#!/usr/bin/env python3
"""Flatten the Omarchy menu tree into one searchable line per action.

    menu-index.py build <path-to-omarchy-menu>
        Prints the index: display<TAB>function<TAB>option<TAB>description.
        `display` is the icon and the path ("󰣇  Install › Package"), `function`
        is the menu function that owns the choice, `option` is the exact string
        that function's case statement matches on, and `description` says what
        the entry does. Running an entry means calling `function` with `menu`
        stubbed to answer `option`.

    menu-index.py render <index> <recent-file> <0|1 descriptions>
        Prints the lines to show: what was used lately, then the sections, then
        everything else, then the row that turns descriptions off and on.

Descriptions come from menu-hints.tsv where it has an opinion, then from the
path for the repetitive families, then from the `omarchy:summary=` line of the
command the entry runs. Menus whose entries are built by a command (themes,
fonts) are left as leaves; their contents are not ours to enumerate.
"""

import fnmatch
import os
import re
import sys

FUNC = re.compile(r"^([a-z_][a-z0-9_]*)\(\) \{$")
MENU_CALL = re.compile(r"(?<![\w-])menu\s+(\"(?:[^\"\\]|\\.)*\")\s+(\"(?:[^\"\\]|\\.)*\")")
OPTIONS_APPEND = re.compile(r'options=\"(.*)\"')
SUMMARY = re.compile(r"^# omarchy:summary=(.*)$", re.M)
COMMAND = re.compile(r"omarchy-[a-z0-9-]+")
QUOTED = re.compile(r'"([^"]*)"')

HERE = os.path.dirname(os.path.abspath(__file__))
HINTS = os.path.join(HERE, "menu-hints.tsv")
SEPARATOR = " › "
FIELD = " · "
RECENT_SHOWN = 3
TOGGLE_ICON = "󰋼"


# The menu, as bash ------------------------------------------------------


def read_functions(source):
    functions, name, body = {}, None, []
    for line in source.splitlines():
        if name is None:
            match = FUNC.match(line)
            if match:
                name, body = match.group(1), []
        elif line == "}":
            functions[name], name = body, None
        else:
            body.append(line)
    return functions


def unquote(text):
    return text[1:-1] if len(text) > 1 and text[0] == text[-1] == '"' else text


def options_from_variable(body):
    """Collect every literal that any branch appends to $options."""
    found = []
    for line in body:
        match = OPTIONS_APPEND.search(line) if "options=" in line else None
        if not match:
            continue
        literal = match.group(1)
        literal = literal.replace("${options:+$options\\n}", "").replace("$options", "")
        for entry in literal.split("\\n"):
            if entry.strip() and entry not in found:
                found.append(entry)
    return found


def menu_options(body):
    """The option list a function offers, or None when it offers no menu."""
    for index, line in enumerate(body):
        match = MENU_CALL.search(line)
        if not match:
            continue
        argument = unquote(match.group(2))
        if argument == "$options":
            return options_from_variable(body[:index]), index
        if argument.startswith("$"):
            return None, index
        return [entry for entry in argument.split("\\n") if entry.strip()], index
    return None, None


def case_branches(body, start):
    """Every (patterns, body) pair of the case statement starting at `start`."""
    branches, patterns, collected = [], None, []
    for line in body[start + 1:]:
        stripped = line.strip()
        if stripped == "esac":
            break
        if patterns is None:
            head = stripped.split(")", 1)
            if len(head) != 2:
                continue
            patterns = [p.strip().replace('"', "") for p in head[0].split("|")]
            collected = [head[1]]
        else:
            collected.append(stripped)
        if stripped.endswith(";;"):
            branches.append((patterns, " ".join(collected).rsplit(";;", 1)[0].strip()))
            patterns = None
    return branches


def branch_for(option, branches):
    for patterns, body in branches:
        if any(fnmatch.fnmatchcase(option, pattern) for pattern in patterns):
            return body
    return None


def label(option):
    return re.sub(r"^[^\x00-\x7f]+\s*", "", option.strip()).strip()


def icon(option):
    head = option.strip().split(" ", 1)[0]
    return head if head and ord(head[0]) > 127 else ""


# What each entry does ---------------------------------------------------


def read_hints():
    hints = {}
    if not os.path.exists(HINTS):
        return hints
    for line in open(HINTS, encoding="utf-8"):
        if line.startswith("#") or "\t" not in line:
            continue
        path, text = line.rstrip("\n").split("\t", 1)
        hints[path.strip()] = text.strip()
    return hints


def read_summary(command, bindir):
    path = os.path.join(bindir, command)
    if not os.path.isfile(path):
        return ""
    match = SUMMARY.search(open(path, encoding="utf-8", errors="replace").read())
    if not match:
        return ""
    text = match.group(1).strip().rstrip(".")
    return text[:1].lower() + text[1:]


