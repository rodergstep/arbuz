#!/usr/bin/env python3
"""Generate every voice line the game can say, as Ogg Vorbis files.

Reads content/words/words.csv and content/voice/lines.csv, expands every line template for
every word, and writes audio/voice/<lang>/<hash>.ogg, where hash = sha1("<lang>|<text>")[:16]
(the same name Speech.voice_path() computes in the game). Existing files are kept, so a re-run
only renders new or changed texts; files no longer needed are removed.

English: Chatterbox TTS (Resemble AI, MIT licence), each speaker's voice cloned from a short
reference clip in audio_gen/voices_ref/<speaker>.wav (Tygrytsa: tygrytsa.wav). Ukrainian: Piper
(uk_UA ukrainian_tts). Runs locally, offline after the one-time model download (see
audio_gen/README.md).

Usage:  audio_gen/.venv-chatterbox/bin/python audio_gen/generate_voices.py [--dry-run]
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
VOICES_REF = ROOT / "audio_gen/voices_ref"

# Speakers (the `speaker` column of lines.csv) other than Tygrytsa, each with a reference clip.
SPEAKER_VOICES = {s: f"{s}.wav" for s in ("postman", "baker", "toymaker", "farmer", "clockmaker")}
# Chatterbox: a little warmth (exaggeration) at the natural pace (cfg_weight 0.5); slowness comes
# from pauses between sentences, never from stretching (playtests).
EN_EXAGGERATION = 0.55
EN_CFG = 0.5
UK_SPEAKER = 0  # "lada"
UK_LENGTH_SCALE = 1.0  # natural pace
# When a voice setting changes, every file of that language is rendered again.
SENTENCE_PAUSE = 0.45  # seconds of silence between sentences of one line
STAMPS = {
    "en": f"chatterbox:ref-v1:exag{EN_EXAGGERATION}:cfg{EN_CFG}:pause{SENTENCE_PAUSE}",
    "uk": f"piper:{UK_SPEAKER}:{UK_LENGTH_SCALE}:pause{SENTENCE_PAUSE}",
}


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
    """text may be "speaker|line" for a speaker other than Tygrytsa (see Speech.voice_path)."""
    return hashlib.sha1(f"{lang}|{text}".encode("utf-8")).hexdigest()[:16] + ".ogg"


def split_speaker(text: str):
    head, sep, rest = text.partition("|")
    if sep and head in SPEAKER_VOICES:
        return head, rest
    return "", text


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
            # Only the English of a speaker's line uses their voice; Ukrainian is Tygrytsa's.
            speaker = (row.get("speaker") or "") if lang == "en" else ""
            prefix = f"{speaker}|" if speaker else ""
            if "{" in template:
                # The `words` column narrows a template to the words it is used with
                # ("topic:food" or word ids); empty = every word.
                only = (row.get("words") or "").split()
                for w in words:
                    if only and w["id"] not in only and f"topic:{w.get('topic', '')}" not in only:
                        continue
                    texts[lang].add(prefix + fill(template, w))
            else:
                texts[lang].add(prefix + template)
    return texts


def sentences(text: str) -> list:
    """Splits a line into sentences, keeping their punctuation."""
    import re

    return [s for s in re.split(r"(?<=[.!?])\s+", text.strip()) if s]


def with_pauses(parts: list, rate: int):
    """Joins rendered sentences with a short silence: a calmer pace with a natural voice."""
    import numpy as np

    gap = np.zeros(int(SENTENCE_PAUSE * rate), dtype="float32")
    out = []
    for i, part in enumerate(parts):
        if i:
            out.append(gap)
        out.append(np.asarray(part, dtype="float32"))
    return np.concatenate(out), rate


def trim(samples, rate: int, threshold: float = 0.01, pad: float = 0.08):
    """Cuts silence (and Chatterbox's occasional quiet tail) from both ends, keeping a short pad."""
    import numpy as np

    loud = np.nonzero(np.abs(samples) > threshold)[0]
    if loud.size == 0:
        return samples
    start = max(0, int(loud[0] - pad * rate))
    end = min(len(samples), int(loud[-1] + pad * rate))
    return samples[start:end]


def render_en(model, text: str):
    speaker, text = split_speaker(text)
    ref = VOICES_REF / SPEAKER_VOICES.get(speaker, "tygrytsa.wav")
    parts = []
    for sentence in sentences(text):
        wav = model.generate(sentence, audio_prompt_path=str(ref), exaggeration=EN_EXAGGERATION, cfg_weight=EN_CFG)
        parts.append(trim(wav.squeeze(0).cpu().numpy(), model.sr))
    return with_pauses(parts, model.sr)


def render_uk(piper_voice, text: str):
    parts = []
    rate = 22050
    for sentence in sentences(text):
        samples, rate = render_uk_one(piper_voice, sentence)
        parts.append(samples)
    return with_pauses(parts, rate)


def render_uk_one(piper_voice, text: str):
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
        rebuild = not stamp.exists() or stamp.read_text().strip() != STAMPS[lang]
        if rebuild:
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
        # Other speakers' voices have their own stamp: changing one re-renders their lines only.
        speaker_stamp = OUT / lang / "speaker-voices.txt"
        speakers_now = ",".join(f"{k}={v}" for k, v in sorted(SPEAKER_VOICES.items())) if lang == "en" else ""
        rebuild_speakers = speaker_stamp.exists() is False or speaker_stamp.read_text().strip() != speakers_now
        if rebuild_speakers and lang == "en" and not args.dry_run:
            speaker_stamp.write_text(speakers_now + "\n")
        for t in sorted(items):
            # After a settings change every line is rendered again (also counted in --dry-run).
            stale_speaker = rebuild_speakers and lang == "en" and split_speaker(t)[0] != ""
            if rebuild or stale_speaker or not (OUT / lang / voice_name(lang, t)).exists():
                todo.append((lang, t))
    print(f"{sum(len(v) for v in texts.values())} texts, {len(todo)} to render")
    if args.dry_run or not todo:
        return 0
    import soundfile as sf

    chatterbox = None
    piper_voice = None
    for i, (lang, t) in enumerate(todo, 1):
        if lang == "en":
            if chatterbox is None:
                import torch
                from chatterbox.tts import ChatterboxTTS

                device = "mps" if torch.backends.mps.is_available() else "cpu"
                chatterbox = ChatterboxTTS.from_pretrained(device=device)
            samples, rate = render_en(chatterbox, t)
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
