#!/usr/bin/env python3
"""Stop hook: speaks Claude's last reply with Kokoro. Toggle with ~/.claude/hooks/voice-reply.sh on|off"""
import hashlib, json, os, re, subprocess, sys, time, pathlib

HOME = pathlib.Path.home()
STATE = HOME / ".claude" / "voice-reply.state"
VOICEPIN = HOME / ".claude" / "voice-reply.voice"
SPEEDFILE = HOME / ".claude" / "voice-reply.speed"
LIMITFILE = HOME / ".claude" / "voice-reply.limit"
SPEAK = HOME / ".claude" / "skills" / "kokoro-tts" / "speak.sh"
PIDFILE = pathlib.Path("/tmp/claude-voice-reply.pid")
LASTVOICE = pathlib.Path("/tmp/claude-voice-reply.last")

def max_chars() -> int:
    """0 means read the whole reply."""
    try:
        raw = LIMITFILE.read_text().strip().lower()
    except OSError:
        return 0
    if raw in ("full", "0", ""):
        return 0
    try:
        return max(80, int(raw))
    except ValueError:
        return 0
TAIL_BYTES = 256 * 1024
POLL_SECONDS = 5.0
POLL_INTERVAL = 0.15

# Curated pool, the better-rated Kokoro voices across both accents
VOICES = [
    "af_heart", "af_bella", "af_nicole", "af_aoede", "af_kore", "af_sarah",
    "am_michael", "am_fenrir", "am_puck",
    "bf_emma", "bm_george", "bm_fable",
]


def read_tail(path):
    with open(path, "rb") as fh:
        fh.seek(0, os.SEEK_END)
        size = fh.tell()
        fh.seek(max(0, size - TAIL_BYTES))
        data = fh.read()
    return data.decode("utf-8", "replace").splitlines()


def final_reply(lines):
    """The turn's closing message, or None while the turn is still running.

    Only the newest assistant record counts. A preamble before a tool call is
    newer than anything spoken before, but it does not end the turn.
    """
    for line in reversed(lines):
        try:
            d = json.loads(line)
        except Exception:
            continue
        if d.get("type") != "assistant":
            continue
        blocks = d.get("message", {}).get("content", [])
        if not isinstance(blocks, list):
            return None
        kinds = {b.get("type") for b in blocks if isinstance(b, dict)}
        if "tool_use" in kinds:
            return None  # more work coming, not the closing message
        text = " ".join(
            b.get("text", "") for b in blocks
            if isinstance(b, dict) and b.get("type") == "text"
        ).strip()
        return (d.get("uuid") or "", text) if text else None
    return None


def speakable(name: str) -> str:
    return re.sub(r"\s+", " ", re.sub(r"[-_]+", " ", name)).strip()


def folder_of(payload, transcript_path, lines) -> str:
    cwd = payload.get("cwd")
    if not cwd:
        for line in reversed(lines):
            try:
                cwd = json.loads(line).get("cwd")
            except Exception:
                continue
            if cwd:
                break
    if cwd:
        return speakable(os.path.basename(cwd.rstrip("/")))
    return speakable(pathlib.Path(transcript_path).parent.name.split("-")[-1])


def title_of(lines) -> str:
    for line in reversed(lines):
        try:
            d = json.loads(line)
        except Exception:
            continue
        if d.get("type") == "ai-title" and d.get("aiTitle"):
            return speakable(d["aiTitle"])[:60]
    return ""


def session_label(payload, transcript_path, lines) -> str:
    """Folder plus session title, so sessions sharing a folder stay distinct."""
    folder = folder_of(payload, transcript_path, lines)
    title = title_of(lines)
    if not title:
        return folder
    # Do not say "tempo, tempo refactor"
    if folder and folder.lower() not in title.lower():
        return f"{folder}, {title}"
    return title


