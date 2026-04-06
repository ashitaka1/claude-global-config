#!/bin/bash
eval "$(/opt/homebrew/bin/brew shellenv)"
source ~/eng/whisperx/.venv/bin/activate
source ~/eng/whisperx/.env
exec python ~/eng/whisperx/transcribe.py "$@"
