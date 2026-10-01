# ![](icons/film.png) transcribe

Right-click a video and get an .srt transcript saved right next to it

Windows · macOS · Linux

<!-- media: hero -->
![transcribe turning a short video into subtitles in a terminal](docs/terminal.png)

[Watch it run (11 seconds)](docs/demo.mp4)
<!-- /media: hero -->

## What it is

This one takes a video, pulls the audio out with ffmpeg and runs it through Whisper, then drops an .srt file next to the original. I mostly use it from the right-click menu in Explorer so I don't have to think about it.

It runs on the GPU with CUDA if it can and falls back to the CPU if that fails. There's also a speaker mode that labels lines as SPEAKER_00, SPEAKER_01 and so on, it doesn't know who anyone actually is though.

On Windows the regular command uses faster-whisper-xxl, with a CPU retry if CUDA fails. On macOS and Linux it uses the Python faster-whisper package, with CPU inference unless CUDA is available. Speaker mode uses Python on all platforms.

## Get it

Paste this into your AI coding agent (Claude Code, Codex, Cursor...):

> Clone https://github.com/mikecann/transcribe and make it my own. It's one of Mike
> Cann's personal tools, so read the README first, change anything specific to his
> setup to suit mine, then help me get it running.

### Or set it up by hand

Clone the repo and keep it where you want the source to live. The installed launchers point at this clone, so rerun the installer if you move it.

```bash
git clone https://github.com/mikecann/transcribe.git
cd transcribe
```

**Windows:** You'll need PowerShell and the binaries listed under Dependencies below. Put them in `C:\dev\tools`, then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

The installer writes command stubs into `C:\dev\tools`, offers to add it to your user PATH, registers the two Explorer commands and runs `deps.ps1`. Open a new terminal afterwards. Use `-SkipDeps` to skip dependency checks. Speaker mode also needs Python 3.10 or newer and the optional packages below. Clone to a path with ASCII characters so CMD can read the generated batch stub.

**macOS / Linux:** You'll need Python 3.10 or newer, pip and ffmpeg. On macOS, `deps.sh` can install ffmpeg through Homebrew. On Linux, install ffmpeg through your package manager first.

```bash
bash deps.sh
bash install.sh
```

The installer links `transcribe` into `~/.local/bin` and prints a PATH setting if needed. You can also choose a destination with `bash install.sh /path/to/bin`.