def pick_voice(session_id: str) -> str:
    """Stable per session, varies between sessions. A pin file overrides."""
    try:
        pinned = VOICEPIN.read_text().strip()
        if pinned and pinned != "random":
            return pinned
    except OSError:
        pass
    if not session_id:
        return VOICES[0]
    # md5 not hash(), Python salts string hashes per process
    return VOICES[hashlib.md5(session_id.encode()).digest()[0] % len(VOICES)]


def for_speech(s: str, limit: int) -> str:
    s = re.sub(r"```.*?```", " code block. ", s, flags=re.S)
    s = re.sub(r"`([^`]*)`", r"\1", s)
    s = re.sub(r"!?\[([^\]]*)\]\([^)]*\)", r"\1", s)           # links keep their label
    s = re.sub(r"^\s{0,3}#{1,6}\s*", "", s, flags=re.M)        # headings
    s = re.sub(r"^\s*\|.*\|\s*$", "", s, flags=re.M)           # table rows
    s = re.sub(r"^\s*[-*+]\s+", "", s, flags=re.M)             # bullets
    s = re.sub(r"\*\*([^*]*)\*\*", r"\1", s)
    s = re.sub(r"https?://\S+", "link", s)
    s = re.sub(r"(?<![\w/])(?:~|\.{0,2})/\S+", "a path", s)    # file paths
    s = re.sub(r"\s+", " ", s).strip()
    if not limit or len(s) <= limit:
        return s
    cut = s[:limit]
    stop = max(cut.rfind(". "), cut.rfind("? "), cut.rfind("! "))
    return cut[: stop + 1] if stop > 120 else cut


def tty_path() -> str:
    """The terminal this session draws in, so the panel opens in its window."""
    pid = os.getppid()
    for _ in range(5):
        out = subprocess.run(
            ["ps", "-o", "tty=,ppid=", "-p", str(pid)],
            capture_output=True, text=True, check=False,
        ).stdout.split()
        if len(out) < 2:
            return ""
        name, parent = out[0], out[-1]
        if name not in ("??", "-", ""):
            return f"/dev/{name}"
        try:
            pid = int(parent)
        except ValueError:
            return ""
    return ""


try:
    if STATE.read_text().strip() != "on":
        sys.exit(0)
except OSError:
    sys.exit(0)

try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)

transcript = payload.get("transcript_path")
if not transcript or not os.path.exists(transcript):
    sys.exit(0)

session_id = payload.get("session_id") or pathlib.Path(transcript).stem
seen_path = pathlib.Path(f"/tmp/claude-voice-reply.{session_id}.seen")
try:
    seen = seen_path.read_text().strip()
except OSError:
    seen = ""

# The turn's final message may not be flushed yet, so wait for one we have not spoken
deadline = time.monotonic() + POLL_SECONDS
while True:
    lines = read_tail(transcript)
    found = final_reply(lines)
    if found and found[0] and found[0] != seen:
        uid, text = found
        break
    if time.monotonic() >= deadline:
        sys.exit(0)
    time.sleep(POLL_INTERVAL)

speech = for_speech(text, max_chars())
if not speech:
    sys.exit(0)

name = session_label(payload, transcript, lines)
if name:
    speech = f"{name}. {speech}"

voice = pick_voice(session_id)
try:
    speed = str(max(0.5, min(2.0, float(SPEEDFILE.read_text().strip()))))
except (OSError, ValueError):
    speed = "1.0"
for path, value in ((seen_path, uid), (LASTVOICE, voice)):
    try:
        path.write_text(value)
    except OSError:
        pass

# Queued, not cancelled: several open sessions read out one after another
QUEUED = HOME / ".claude" / "hooks" / "speak-queued.py"
proc = subprocess.Popen(
    [sys.executable, str(QUEUED), speech, voice, speed, name or "claude", tty_path()],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    start_new_session=True,
)
try:
    PIDFILE.write_text(str(os.getpgid(proc.pid)))
except OSError:
    pass
sys.exit(0)
