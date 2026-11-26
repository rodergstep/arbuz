#!/usr/bin/env python3
"""Generate every voice line the game can say, as Ogg Vorbis files.

Reads content/words/words.csv and content/voice/lines.csv, expands every line template for
every word, and writes audio/voice/<lang>/<hash>.ogg, where hash = sha1("<lang>|<text>")[:16]
(the same name Speech.voice_path() computes in the game). Existing files are kept, so a re-run
only renders new or changed texts; files no longer needed are removed.

English: Kokoro (kokoro-onnx), Ukrainian: Piper (uk_UA ukrainian_tts). Runs locally, offline
after the one-time model download (see audio_gen/README.md).

Usage:  audio_gen/.venv/bin/python audio_gen/generate_voices.py [--dry-run]
"""
import argparse
import csv
import hashlib
import io
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WORDS = ROOT / "content/words/words.csv"
LINES = ROOT / "content/voice/lines.csv"
OUT = ROOT / "audio/voice"
MODELS = ROOT / "audio_gen/models"

EN_VOICE = "bf_emma"  # British English, warm and clear
EN_SPEED = 0.75  # slower for a three-year-old (playtests: 0.85 too fast, 0.65 a bit too slow)
UK_SPEAKER = 0  # "lada"
UK_LENGTH_SCALE = 1.12  # >1 = slower
# When a voice setting changes, every file of that language is rendered again.
STAMPS = {"en": f"kokoro:{EN_VOICE}:{EN_SPEED}", "uk": f"piper:{UK_SPEAKER}:{UK_LENGTH_SCALE}"}


def article(word: str) -> str:
    return ("an " if word[:1].lower() in "aeiou" else "a ") + word


def capitalize(word: str) -> str:
    # Same as Godot's String.capitalize() for single, lowercase words.
    return " ".join(w[:1].upper() + w[1:] for w in word.replace("_", " ").split())


def fill(template: str, word: dict) -> str:
    return (
        template.replace("{Word}", capitalize(word["en"]))
        .replace("{word}", word["en"])
        .replace("{a_word}", article(word["en"]))
        .replace("{uk_word}", word["uk"])
    )


def voice_name(lang: str, text: str) -> str:
    return hashlib.sha1(f"{lang}|{text}".encode("utf-8")).hexdigest()[:16] + ".ogg"


def collect() -> dict:
    words = list(csv.DictReader(WORDS.open(encoding="utf-8")))
    lines = list(csv.DictReader(LINES.open(encoding="utf-8")))
    texts = {"en": set(), "uk": set()}
    for w in words:
        texts["en"].add(w["en"])
        for sentence in (w.get("examples_en") or "").split("|"):
            if sentence.strip():
                texts["en"].add(sentence.strip())
    for row in lines:
        for lang in ("uk", "en"):
            template = row[lang]
            if not template:
                continue
            if "{" in template:
                for w in words:
                    texts[lang].add(fill(template, w))
            else:
                texts[lang].add(template)
    return texts


def render_en(kokoro, text: str):
    samples, rate = kokoro.create(text, voice=EN_VOICE, speed=EN_SPEED, lang="en-gb")
    return samples, rate


def render_uk(piper_voice, text: str):
    import numpy as np
    from piper import SynthesisConfig

    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        piper_voice.synthesize_wav(
            text.lower(), w, syn_config=SynthesisConfig(speaker_id=UK_SPEAKER, length_scale=UK_LENGTH_SCALE)
        )
    buf.seek(0)
    with wave.open(buf, "rb") as r:
        rate = r.getframerate()
        pcm = np.frombuffer(r.readframes(r.getnframes()), dtype=np.int16)
    return pcm.astype("float32") / 32768.0, rate


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="list what would be rendered")
    args = parser.parse_args()
    texts = collect()
    todo = []
    for lang, items in texts.items():
        (OUT / lang).mkdir(parents=True, exist_ok=True)
        stamp = OUT / lang / "voice-settings.txt"
        if not stamp.exists() or stamp.read_text().strip() != STAMPS[lang]:
            print(f"{lang}: voice settings changed -> render all again")
            if not args.dry_run:
                for old in (OUT / lang).glob("*.ogg"):
                    old.unlink()
                    old.with_name(old.name + ".import").unlink(missing_ok=True)
                stamp.write_text(STAMPS[lang] + "\n")
        wanted = {voice_name(lang, t) for t in items}
        # Godot's import sidecars of files that no longer exist.
        for orphan in (OUT / lang).glob("*.ogg.import"):
            if not orphan.with_suffix("").exists() and not args.dry_run:
                orphan.unlink()
        for stale in (OUT / lang).glob("*.ogg"):
            if stale.name not in wanted:
                print(f"remove {lang}/{stale.name}")
                if not args.dry_run:
                    stale.unlink()
                    stale.with_name(stale.name + ".import").unlink(missing_ok=True)
        for t in sorted(items):
            if not (OUT / lang / voice_name(lang, t)).exists():
                todo.append((lang, t))
    print(f"{sum(len(v) for v in texts.values())} texts, {len(todo)} to render")
    if args.dry_run or not todo:
        return 0
    import soundfile as sf

    kokoro = None
    piper_voice = None
    for i, (lang, t) in enumerate(todo, 1):
        if lang == "en":
            if kokoro is None:
                from kokoro_onnx import Kokoro

                kokoro = Kokoro(str(MODELS / "kokoro-v1.0.fp16.onnx"), str(MODELS / "voices-v1.0.bin"))
            samples, rate = render_en(kokoro, t)
        else:
            if piper_voice is None:
                from piper import PiperVoice

                piper_voice = PiperVoice.load(str(MODELS / "uk_UA-ukrainian_tts-medium.onnx"))
            samples, rate = render_uk(piper_voice, t)
        sf.write(OUT / lang / voice_name(lang, t), samples, rate, format="OGG", subtype="VORBIS")
        print(f"[{i}/{len(todo)}] {lang}: {t}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
