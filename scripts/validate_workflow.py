#!/usr/bin/env python3
"""Validate the SDD workflow files under .claude/.

Checks:
  1. every .claude/skills/<name>/SKILL.md has frontmatter with name == <name> and a description
  2. every .claude/agents/*.md has frontmatter with name == file stem, description, model, tools
  3. every `agents: [...]` entry in a skill names an existing agent
  4. every relative Markdown link in .claude/ resolves (templates excepted: their links
     are relative to where the filled-in copy will live)
  5. no leftovers of the original plugin (sdd: prefixes, removed stages, removed shared files)
  6. every _shared/*.md is referenced from at least one other file

Run from the repo root:  python3 scripts/validate_workflow.py
Exit code 0 = clean, 1 = problems found.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLAUDE = ROOT / ".claude"
SKILLS = CLAUDE / "skills"
AGENTS = CLAUDE / "agents"

LEFTOVERS = [
    (re.compile(r"(?<![\w.])/?sdd:[a-z]"), "plugin prefix sdd:"),
    (re.compile(r"tool-adapters\.md|surfaces\.md|artifact-language\.md"), "removed shared file"),
    (re.compile(r"\bdata-model\.md\b|openapi\.ya?ml|screens\.md|sequences/SKILL"), "removed stage artifact"),
    (re.compile(r"/(data-model|api|screens|sequences)\b(?!/)"), "removed stage command"),
    (re.compile(r"\b(team_mode|workflow_mode|max_parallel_agents|artifact_language|target_surfaces)\b"), "removed setting"),
    (re.compile(r"idea-brief\.md"), "old idea path"),
]

LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")

problems = []


def frontmatter(path):
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        return None, text
    end = text.find("\n---", 4)
    if end == -1:
        return None, text
    block = text[4:end]
    data = {}
    key = None
    for line in block.splitlines():
        m = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", line)
        if m:
            key = m.group(1)
            data[key] = m.group(2).strip()
        elif key and line.startswith("  "):
            data[key] = (data[key] + " " + line.strip()).strip()
    return data, text


def rel(p):
    return p.relative_to(ROOT).as_posix()


agent_names = set()
for path in sorted(AGENTS.glob("*.md")):
    fm, _ = frontmatter(path)
    if fm is None:
        problems.append(f"{rel(path)}: missing frontmatter")
        continue
    if fm.get("name") != path.stem:
        problems.append(f"{rel(path)}: name '{fm.get('name')}' != file name '{path.stem}'")
    for k in ("description", "model", "tools"):
        if not fm.get(k) or fm.get(k) == ">":
            problems.append(f"{rel(path)}: missing '{k}'")
    agent_names.add(path.stem)

for skill_dir in sorted(p for p in SKILLS.iterdir() if p.is_dir() and not p.name.startswith("_")):
    path = skill_dir / "SKILL.md"
    if not path.exists():
        problems.append(f"{rel(skill_dir)}: no SKILL.md")
        continue
    fm, _ = frontmatter(path)
    if fm is None:
        problems.append(f"{rel(path)}: missing frontmatter")
        continue
    if fm.get("name") != skill_dir.name:
        problems.append(f"{rel(path)}: name '{fm.get('name')}' != dir '{skill_dir.name}'")
    desc = fm.get("description", "")
    if not desc or desc == ">":
        problems.append(f"{rel(path)}: missing description")
    elif len(desc) > 1024:
        problems.append(f"{rel(path)}: description is {len(desc)} chars (max 1024)")
    agents = fm.get("agents", "")
    for a in re.findall(r"[\w-]+", agents):
        if a not in agent_names:
            problems.append(f"{rel(path)}: agents lists unknown agent '{a}'")

all_md = sorted(CLAUDE.rglob("*.md"))
referenced = set()
for path in all_md:
    text = path.read_text(encoding="utf-8")
    for target in LINK.findall(text):
        if re.match(r"^[a-z]+:", target) or target.startswith("#"):
            continue
        target = target.split("#", 1)[0]
        if not target or "<" in target or "{" in target:
            continue
        resolved = (path.parent / target).resolve()
        if resolved.exists():
            referenced.add(resolved)
        elif "/templates/" in path.as_posix():
            pass  # template links point at where the copied file will live
        elif not target.startswith(("docs/", "../docs", "tests/", "CHANGELOG")):
            problems.append(f"{rel(path)}: broken link -> {target}")
    for i, line in enumerate(text.splitlines(), 1):
        for rx, label in LEFTOVERS:
            if rx.search(line):
                problems.append(f"{rel(path)}:{i}: {label}: {line.strip()[:100]}")

for path in sorted((SKILLS / "_shared").glob("*.md")):
    if path.resolve() not in referenced:
        problems.append(f"{rel(path)}: not referenced by any other file")

if problems:
    print(f"{len(problems)} problem(s):")
    for p in problems:
        print("  - " + p)
    sys.exit(1)
print(f"OK: {len(agent_names)} agents, {sum(1 for p in SKILLS.iterdir() if p.is_dir() and not p.name.startswith('_'))} skills, {len(all_md)} markdown files checked.")
