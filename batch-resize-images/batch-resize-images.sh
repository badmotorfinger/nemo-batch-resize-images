#!/bin/bash

TEXTDOMAIN="batch-resize-images@badmotorfinger"
TEXTDOMAINDIR="${HOME}/.local/share/locale"

# Images

_IMAGE__TITLE=$"Batch Resize Images"
_IMAGE__PROMPT=$"Choose the resolution to resize ALL selected files to:"
_IMAGE__COLUMN_1=$"Select"
_IMAGE__COLUMN_2=$"Resolution"
_IMAGE__COLUMN_3=$"Description"

_PROGRESS_TITLE=$"Batch Resizing Images"
_PROGRESS_TEXT=$"Processing..."
_NOT_AN_IMAGE=$"is not an image file and will be skipped"

IMAGE__TITLE="$(/usr/bin/gettext "$_IMAGE__TITLE")"
IMAGE__PROMPT="$(/usr/bin/gettext "$_IMAGE__PROMPT")"
IMAGE__COLUMN_1="$(/usr/bin/gettext "$_IMAGE__COLUMN_1")"
IMAGE__COLUMN_2="$(/usr/bin/gettext "$_IMAGE__COLUMN_2")"
IMAGE__COLUMN_3="$(/usr/bin/gettext "$_IMAGE__COLUMN_3")"

PROGRESS_TITLE="$(/usr/bin/gettext "$_PROGRESS_TITLE")"
PROGRESS_TEXT="$(/usr/bin/gettext "$_PROGRESS_TEXT")"
NOT_AN_IMAGE="$(/usr/bin/gettext "$_NOT_AN_IMAGE")"

# Get target resolution from user once for all files
if ! RESOLUTION=$(
  /usr/bin/zenity --list --radiolist \
    --title="$IMAGE__TITLE" \
    --text="$IMAGE__PROMPT" \
    --height=480 \
    --width=720 \
    --column="$IMAGE__COLUMN_1" --column="$IMAGE__COLUMN_2" --column="$IMAGE__COLUMN_3" \
    FALSE "320x240" "QVGA (4:3)" \
    FALSE "640x480" "VGA (4:3)" \
    FALSE "800x600" "SVGA (4:3)" \
    FALSE "1024x768" "XGA (4:3)" \
    FALSE "1280x960" "SXGA (4:3)" \
    FALSE "1600x1200" "UXGA (4:3)" \
    FALSE "854x480" "FWVGA (16:9)" \
    FALSE "1280x720" "HD 720p (16:9)" \
    FALSE "1920x1080" "Full HD 1080p (16:9)" \
    FALSE "2560x1440" "QHD 1440p (16:9)" \
    FALSE "3840x2160" "4K UHD (16:9)" \
    FALSE "480x480" "Square 480x480" \
    FALSE "640x640" "Square 640x640" \
    FALSE "800x800" "Square 800x800" \
    FALSE "1024x1024" "Square 1024x1024" \
    FALSE "1200x1200" "Square 1200x1200" \
    FALSE "1500x1500" "Square 1500x1500" \
    FALSE "2000x2000" "Square 2000x2000" \
    FALSE "480x640" "Portrait 480x640 (3:4)" \
    FALSE "600x800" "Portrait 600x800 (3:4)" \
    FALSE "768x1024" "Portrait 768x1024 (3:4)" \
    FALSE "960x1280" "Portrait 960x1280 (3:4)" \
    FALSE "1200x1600" "Portrait 1200x1600 (3:4)" \
    FALSE "480x854" "Portrait 480x854 (9:16)" \
    FALSE "720x1280" "Portrait 720x1280 (9:16)" \
    FALSE "1080x1920" "Portrait 1080x1920 (9:16)" \
    FALSE "1440x2560" "Portrait 1440x2560 (9:16)" \
    FALSE "2160x3840" "Portrait 2160x3840 (9:16)"
); then
  exit
fi

resize_image() {
  local FILE="$1"
  local DIRECTORY=$(dirname "$FILE")
  local FILENAME=$(basename "$FILE")
  local EXTENSION="${FILENAME##*.}"
  local BASENAME="${FILENAME%.*}"
  
  # Create resized filename
  local OUTPUT_FILE="${DIRECTORY}/${BASENAME}_${RESOLUTION}.${EXTENSION}"
  
  # Resize the image maintaining aspect ratio and fit within the specified dimensions
  /usr/bin/convert "$FILE" -resize "${RESOLUTION}>" "$OUTPUT_FILE"
}

(
  TOTAL_FILES=$#
  COUNT=0
  for FILE in "$@"; do
    MIMETYPE=$(/usr/bin/file --mime-type -b "$FILE")
    if [[ $MIMETYPE == image/* ]]; then
      resize_image "$FILE"
      COUNT=$((COUNT + 1))
      echo "$((COUNT * 100 / TOTAL_FILES))"
      echo "# Resizing $FILE ($COUNT of $TOTAL_FILES)"
    else
      /usr/bin/zenity --warning --text="$FILE $NOT_AN_IMAGE."
    fi
  done
) | /usr/bin/zenity --progress \
  --title="$PROGRESS_TITLE" \
  --text="$PROGRESS_TEXT" \
  --percentage=0 \
  --auto-close