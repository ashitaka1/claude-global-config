---
name: transcribe
description: Transcribe audio files with speaker diarization using WhisperX. Use when the user wants to transcribe audio, get meeting notes, identify speakers in a recording, or process any audio/video file into text.
disable-model-invocation: false
argument-hint: <audio-file> [--speakers N]
allowed-tools: Bash(~/.claude/skills/transcribe/run.sh *) Read
---

Transcribe an audio file with speaker diarization and present the results.

## Usage

```
/transcribe <path-to-audio-file> [--speakers N] [--min-speakers N] [--max-speakers N] [--model SIZE]
```

## What it does

1. **Run WhisperX** on the provided audio file
2. **Read the transcript** from the output file
3. **Present results** and ask what the user wants to do (unless they already stated intent)

## Step 1: Run transcription (async)

**IMPORTANT:** Run the transcription in the background using `run_in_background: true` on the Bash tool. This lets the user keep working while the transcription processes.

First, determine the output path so you know where to read from later. The default is `<name>_transcript.txt` alongside the audio file.

```bash
~/.claude/skills/transcribe/run.sh "<audio_file>" [flags]
```

- Pass through any flags the user provides: `--speakers`, `--min-speakers`, `--max-speakers`, `--model`, `-o`
- Stdout contains the path to the transcript file
- The transcript file is written next to the audio file as `<name>_transcript.txt`
- Use `timeout: 600000` (10 minutes)

After launching, tell the user the transcription is running in the background and that they can ask for a status update at any time.

## Checking status

The script writes live status to `/tmp/whisperx_status.json`. When the user asks how the transcription is going (or similar), read that file and report:

- **stage**: `loading_model` → `transcribing` → `transcribing_done` → `aligning` → `diarizing` → `done`
- **elapsed_seconds**: how long it's been running
- **detail**: extra info like segment count or detected language

Report this concisely, e.g. "Diarizing speakers — 3m 42s elapsed."

## Step 2: Read the transcript (when background task completes)

When the background task completes, read the output to get the transcript file path (last line of stdout). Then use the **Read tool** on that path:

- **Short transcripts (< 200 lines):** Read the whole file and show it to the user
- **Long transcripts (200+ lines):** Read the first 50 lines as a preview. Tell the user the total line count and the file path. Then proceed based on their intent.

## Step 3: Follow-up

After showing the transcript (or preview), ask the user what they'd like to do with it. Common follow-ups:

- **Summarize** — condense into key points. For long transcripts, read in chunks and build a running summary.
- **Meeting notes** — extract action items, decisions, and discussion topics
- **Clean up** — rewrite as readable narrative, removing filler words and false starts
- **Extract quotes** — pull out notable statements
- **Relabel speakers** — replace SPEAKER_00/01 with real names
- **Search** — find where a specific topic was discussed

If the user already stated their intent alongside the transcribe command, proceed directly.

When processing long transcripts for summarization or note-taking, read the file in chunks (500 lines at a time) rather than all at once.

## Supported formats

WhisperX (via ffmpeg) handles: `.m4a`, `.mp3`, `.wav`, `.flac`, `.ogg`, `.webm`, `.mp4`, `.mkv`, and most other audio/video formats.

## Tips for better diarization

- Use `--speakers N` when you know the exact number of participants
- Longer recordings with distinct speaker turns produce better diarization than short clips
- The `large-v3` model (default) is the most accurate; use `--model medium` or `--model small` for faster but less accurate results
