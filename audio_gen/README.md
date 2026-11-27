# Voice generation

Generates every line the game says as Ogg Vorbis files in `audio/voice/<lang>/`, from
`content/words/words.csv` (words and example sentences) and `content/voice/lines.csv` (Tygrytsa's
lines, templates with `{word}`, `{Word}`, `{a_word}`, `{uk_word}`). Runs locally and offline after
the one-time setup. Free, open models only: Chatterbox TTS (English, Resemble AI, MIT; each character cloned from a short clip in `audio_gen/voices_ref/`, Tygrytsa = `tygrytsa.wav`) and Piper (Ukrainian,
`uk_UA-ukrainian_tts`, speaker "lada"). The calm pace for a toddler comes from silence between
sentences (0.45 s, rendered into the file) and between lines (0.5 s, in the game), never from
slowing or stretching the voice, which sounds unnatural (playtest).
Changing a voice setting re-renders that language (`voice-settings.txt` stamp per folder).

## One-time setup (M4)

```bash
uv venv -p 3.11 audio_gen/.venv-chatterbox
VIRTUAL_ENV=audio_gen/.venv-chatterbox uv pip install chatterbox-tts soundfile piper-tts "setuptools<81"
mkdir -p audio_gen/models && cd audio_gen/models
curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/uk/uk_UA/ukrainian_tts/medium/uk_UA-ukrainian_tts-medium.onnx
curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/uk/uk_UA/ukrainian_tts/medium/uk_UA-ukrainian_tts-medium.onnx.json
```

`.venv/` and `models/` are gitignored.

## Run after any word or line change

```bash
audio_gen/.venv-chatterbox/bin/python audio_gen/generate_voices.py
```

It renders only new texts and deletes files nothing uses any more (`--dry-run` lists them).
File name = first 16 hex chars of `sha1("<lang>|<text>")`, the same as `Speech.voice_path()`,
so the game finds a line by its exact text. A text without a file falls back to the system voice.

Chatterbox downloads its model from Hugging Face on first use (~2 GB, cached). On the M4 (MPS) a
line takes about 8 s, so a full English re-render (~1450 lines) takes a few hours. The `words`
column of lines.csv narrows a `{word}` template to the words it is used with.
