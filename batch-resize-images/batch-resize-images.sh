#!/bin/bash

TEXTDOMAIN="batch-resize-images@badmotorfinger"
TEXTDOMAINDIR="${HOME}/.local/share/locale"

if [[ $# -eq 0 ]]; then
  exit 0
fi

# Images

_IMAGE__TITLE=$"Batch Resize Images"
_IMAGE__PROMPT=$"Choose the resolution to resize ALL selected files to:"
_IMAGE__COLUMN_1=$"Select"
_IMAGE__COLUMN_2=$"Resolution"
_IMAGE__COLUMN_3=$"Description"

_PROGRESS_TITLE=$"Batch Resizing Images"
_PROGRESS_TEXT=$"Processing..."
_NOT_AN_IMAGE=$"is not an image file and will be skipped"
_RESIZE_FAILED=$"could not be resized"

IMAGE__TITLE="$(gettext "$_IMAGE__TITLE")"
IMAGE__PROMPT="$(gettext "$_IMAGE__PROMPT")"
IMAGE__COLUMN_1="$(gettext "$_IMAGE__COLUMN_1")"
IMAGE__COLUMN_2="$(gettext "$_IMAGE__COLUMN_2")"
IMAGE__COLUMN_3="$(gettext "$_IMAGE__COLUMN_3")"

PROGRESS_TITLE="$(gettext "$_PROGRESS_TITLE")"
PROGRESS_TEXT="$(gettext "$_PROGRESS_TEXT")"
NOT_AN_IMAGE="$(gettext "$_NOT_AN_IMAGE")"
RESIZE_FAILED="$(gettext "$_RESIZE_FAILED")"

# Get target resolution from user once for all files
RESOLUTIONS=(
  "320x240"   "QVGA (4:3)"
  "640x480"   "VGA (4:3)"
  "800x600"   "SVGA (4:3)"
  "1024x768"  "XGA (4:3)"
  "1280x960"  "SXGA (4:3)"
  "1600x1200" "UXGA (4:3)"
  "854x480"   "FWVGA (16:9)"
  "1280x720"  "HD 720p (16:9)"
  "1920x1080" "Full HD 1080p (16:9)"
  "2560x1440" "QHD 1440p (16:9)"
  "3840x2160" "4K UHD (16:9)"
  "480x480"   "Square 480x480"
  "640x640"   "Square 640x640"
  "800x800"   "Square 800x800"
  "1024x1024" "Square 1024x1024"
  "1200x1200" "Square 1200x1200"
  "1500x1500" "Square 1500x1500"
  "2000x2000" "Square 2000x2000"
  "480x640"   "Portrait 480x640 (3:4)"
  "600x800"   "Portrait 600x800 (3:4)"
  "768x1024"  "Portrait 768x1024 (3:4)"
  "960x1280"  "Portrait 960x1280 (3:4)"
  "1200x1600" "Portrait 1200x1600 (3:4)"
  "480x854"   "Portrait 480x854 (9:16)"
  "720x1280"  "Portrait 720x1280 (9:16)"
  "1080x1920" "Portrait 1080x1920 (9:16)"
  "1440x2560" "Portrait 1440x2560 (9:16)"
  "2160x3840" "Portrait 2160x3840 (9:16)"
)

RADIO_ROWS=()
for ((i = 0; i < ${#RESOLUTIONS[@]}; i += 2)); do
  RADIO_ROWS+=(FALSE "${RESOLUTIONS[i]}" "${RESOLUTIONS[i + 1]}")
done

if ! RESOLUTION=$(
  zenity --list --radiolist \
    --title="$IMAGE__TITLE" \
    --text="$IMAGE__PROMPT" \
    --height=480 \
    --width=720 \
    --column="$IMAGE__COLUMN_1" --column="$IMAGE__COLUMN_2" --column="$IMAGE__COLUMN_3" \
    "${RADIO_ROWS[@]}"
); then
  exit
fi

resize_image() {
  local FILE="$1"
  local MIMETYPE="$2"
  local DIRECTORY; DIRECTORY=$(dirname "$FILE")
  local FILENAME; FILENAME=$(basename "$FILE")
  local EXTENSION BASENAME

  if [[ $FILENAME == ?*.* ]]; then
    EXTENSION="${FILENAME##*.}"
    BASENAME="${FILENAME%.*}"
  else
    BASENAME="$FILENAME"
    EXTENSION="${MIMETYPE#image/}"
    [[ $EXTENSION == jpeg ]] && EXTENSION="jpg"
  fi

  # Create resized filename
  local OUTPUT_FILE="${DIRECTORY}/${BASENAME}_${RESOLUTION}.${EXTENSION}"

  # Resize the image maintaining aspect ratio and fit within the specified dimensions
  convert "$FILE" -resize "${RESOLUTION}>" "$OUTPUT_FILE"
}

SKIPPED=$(mktemp)
FAILED=$(mktemp)
trap 'rm -f "$SKIPPED" "$FAILED"' EXIT

(
  TOTAL_FILES=$#
  PROCESSED=0
  for FILE in "$@"; do
    PROCESSED=$((PROCESSED + 1))
    MIMETYPE=$(file --mime-type -b "$FILE")
    if [[ $MIMETYPE == image/* ]]; then
      if resize_image "$FILE" "$MIMETYPE"; then
        echo "# Resizing $FILE ($PROCESSED of $TOTAL_FILES)"
      else
        printf '%s\n' "$FILE" >> "$FAILED"
      fi
    else
      printf '%s\n' "$FILE" >> "$SKIPPED"
    fi
    echo "$((PROCESSED * 100 / TOTAL_FILES))"
  done
) | zenity --progress \
  --title="$PROGRESS_TITLE" \
  --text="$PROGRESS_TEXT" \
  --percentage=0 \
  --auto-close

if [[ -s "$SKIPPED" || -s "$FAILED" ]]; then
  NOTICE=""
  while IFS= read -r f; do
    NOTICE+="$f $NOT_AN_IMAGE."$'\n'
  done < "$SKIPPED"
  while IFS= read -r f; do
    NOTICE+="$f $RESIZE_FAILED."$'\n'
  done < "$FAILED"
  zenity --warning --text="$NOTICE"
fi
