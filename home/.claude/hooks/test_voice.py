#!/usr/bin/env python3
"""Self-check for voice position tracking and panel layout: python3 test_voice.py"""
import importlib.util
import json
import pathlib


def load(name, filename):
    spec = importlib.util.spec_from_file_location(
        name, pathlib.Path(__file__).with_name(filename)
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


q = load("speak_queued", "speak-queued.py")
r = load("voice_reader", "voice-reader.py")

parts = q.sentences("One two. Three four! Five six? Seven.")
assert parts == ["One two.", "Three four!", "Five six?", "Seven."], parts
assert q.sentences("") == []

assert q.index_at(parts, 0.0) == 0
assert q.index_at(parts, 0.99) == 3
assert q.index_at(parts, 1.5) == 3
assert q.index_at(parts, -1.0) == 0
# 34 chars total, 0.5 lands at 17, inside "Three four!" which ends at 19
assert q.index_at(parts, 0.5) == 1, q.index_at(parts, 0.5)
assert q.index_at(["only one"], 0.7) == 0

q.publish("lbl", parts, 2, True)
state = json.loads(q.READING.read_text())
assert state == {"label": "lbl", "sentences": parts, "index": 2, "playing": True}
assert not q.READING.with_suffix(".tmp").exists()

lines = r.layout(["aaa bbb ccc", "ddd"], 7)
assert lines == [("aaa bbb", 0), ("ccc", 0), ("", 0), ("ddd", 1)], lines
assert r.layout(["aaa bbb ccc", "ddd"], 7, gap=False) == [
    ("aaa bbb", 0), ("ccc", 0), ("ddd", 1)
]
assert r.layout([], 20) == []

# Whatever the sentence, the window keeps it on screen
many = [f"sentence number {n}" for n in range(40)]
wrapped = r.layout(many, 40)
assert r.window(wrapped, 0, 10) == 0
assert r.window(wrapped, 39, 10) == len(wrapped) - 10
assert r.window(wrapped[:5], 1, 10) == 0
for current in range(40):
    for height in (1, 3, 10):
        start = r.window(wrapped, current, height)
        assert 0 <= start <= max(0, len(wrapped) - height), (current, height, start)
        assert current in {i for _, i in wrapped[start : start + height]}, (current, height)

# A sentence taller than the strip still starts at its own first line
tall_one = r.layout(["word " * 60], 20, gap=False)
assert r.window(tall_one, 0, 3) == 0

out = r.frame(state, 40, 8)
assert "\033[7m" in out, "current sentence not highlighted"
assert out.count("\n") == 7, out.count("\n")
assert "\U0001f50a" in out, "tall panel lost its header"
assert "\033[7m" not in r.frame({**state, "playing": False}, 40, 8)
assert "waiting" in r.frame(None, 40, 8)

# Strip mode: no header, no separators, every row is text
strip = r.frame(state, 40, 4)
assert strip.count("\n") == 3, strip.count("\n")
assert "\U0001f50a" not in strip, "strip should not spend a row on the header"
assert "\033[7m" in strip

rows = [
    "/dev/ttys003\t%2\t@0\tclaude",
    "/dev/ttys009\t%7\t@1\tzsh",
    "/dev/ttys021\t%8\t@1\t/Users/gb/.claude/hooks/voice-reader.py --auto",
]
assert q.pick_pane(rows, "/dev/ttys003") == ("%2", "@0")
assert q.pick_pane(rows, "/dev/ttys099") == ("", "")
assert q.pick_pane(rows, "") == ("", ""), "empty tty must not match a pane"
assert q.has_strip(rows, "@1") is True
assert q.has_strip(rows, "@0") is False

print("ok")
