#!/usr/bin/env python3
"""Play one reply, waiting for any other session to finish speaking first.

Sessions used to cancel each other: a second Claude finishing mid-sentence
killed the first one's audio. They queue on a lock instead, so several open
terminals read out one after another rather than over each other.
"""
import fcntl
import os
import pathlib
import subprocess
import sys
import time

HOME = pathlib.Path.home()
STATE = HOME / ".claude" / "voice-reply.state"
SPEAK = HOME / ".claude" / "skills" / "kokoro-tts" / "speak.sh"
LOCK = pathlib.Path("/tmp/claude-voice-reply.lock")
QUEUE = pathlib.Path("/tmp/claude-voice-reply.queue")

# Past this the reply is stale, and hearing it is worse than missing it
MAX_WAIT = 180.0
POLL = 0.2


def enabled() -> bool:
    try:
        return STATE.read_text().strip() == "on"
    except OSError:
        return False


def main() -> int:
    if len(sys.argv) < 4:
        return 1
    text, voice, speed = sys.argv[1], sys.argv[2], sys.argv[3]
    label = sys.argv[4] if len(sys.argv) > 4 else "?"

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
        subprocess.run(
            [str(SPEAK), text, "-v", voice, "-s", speed, "--play"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
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
