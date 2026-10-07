#!/usr/bin/env python3
"""Block writing that breaks the rules in ~/.claude/CLAUDE.md.

PreToolUse on Write, Edit and Bash. Prose rules and hard wraps in markdown,
comment length, punctuation and block style in code, commit bodies in git commands,
and attribution in pull request bodies. Exits 2 to block, quoting the offending line.
"""
import json
import os
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


LIST_RE = re.compile(r'^([-*+]|\d+[.)])\s')


# A paragraph is one line, so prose on the next line means it was wrapped
def hard_wraps(text: str) -> list[str]:
    found = []
    lines = text.split('\n')
    fenced = False
    front = lines[0].strip() in ('---', '+++')
    previous: tuple[int, str] | None = None
    for number, line in enumerate(lines, 1):
        stripped = line.strip()
        if front:
            if number > 1 and stripped in ('---', '+++'):
                front = False
            continue
        if stripped.startswith('```'):
            fenced = not fenced
            previous = None
            continue
        structural = (
            not stripped
            or fenced
            or stripped[0] in '|#<'
            or stripped.startswith(('{{', '{%', '[^', '---', '***'))
            or LIST_RE.match(stripped)
        )
        if previous and stripped and not fenced and not structural:
            start, first = previous
            found.append(
                f'  line {start}: {first[:90]}\n'
                f'    -> hard-wrapped paragraph, it continues on line {number}. Join it into one line.'
            )
            if len(found) >= 5:
                break
        # A line ending in two spaces or a backslash is a deliberate break
        deliberate = line.endswith('  ') or line.endswith('\\')
        if stripped and not fenced and not deliberate and (not structural or LIST_RE.match(stripped)):
            previous = (number, stripped)
        else:
            previous = None
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


LINE_MARKER = {'.py': '#', '.sh': '#', '.bash': '#', '.zsh': '#', '.sql': '--'}
TRAILING_PUNCT_RE = re.compile(r'[.;:!]$')
BLOCK_ONE_LINE_LIMIT = 100


# A comment ends without punctuation, a one-line thought is a line comment, and a
# block exists only for text too long for one line
def comment_style(text: str, path: str) -> list[str]:
    suffix = os.path.splitext(path)[1]
    marker = LINE_MARKER.get(suffix, '//')
    line_re = re.compile(r'^(--)\s?') if suffix == '.sql' else re.compile(r'^(//|#)\s?')
    found = []
    lines = text.split('\n')
    run: list[tuple[int, str]] = []

    def close_run() -> None:
        if run and TRAILING_PUNCT_RE.search(run[-1][1]):
            found.append(
                f'  line {run[-1][0]}: {run[-1][1][:110]}\n'
                '    -> a comment ends with punctuation. Drop the final mark.'
            )
        run.clear()

    index = 0
    while index < len(lines):
        number = index + 1
        stripped = lines[index].strip()
        match = line_re.match(stripped)
        # rustdoc renders /// and //! as prose, so they keep normal sentences
        if match and not stripped.startswith(('///', '//!')) and not DIRECTIVE_RE.search(stripped):
            run.append((number, stripped[match.end():].strip()))
            index += 1
            continue
        close_run()

        if stripped.startswith('/*'):
            if stripped.endswith('*/'):
                # a JSDoc one-liner like /** @type {X} */ is an annotation, not prose
                if not (stripped.startswith('/**') and '@' in stripped):
                    found.append(
                        f'  line {number}: {stripped[:110]}\n'
                        f'    -> a one-line block comment. Use {marker} for a single line.'
                    )
                index += 1
                continue

            end = index + 1
            while end < len(lines) and '*/' not in lines[end]:
                end += 1
            block_lines = [line.strip() for line in lines[index + 1:end]]
            closing = lines[end].strip() if end < len(lines) else ''

            if stripped != '/**':
                found.append(
                    f'  line {number}: {stripped[:110]}\n'
                    '    -> a docblock opens with /** alone on its line.'
                )
            if any(line and not line.startswith('*') for line in block_lines):
                found.append(
                    f'  line {number}: {stripped[:110]}\n'
                    "    -> every docblock line starts with ' * '."
                )
            if closing != '**/':
                found.append(
                    f'  line {end + 1}: {closing[:110]}\n'
                    '    -> a docblock closes with **/ alone on its line.'
                )

            text = [line.lstrip('*').strip() for line in block_lines]
            body = ' '.join(part for part in text if part)
            # tagged docblocks (@param, @returns) follow their tooling's punctuation
            if not any(part.startswith('@') for part in text):
                if len(body) <= BLOCK_ONE_LINE_LIMIT:
                    found.append(
                        f'  line {number}: {body[:110]}\n'
                        f'    -> a docblock that fits on one line. Use {marker}, a docblock is only for text that needs several lines.'
                    )
                elif TRAILING_PUNCT_RE.search(body):
                    found.append(
                        f'  line {number}: ...{body[-80:]}\n'
                        '    -> a docblock ends with punctuation. Drop the final mark.'
                    )
            index = end + 1
            continue
        index += 1
    close_run()
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


