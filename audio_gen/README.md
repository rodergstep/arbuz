# Voice generation

Generates every line the game says as Ogg Vorbis files in `audio/voice/<lang>/`, from
`content/words/words.csv` (words and example sentences) and `content/voice/lines.csv` (Тигриця's
lines, templates with `{word}`, `{Word}`, `{a_word}`, `{uk_word}`). Runs locally and offline after
the one-time setup. Free, open models only: Kokoro (English, voice `bf_emma`) and Piper
(Ukrainian, `uk_UA-ukrainian_tts`, speaker "lada").

## One-time setup (M4)

```bash
python3 -m venv audio_gen/.venv
audio_gen/.venv/bin/pip install kokoro-onnx soundfile piper-tts
mkdir -p audio_gen/models && cd audio_gen/models
gh release download model-files-v1.1 -R thewh1teagle/kokoro-onnx -p kokoro-v1.0.fp16.onnx
gh release download model-files-v1.0 -R thewh1teagle/kokoro-onnx -p voices-v1.0.bin
curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/uk/uk_UA/ukrainian_tts/medium/uk_UA-ukrainian_tts-medium.onnx
curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/uk/uk_UA/ukrainian_tts/medium/uk_UA-ukrainian_tts-medium.onnx.json
```

`.venv/` and `models/` are gitignored.

## Run after any word or line change

```bash
audio_gen/.venv/bin/python audio_gen/generate_voices.py
```

It renders only new texts and deletes files nothing uses any more (`--dry-run` lists them).
File name = first 16 hex chars of `sha1("<lang>|<text>")`, the same as `Speech.voice_path()`,
so the game finds a line by its exact text. A text without a file falls back to the system voice.
