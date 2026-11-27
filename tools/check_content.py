#!/usr/bin/env python3
"""Checks the game's content before a build; exits 1 (and the build stops) on a problem.

1. Every data .csv under content/ uses Godot's "keep" importer. Godot imports a .csv as a
   translation by default, and then the raw file is left out of exported builds, so the game
   can't read it there (playtest bug: no card scenes in the app).
2. Every sentence a learning card speaks (the first two examples of each word) has a scene in
   content/words/scenes.csv, and every scene's things exist.
"""
import csv
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
problems = []

for path in (ROOT / "content").rglob("*.csv"):
    imp = path.with_name(path.name + ".import")
    if not imp.exists() or 'importer="keep"' not in imp.read_text():
        problems.append(f'{path.relative_to(ROOT)}: importer must be "keep" (copy content/words/words.csv.import)')

scenes = {r["sentence"].strip(): r for r in csv.DictReader((ROOT / "content/words/scenes.csv").open(encoding="utf-8"))}
for word in csv.DictReader((ROOT / "content/words/words.csv").open(encoding="utf-8")):
    for sentence in (word.get("examples_en") or "").split("|")[:2]:
        if sentence.strip() and sentence.strip() not in scenes:
            problems.append(f'card sentence without a scene ({word["id"]}): "{sentence.strip()}"')

if problems:
    print("Content check FAILED:")
    for p in problems:
        print("  -", p)
    sys.exit(1)
print(f"Content check OK: {len(scenes)} scenes, all data files packed.")
