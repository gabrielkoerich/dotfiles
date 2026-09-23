#!/usr/bin/env python3
"""Side panel showing the reply being spoken, current sentence highlighted.

Claude Code draws on the alternate screen and repaints it, so the transcript
cannot be recoloured in place. This renders the same text in its own pane and
scrolls to keep the spoken sentence in view. Short panes drop the header and
read as a moving strip. The Stop hook opens one per window, it stays up and
shows the last reply between turns.
"""
import json
import os
import pathlib
import shutil
import signal
import sys
import textwrap
import time

READING = pathlib.Path("/tmp/claude-voice-reply.reading")
POLL = 0.2
HEADER_ROWS = 8  # below this the pane is a strip, the label costs too much
PAD_X = 2
PAD_Y = 1
DIM = "\033[90m"
HL = "\033[7m"
OFF = "\033[0m"


def read_state():
    try:
        return json.loads(READING.read_text())
    except (OSError, ValueError):
        return None


def layout(parts: list, width: int, gap: bool = True) -> list:
    """Wrapped lines paired with the sentence each came from."""
    lines = []
    for i, part in enumerate(parts):
        wrapped = textwrap.wrap(part, width=max(8, width)) or [""]
        lines.extend((text, i) for text in wrapped)
        if gap:
            lines.append(("", i))  # separator, too costly in a short strip
    return lines[:-1] if gap and lines else lines


def window(lines: list, current: int, height: int) -> int:
    """First line to draw, keeping the current sentence in view."""
    if len(lines) <= height:
        return 0
    span = [n for n, (_, i) in enumerate(lines) if i == current] or [0]
    # Centre it, a sentence taller than the strip still starts at its top
    lead = max(0, (height - len(span)) // 2)
    return max(0, min(span[0] - lead, len(lines) - height))


def inset(text: str, cols: int) -> str:
    """Left pad, then fill the row so a highlight reads as a full width bar.

    Stops one short of the pane width, writing the last cell of the last row
    scrolls the pane on some terminals.
    """
    return (" " * PAD_X + text)[: cols - 1].ljust(cols - 1)


def frame(state, cols: int, rows: int) -> str:
    if not state or not state.get("sentences"):
        return "\n" * PAD_Y + f"{DIM}{inset('waiting for a reply', cols)}{OFF}"
    parts = state["sentences"]
    current = state.get("index", 0)
    playing = state.get("playing", False)
    label = state.get("label", "")

    tall = rows >= HEADER_ROWS
    chrome = (1 if tall else 0) + 2 * PAD_Y
    body_rows = max(1, rows - chrome)
    width = max(8, cols - 2 * PAD_X)
    lines = layout(parts, width, gap=tall)
    start = window(lines, current, body_rows)

    out = []
    if tall:
        mark = "\U0001f50a" if playing else "\u25cf"
        head = inset(f"{mark} {label}", cols)
        out.append(head if playing else f"{DIM}{head}{OFF}")
    out.extend([""] * PAD_Y)
    for text, index in lines[start : start + body_rows]:
        row = inset(text, cols)
        if index == current and playing:
            out.append(f"{HL}{row}{OFF}")
        elif index == current:
            out.append(row)
        else:
            out.append(f"{DIM}{row}{OFF}")
    out.extend([""] * PAD_Y)
    return "\n".join(out)


def main() -> int:
    sys.stdout.write("\033[?1049h\033[?25l")
    sys.stdout.flush()

    def restore(*_):
        sys.stdout.write("\033[?25h\033[?1049l")
        sys.stdout.flush()
        sys.exit(0)

    signal.signal(signal.SIGINT, restore)
    signal.signal(signal.SIGTERM, restore)

    shown = None
    try:
        while True:
            size = shutil.get_terminal_size((40, 20))
            state = read_state()
            key = (json.dumps(state, sort_keys=True), size.columns, size.lines)
            if key != shown:
                shown = key
                sys.stdout.write("\033[H\033[2J")
                sys.stdout.write(frame(state, size.columns, size.lines))
                sys.stdout.flush()
            time.sleep(POLL)
    finally:
        sys.stdout.write("\033[?25h\033[?1049l")
        sys.stdout.flush()
    return 0


if __name__ == "__main__":
    sys.exit(main())