ATTRIBUTION = ('Generated with', 'Co-Authored-By', 'Claude-Session', 'noreply@anthropic')


# A PR body names no tool either. It arrives inline, in a heredoc or through --body-file,
# so this reads the raw command and the file, not the heredoc-stripped text
def pr_attribution(command: str) -> list[str]:
    pr_command = re.search(r'\bgh\s+pr\s+(create|edit|comment|review)\b', command)
    pr_api = re.search(r'\bgh\s+api\b.*\b(pulls|issues/\d+/comments)\b', command, re.S)
    if not (pr_command or pr_api):
        return []

    text = command
    try:
        tokens = shlex.split(command)
    except ValueError:
        tokens = []
    for index, token in enumerate(tokens[:-1]):
        if token in ('--body-file', '-F'):
            try:
                with open(os.path.expanduser(tokens[index + 1]), encoding='utf-8') as handle:
                    text += handle.read()
            except OSError:
                pass

    return [
        f'    -> the PR body carries "{marker}". Pull requests name no tool and no co-author.'
        for marker in ATTRIBUTION
        if marker.lower() in text.lower()
    ]


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    tool = event.get('tool_name', '')
    payload = event.get('tool_input', {})

    if tool == 'Bash':
        command = payload.get('command', '')
        found = commit_body(command)
        if found:
            print(
                'Commit rules (~/.claude/CLAUDE.md):\n'
                + '\n'.join(found)
                + '\nUse a subject line only. Reasoning goes in the docs.',
                file=sys.stderr,
            )
            return 2

        found = pr_attribution(command)
        if found:
            print(
                'Pull request rules (~/.claude/CLAUDE.md):\n'
                + '\n'.join(found)
                + '\nRemove the line from the PR body and run it again.',
                file=sys.stderr,
            )
            return 2
        return 0

    if tool not in ('Write', 'Edit'):
        return 0

    path = payload.get('file_path', '')
    text = payload.get('content') or payload.get('new_string') or ''

    # The rule files quote banned words on purpose, but they still must not wrap
    if path.endswith('.md') and any(name in path for name in EXEMPT):
        found = hard_wraps(text)
    elif any(name in path for name in EXEMPT):
        return 0
    elif path.endswith('.md'):
        found = offences(text) + hard_wraps(text)
    elif path.endswith(CODE_SUFFIXES):
        found = comment_runs(text) + comment_style(text, path)
        # Only what this write adds, keyed without line numbers because an
        # Edit fragment numbers its lines from one
        def key(finding: str) -> str:
            return re.sub(r'^\s*line \d+: ', '', finding)

        try:
            with open(path, encoding='utf-8') as handle:
                existing = handle.read()
            already = {key(line) for line in comment_runs(existing) + comment_style(existing, path)}
            found = [line for line in found if key(line) not in already]
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
