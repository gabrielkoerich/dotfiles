#!/usr/bin/env python3
"""Block writing that breaks the rules in ~/.claude/CLAUDE.md.

PreToolUse on Write, Edit and Bash. Three jobs: prose rules in markdown,
comment-block length in code, and commit bodies in git commands. Exits 2 to
block, quoting the offending line.
"""
import json
import re
import shlex
import sys

# Three consecutive comment lines is a paragraph, which belongs in the docs
MAX_COMMENT_RUN = 2

CODE_SUFFIXES = (
    '.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs',
    '.py', '.rs', '.go', '.java', '.kt', '.swift',
    '.c', '.h', '.cpp', '.hpp', '.sh', '.bash', '.zsh', '.sql',
)

# Line comments only. A `/* */` block or a docstring is the sanctioned way to
# carry more than two lines, so neither is matched here
COMMENT_RE = re.compile(r'^(//|#|--)\s?')

# Directives are machine-readable, so a run of them is not prose
DIRECTIVE_RE = re.compile(
    r'(biome-ignore|eslint-|ts-|prettier-|type:|noqa|pylint|ruff|SPDX|!/|coding[:=])'
)

# Quoting a banned example is how the rules are written down, so the files
# that hold them are exempt
EXEMPT = ('CLAUDE.md', 'AGENTS.md')

RULES = [
    (
        re.compile(r'[—–]'),
        'em or en dash. Use a comma, or split the sentence.',
    ),
    (
        re.compile(
            r'\b(it is|it\'s) worth (noting|stating|mentioning)'
            r'|\bneedless to say\b'
            r'|\bthis is not arbitrary\b'
            r'|\bthe key point is\b',
            re.I,
        ),
        'throat-clearing. Delete the phrase and state the fact.',
    ),
    (
        # A contrast closing a line: "...costs latency, not correctness."
        # Mid-sentence contrasts are left alone, they usually disambiguate.
        re.compile(r',\s+not\s+(?:\w+[\s\-]){0,4}\w+\.?\s*$'),
        'contrast used as a closer. Keep the fact, delete the decoration.',
    ),
]


# Brochure words and the everyday word that carries the same meaning
PLAIN = {
    'leverage': 'use',
    'leverages': 'uses',
    'leveraging': 'using',
    'utilize': 'use',
    'utilizes': 'uses',
    'utilizing': 'using',
    'myriad': 'many',
    'plethora': 'many',
    'furthermore': 'also',
    'moreover': 'also',
    'paramount': 'main',
    'showcase': 'show',
    'showcases': 'shows',
    'delve': 'look',
    'endeavor': 'try',
    'seamless': 'plain word',
    'seamlessly': 'plain word',
    'robust': 'plain word',
    'holistic': 'plain word',
    'cutting-edge': 'plain word',
    'state-of-the-art': 'plain word',
    'game-changer': 'plain word',
    'synergy': 'plain word',
}
FANCY = re.compile(r'\b(' + '|'.join(PLAIN) + r')\b', re.I)


def offences(text: str) -> list[str]:
    found = []
    fenced = False
    for number, line in enumerate(text.split('\n'), 1):
        stripped = line.strip()
        if stripped.startswith('```'):
            fenced = not fenced
            continue
        # Tables, code and headings are reference material. A heading states
        # the distinction it names, so a contrast there is the content.
        if fenced or stripped.startswith('|') or stripped.startswith('#'):
            continue
        for pattern, why in RULES:
            # A dash separating a term from its definition in a list is a
            # layout device. The rule is about asides inside a sentence.
            if why.startswith('em or en dash') and stripped[:1] in '-*>':
                continue
            if pattern.search(line):
                found.append(f'  line {number}: {stripped[:90]}\n    -> {why}')
                break
        else:
            word = FANCY.search(line)
            if word:
                plain = PLAIN[word.group(1).lower()]
                hint = f'say "{plain}"' if plain != 'plain word' else 'cut it'
                found.append(
                    f'  line {number}: {stripped[:90]}\n'
                    f'    -> "{word.group(1)}" is a brochure word, {hint}.'
                )
    return found


