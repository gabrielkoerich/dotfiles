#!/usr/bin/env python3
"""Play one reply, waiting for any other session to finish speaking first.

Sessions used to cancel each other: a second Claude finishing mid-sentence
killed the first one's audio. They queue on a lock instead, so several open
terminals read out one after another rather than over each other.

While a reply plays, the sentence being read is published to READING for the
side panel to highlight. Claude Code runs on the alternate screen and repaints
it, so no outside process can recolour the transcript in place.
"""
import contextlib
import fcntl
import shutil
import json
import os
import pathlib
import re
import subprocess
import sys
import time
import wave

HOME = pathlib.Path.home()
STATE = HOME / ".claude" / "voice-reply.state"
SPEAK = HOME / ".claude" / "skills" / "kokoro-tts" / "speak.sh"
LOCK = pathlib.Path("/tmp/claude-voice-reply.lock")
QUEUE = pathlib.Path("/tmp/claude-voice-reply.queue")
READING = pathlib.Path("/tmp/claude-voice-reply.reading")
READER = HOME / ".claude" / "hooks" / "voice-reader.py"
PANEL_ROWS = 7  # one blank row top and bottom, five of text

# Past this the reply is stale, and hearing it is worse than missing it
MAX_WAIT = 180.0
POLL = 0.2
TRACK_POLL = 0.25


def enabled() -> bool:
    try:
        return STATE.read_text().strip() == "on"
    except OSError:
        return False


PANES_FMT = "#{pane_tty}\t#{pane_id}\t#{window_id}\t#{pane_start_command}"


def pick_pane(rows: list, tty: str) -> tuple:
    """The pane and window owning this terminal, empty when none does."""
    for row in rows:
        parts = row.split("\t")
        if tty and len(parts) >= 3 and parts[0] == tty:
            return parts[1], parts[2]
    return "", ""


def has_strip(rows: list, window: str) -> bool:
    return any(r.split("\t")[2:3] == [window] and "voice-reader" in r for r in rows)


def active_pane(tmux: str) -> tuple:
    """Where the user is looking. Background sessions own no pane of their own,
    their process tree ends at a detached pty host, so the newest client's
    active pane is the only honest guess at which screen they are watching."""
    clients = subprocess.run(
        [tmux, "list-clients", "-F", "#{client_activity}\t#{client_session}"],
        capture_output=True, text=True, check=False,
    ).stdout.splitlines()

    def when(row):
        head = row.split("\t")[0]
        return int(head) if head.isdigit() else 0

    if not clients:
        return "", ""
    session = max(clients, key=when).split("\t")[-1]
    found = subprocess.run(
        [tmux, "display-message", "-p", "-t", session,
         "#{pane_id}\t#{window_id}\t#{pane_current_command}"],
        capture_output=True, text=True, check=False,
    ).stdout.strip().split("\t")
    if len(found) >= 3 and found[2] == "claude":
        return found[0], found[1]
    return "", ""


def open_panel(tty: str) -> None:
    """Split a strip under the pane this session runs in, one per window."""
    tmux = shutil.which("tmux")
    if not tmux:
        return
    rows = subprocess.run(
        [tmux, "list-panes", "-a", "-F", PANES_FMT],
        capture_output=True, text=True, check=False,
    ).stdout.splitlines()
    target, window = pick_pane(rows, tty)
    if not target:
        target, window = active_pane(tmux)
    if not target or has_strip(rows, window):
        return
    subprocess.run(
        [tmux, "split-window", "-v", "-d", "-l", str(PANEL_ROWS), "-t", target,
         str(READER)],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False,
    )


def publish(label: str, parts: list, index: int, playing: bool) -> None:
    """Atomic, so the panel never reads a half-written file."""
    payload = json.dumps(
        {"label": label, "sentences": parts, "index": index, "playing": playing}
    )
    tmp = READING.with_suffix(".tmp")
    try:
        tmp.write_text(payload)
        tmp.replace(READING)
    except OSError:
        pass


def sentences(text: str) -> list:
    return [s for s in re.split(r"(?<=[.!?])\s+", text) if s.strip()]


def duration(wav: str) -> float:
    try:
        with contextlib.closing(wave.open(wav, "rb")) as handle:
            rate = handle.getframerate()
            return handle.getnframes() / rate if rate else 0.0
    except Exception:
        return 0.0


def index_at(parts: list, frac: float) -> int:
    """Which sentence covers this fraction of the text, by character share."""
    target = max(0.0, min(1.0, frac)) * sum(len(p) for p in parts)
    seen = 0
    for i, part in enumerate(parts):
        seen += len(part)
        if seen >= target:
            return i
    return len(parts) - 1


def play(wav: str, text: str, label: str) -> None:
    """Play the wav, tracking position by elapsed time over total characters."""
    parts = sentences(text)
    total_seconds = duration(wav)
    if not parts:
        subprocess.run(["afplay", wav], check=False)
        return

    publish(label, parts, 0, True)
    proc = subprocess.Popen(["afplay", wav])
    if total_seconds <= 0:
        proc.wait()
        publish(label, parts, len(parts) - 1, False)
        return

    # ponytail: position estimated from character share, kokoro gives no
    # per-sentence timings, switch to segment playback if drift annoys
    start = time.monotonic()
    shown = 0
    while proc.poll() is None:
        index = index_at(parts, (time.monotonic() - start) / total_seconds)
        if index != shown:
            shown = index
            publish(label, parts, index, True)
        time.sleep(TRACK_POLL)
    publish(label, parts, len(parts) - 1, False)


def main() -> int:
    if len(sys.argv) < 4:
        return 1
    text, voice, speed = sys.argv[1], sys.argv[2], sys.argv[3]
    label = sys.argv[4] if len(sys.argv) > 4 else "?"
    tty = sys.argv[5] if len(sys.argv) > 5 else ""

    handle = os.open(LOCK, os.O_CREAT | os.O_RDWR, 0o644)
    deadline = time.monotonic() + MAX_WAIT
    waited = False
    while True:
        try:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
            break
        except OSError:
            if time.monotonic() >= deadline:
                return 0
            if not waited:
                waited = True
                try:
                    with open(QUEUE, "a") as queue:
                        queue.write(f"{os.getpid()}\t{label}\n")
                except OSError:
                    pass
            # Paused while this one waited its turn
            if not enabled():
                return 0
            time.sleep(POLL)

    try:
        if not enabled():
            return 0
        # Up before synthesis, or the panel shows the previous reply meanwhile
        publish(label, sentences(text), 0, False)
        open_panel(tty)
        result = subprocess.run(
            [str(SPEAK), text, "-v", voice, "-s", speed],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            check=False,
        )
        wav = ""
        for line in result.stdout.splitlines():
            if line.strip():
                wav = line.strip()
        if wav and os.path.exists(wav):
            play(wav, text, label)
    finally:
        try:
            if QUEUE.exists():
                remaining = [
                    line
                    for line in QUEUE.read_text().splitlines()
                    if not line.startswith(f"{os.getpid()}\t")
                ]
                QUEUE.write_text("\n".join(remaining) + ("\n" if remaining else ""))
        except OSError:
            pass
        fcntl.flock(handle, fcntl.LOCK_UN)
        os.close(handle)
    return 0


if __name__ == "__main__":
    sys.exit(main())
