#!/usr/bin/env bash
# One-time setup: adds agent state hooks to ~/.claude/settings.json.
# Safe to run multiple times — checks before adding.

SETTINGS="$HOME/.claude/settings.json"
AGENT_STATE="$HOME/.tmux/agent-state.sh"

if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

python3 - "$SETTINGS" "$AGENT_STATE" <<'EOF'
import json, sys
from pathlib import Path

settings_path = Path(sys.argv[1])
agent_state   = sys.argv[2]

data = json.loads(settings_path.read_text()) if settings_path.exists() else {}
data.setdefault("hooks", {})

def has_hook(hooks_list, marker):
    return any(marker in str(h) for h in hooks_list)

def add_hook(event, command):
    data["hooks"].setdefault(event, [])
    entry = {"hooks": [{"type": "command", "command": command}]}
    if not has_hook(data["hooks"][event], "agent-state.sh"):
        data["hooks"][event].append(entry)

add_hook("UserPromptSubmit", f"{agent_state} --agent claude --state running")
add_hook("PermissionRequest", f"{agent_state} --agent claude --state needs-input")
add_hook("Stop", f"{agent_state} --agent claude --state done")

settings_path.write_text(json.dumps(data, indent=2))
print(f"Hooks written to {settings_path}")
EOF
