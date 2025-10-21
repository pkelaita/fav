#!/bin/bash

# Utility script to convert SVGs to favicon ICOs

set -u

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 1; }; }
need magick

prompt_with_default() {
  local prompt="$1" def="$2" outvar="$3" reply=""
  read -e -p "$prompt [$def]: " reply
  [[ -z "$reply" ]] && reply="$def"
  eval "$outvar=\"\$reply\""
}

normalize_path() {
  local p="$1"
  # strip quotes
  [[ "$p" == \"*\" && "$p" == *\" ]] && p="${p%\"}" && p="${p#\"}"
  [[ "$p" == \'*\' && "$p" == *\' ]] && p="${p%\'}" && p="${p#\'}"
  # unescape spaces
  p="${p//\\ / }"
  # expand ~
  [[ "$p" == "~"* ]] && p="${p/#\~/$HOME}"
  # canonicalize if possible
  if command -v realpath >/dev/null 2>&1; then
    p="$(realpath -m -- "$p" 2>/dev/null || echo "$p")"
  fi
  printf '%s' "$p"
}


# Get in/out paths

while :; do
  DEFAULT_IN="favicon.svg"
  prompt_with_default "Input SVG path" "$DEFAULT_IN" IN_RAW
  IN="$(normalize_path "$IN_RAW")"
  if [[ -d "$IN" ]]; then
    echo "That’s a directory. Please enter a file inside it."
    continue
  fi
  if [[ ! -f "$IN" ]]; then
    echo "File not found: $IN"
    continue
  fi
  break
done

DEFAULT_OUT="$(dirname "$IN")/favicon.ico"
prompt_with_default "Output ICO path" "$DEFAULT_OUT" OUT_RAW
OUT="$(normalize_path "$OUT_RAW")"
OUT_DIR="$(dirname "$OUT")"
if [[ ! -d "$OUT_DIR" ]]; then
  echo "Creating directory: $OUT_DIR"
  mkdir -p "$OUT_DIR"
fi


# Convert file

TMP_ERR="$(mktemp)"

if ! magick -background none "$IN" \
    -define icon:auto-resize=256,128,64,48,32,16 \
    "$OUT" 2>"$TMP_ERR"
then
  echo "Conversion failed:"
  cat "$TMP_ERR"
  rm -f "$TMP_ERR"
  exit 1
fi

rm -f "$TMP_ERR"
echo "Done → $OUT"

if command -v identify >/dev/null 2>&1; then
  identify -format "%f: %wx%h\n" "$OUT" || true
fi