If your Python installation blocks `pip install --user`, use a virtual environment instead, and keep it activated when running the launcher:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install faster-whisper
bash install.sh
```

Regular transcription needs no API key. For speaker mode, copy `.env.example` to `.env` in this clone and fill in `HF_TOKEN` after accepting the model terms, as described below. The Python command reads that file wherever you run it from; existing environment variables take precedence. Optional model settings are listed there too.

## Using it

```bash
transcribe /path/to/video.mp4 --cpu
transcribe /path/to/meeting.mp4 --diarize --model large-v3 --min-speakers 2 --max-speakers 4
```

The transcript is saved as `<input_basename>.srt` beside the input file. Existing transcripts at that path are replaced. Audio files work too.

In Windows File Explorer, right-click a video and choose **Mike's Tools > Transcribe Video** or **Transcribe with Speakers**. On Windows 11, click **Show more options** first. Speaker mode passes `--diarize --model large-v3` for a higher-quality transcript.

The Explorer commands cover `.mp4`, `.mkv`, `.avi`, `.mov`, `.wmv`, `.webm`, `.m4v`, `.mpg`, `.mpeg`, `.ts`, `.mts`, `.m2ts`, `.flv` and `.f4v`.

| Argument | Description |
|---|---|
| `<video_file>` | Video or audio file to transcribe |
| `--cpu` | Force CPU inference |
| `--diarize` | Add speaker labels with pyannote.audio |
| `--model <name>` | Whisper model for the Python path, including Windows speaker mode |
| `--num-speakers <n>` | Exact number of speakers |
| `--min-speakers <n>` / `--max-speakers <n>` | Speaker-count range, instead of an exact count |
| `--hf-token <token>` | Token for speaker mode, alternatively use `.env` |
| `--diarization-model <name>` | Override the Python speaker model |

The ordinary Windows EXE path handles `--cpu`; the other options in this table apply to the Python path.

## Speaker diarization

```powershell
transcribe C:\videos\meeting.mp4 --diarize --min-speakers 2 --max-speakers 4
```

This labels speakers as `SPEAKER_00`, `SPEAKER_01`, etc. It does not know real names like "Mike".

`--diarize` uses [pyannote.audio](https://huggingface.co/pyannote) with the default `pyannote/speaker-diarization-community-1` model. Before first use:

1. Install the optional packages:

   ```powershell
   python -m pip install faster-whisper pyannote.audio
   ```

   On macOS / Linux, outside a virtual environment, you can also use:

   ```bash
   bash deps.sh --with-diarize
   ```

2. Request or accept access to [the pyannote model](https://huggingface.co/pyannote/speaker-diarization-community-1) using the same account as your token.
3. Create a [Hugging Face token](https://hf.co/settings/tokens).
4. Set `HF_TOKEN` or `HUGGINGFACE_TOKEN`, add `HF_TOKEN=...` to this clone's `.env`, or pass `--hf-token <token>`.

On Windows, only `--diarize` switches to Python because the standalone EXE does not output speaker diarization. You can choose a smaller model from the terminal:

```powershell
transcribe C:\videos\meeting.mp4 --diarize --model small
```

## Models and settings

The Python path defaults to `small`. Override it with `TRANSCRIBE_MODEL` or `--model`. `base` and `small` download quickly and are useful for drafts. For closer parity with large Windows runs, use `large-v3`, which is a much larger download and slower on CPU.

Set `TRANSCRIBE_DIARIZATION_MODEL` or pass `--diarization-model` to choose a different speaker model. Model files are downloaded on first use. No transcription service receives the audio; inference runs locally.

## Dependencies (Windows)

Large binaries must be downloaded manually and placed in `C:\dev\tools`:

| File | Download |
|---|---|
| `ffmpeg.exe` | [ffmpeg downloads](https://ffmpeg.org/download.html) |
| `faster-whisper-xxl.exe` | [faster-whisper-xxl releases](https://github.com/Purfview/whisper-standalone-win/releases) |
| `_models\` | Create this folder; faster-whisper-xxl downloads models on first run |

Run `deps.ps1` or `install.ps1` to check these. The installed Windows stub sets `EXEDIR` to `C:\dev\tools\`. Direct calls to `transcribe.bat` default to the batch file's directory, so set `EXEDIR` with a trailing backslash if your binaries are elsewhere.

## Screenshots

![transcribe header](docs/header.webp)

![transcribe screenshot](docs/ss1.png)

## Troubleshooting and notes

- The input needs an audio track. The Python path checks for one when ffprobe is available.
- CUDA inference uses `float16`; the Python CPU path uses `int8`. The Windows EXE retries on CPU if CUDA fails. If the Python CUDA path fails, rerun with `--cpu`.
- Audio is extracted to a temporary 16 kHz mono WAV and cleaned up after transcription.
- For a Hugging Face 403, accept the model's terms with the same account that owns the token.
- If the command is missing, check PATH and rerun the installer after moving the clone.

## Uninstall

On Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

This removes transcribe's stubs and two Explorer verbs. It keeps the shared submenu, PATH entry, binaries, models, `.env` and the shared menu icon, since other tools may still use them.

On macOS / Linux, remove the installed symlink, using your chosen directory if different:

```bash
rm ~/.local/bin/transcribe
```

## Development

In an activated virtual environment, install the test dependencies and run:

```bash
python -m pip install numpy torch
python -m unittest discover -v
bash -n install.sh deps.sh transcribe
./transcribe --help
```

Tests exercise transcript formatting, speaker assignment, WAV loading, clone-local settings and POSIX installation. They do not download models or need a GPU or token. With PowerShell installed, run `pwsh -NoProfile -File ./test-install.ps1` to check batch stubs and icon conversion. Windows also checks shared-menu preservation in a disposable registry branch. CI parses every PowerShell script.

## More tools

You can find my other tools at [mikerosoft.app](https://mikerosoft.app).

MIT licensed.