def comment_runs(text: str) -> list[str]:
    found = []
    run: list[tuple[int, str]] = []

    def close() -> None:
        if len(run) > MAX_COMMENT_RUN:
            start = run[0][0]
            body = ' '.join(line for _, line in run)
            found.append(
                f'  line {start}: {body[:110]}\n'
                f'    -> {len(run)} line comments. One, or two at a push.'
                ' Cut it, or use /* */ if it truly cannot be seen in the code.'
            )
        run.clear()

    for number, line in enumerate(text.split('\n'), 1):
        stripped = line.strip()
        match = COMMENT_RE.match(stripped)
        if match and not DIRECTIVE_RE.search(stripped):
            body = stripped[match.end():].strip()
            # A bare `//` divides a block rather than ending it
            run.append((number, body))
        else:
            close()
    close()
    return found


HEREDOC_RE = re.compile(r'<<-?\s*[\'"]?(\w+)[\'"]?\n.*?\n\1', re.S)


# A heredoc is data being written, not a command being run. Without this, any
# script quoting the words below refuses to run
def without_heredocs(command: str) -> str:
    return HEREDOC_RE.sub('\n', command)


# `-m` twice, a newline inside one, or `-F` all produce a commit body
def commit_body(raw: str) -> list[str]:
    command = without_heredocs(raw)
    if not re.search(r'\bgit\s+(-\S+\s+)*commit\b', command):
        return []

    found = []
    for trailer in ('Co-Authored-By', 'Claude-Session', 'Generated with', 'noreply@anthropic'):
        if trailer.lower() in command.lower():
            found.append(f'    -> drops a "{trailer}" trailer. Commits name no tool and no co-author.')

    try:
        tokens = shlex.split(command)
    except ValueError:
        return found

    messages = [
        tokens[index + 1]
        for index, token in enumerate(tokens[:-1])
        if token in ('-m', '--message')
    ]
    if len(messages) > 1:
        found.append(f'    -> {len(messages)} -m flags, which is a subject plus a body.')
    if any('\n' in message for message in messages):
        found.append('    -> a newline inside -m, which is a subject plus a body.')
    if any(token in ('-F', '--file') for token in tokens):
        found.append('    -> -F reads a message from a file, which carries a body.')
    return found


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    tool = event.get('tool_name', '')
    payload = event.get('tool_input', {})

    if tool == 'Bash':
        found = commit_body(payload.get('command', ''))
        if not found:
            return 0
        print(
            'Commit rules (~/.claude/CLAUDE.md):\n'
            + '\n'.join(found)
            + '\nUse a subject line only. Reasoning goes in the docs.',
            file=sys.stderr,
        )
        return 2

    if tool not in ('Write', 'Edit'):
        return 0

    path = payload.get('file_path', '')
    if any(name in path for name in EXEMPT):
        return 0

    text = payload.get('content') or payload.get('new_string') or ''

    if path.endswith('.md'):
        found = offences(text)
    elif path.endswith(CODE_SUFFIXES):
        found = comment_runs(text)
        # Only what this write adds. Rewriting a file should not mean tidying
        # comments somebody else wrote
        try:
            with open(path, encoding='utf-8') as handle:
                already = {line.split('->')[0] for line in comment_runs(handle.read())}
            found = [line for line in found if line.split('->')[0] not in already]
        except OSError:
            pass
    else:
        return 0

    if not found:
        return 0

    print(
        f'Writing rules (~/.claude/CLAUDE.md) in {path}:\n'
        + '\n'.join(found)
        + '\nRewrite, then write the file again.',
        file=sys.stderr,
    )
    return 2


if __name__ == '__main__':
    sys.exit(main())