def from_path(trail):
    """Descriptions for the families where the path already says everything."""
    top, leaf = trail[0], trail[-1]
    second = trail[1] if len(trail) > 1 else ""
    verb = {"Install": "install", "Remove": "remove"}.get(top)

    if verb and second == "Development":
        return f"{verb} the {leaf} toolchain"
    if verb and second == "Style" and len(trail) > 3:
        return f"{verb} the {leaf} font"
    if verb and second in ("AI", "Browser", "Editor", "Gaming", "Service", "Terminal"):
        return f"{verb} {leaf}"
    if top == "Setup" and second == "Defaults" and len(trail) > 3:
        return f"open {leaf} whenever a {trail[2].lower()} is called for"
    if top == "Setup" and second == "Config":
        return f"edit your {leaf} config by hand"
    if top == "Update" and second == "Config":
        return f"throw away your {leaf} config and take Omarchy's"
    if top == "Update" and second in ("Hardware", "Process"):
        return f"restart {leaf}"
    if top == "Update" and second == "Channel":
        return f"follow the {leaf.lower()} release channel"
    if top == "Learn":
        return f"open the {leaf} documentation"
    return ""


def describe(trail, body, hints, bindir):
    path = SEPARATOR.join(trail)
    if path in hints:
        return hints[path]

    built = from_path(trail)
    if built:
        return built

    if body.startswith("open_in_editor"):
        target = body.split(None, 1)[1].strip() if " " in body else ""
        return f"edit {target}" if target else ""
    if body.startswith(("install_and_launch", "install_font", "install ", "aur_install")):
        quoted = QUOTED.findall(body)
        if quoted:
            return f"install {quoted[0]}"

    command = COMMAND.search(body)
    return read_summary(command.group(0), bindir) if command else ""


# Walking ----------------------------------------------------------------


def walk(functions, function, trail, rows, seen, hints, bindir):
    options, start = menu_options(functions.get(function, []))
    if not options:
        return
    branches = case_branches(functions[function], start)
    for option in options:
        body = branch_for(option, branches)
        if body is None:
            continue
        path = trail + [label(option)]
        child = body if re.fullmatch(r"show_[a-z_]+", body) else None
        if child and child not in seen and menu_options(functions.get(child, []))[0]:
            walk(functions, child, path, rows, seen | {function}, hints, bindir)
        else:
            rows.append((icon(option), path, function, option,
                         describe(path, body, hints, bindir)))


def build(source_path):
    source = open(source_path, encoding="utf-8").read()
    bindir = os.path.dirname(os.path.abspath(source_path))
    functions = read_functions(source)
    hints = read_hints()
    top, _ = menu_options(functions["show_main_menu"])
    dispatch = case_branches(functions["go_to_menu"], 0)
    rows = []

    for option in top:
        name = label(option)
        target = branch_for(name.lower(), dispatch)
        rows.append((icon(option), [name], "go_to_menu", option,
                     hints.get(name, "")))
        if target and re.fullmatch(r"show_[a-z_]+", target):
            walk(functions, target, [name], rows, set(), hints, bindir)

    for symbol, trail, function, option, description in rows:
        path = SEPARATOR.join(trail)
        display = f"{symbol}  {path}" if symbol else path
        print("\t".join([display, function, option, description]))


# Rendering --------------------------------------------------------------


def render(index_path, recent_path, descriptions):
    rows = []
    for line in open(index_path, encoding="utf-8"):
        fields = line.rstrip("\n").split("\t")
        if len(fields) == 4:
            rows.append(fields)

    sections = [r for r in rows if r[1] == "go_to_menu"]
    actions = [r for r in rows if r[1] != "go_to_menu"]

    recent = []
    if os.path.exists(recent_path):
        wanted = [line.strip() for line in open(recent_path, encoding="utf-8")]
        by_display = {r[0]: r for r in actions}
        for display in wanted[:RECENT_SHOWN]:
            if display in by_display and by_display[display] not in recent:
                recent.append(by_display[display])

    state = "on" if descriptions else "off"
    toggle = [f"{TOGGLE_ICON}  Descriptions: {state}",
              "__descriptions__",
              "",
              "the line of explanation under every entry, pick to turn it off"]

    order = recent + sections + [r for r in actions if r not in recent] + [toggle]
    for display, _, _, description in order:
        if descriptions and description:
            print(f"{display}{FIELD}{description}")
        else:
            print(display)


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "render":
        render(sys.argv[2], sys.argv[3], sys.argv[4] == "1")
    elif len(sys.argv) > 2 and sys.argv[1] == "build":
        build(sys.argv[2])
    else:
        build(sys.argv[1])


if __name__ == "__main__":
    main()
