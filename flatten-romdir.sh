#!/bin/bash

# Allowed file extensions for hardlinking
allowed_exts=".a26 .a52 .a78 .adf .adfd .agb .bin .chd .col .crt .cue .d64 .dms .fds .fig .gb .gba .gbc .gen .gg .g64 .img .iso .j64 .lnx .mdf .mds .md .nes .n64 .nds .ngc .ngp .pce .prg .rom .sfc .smd .smc .sms .t64 .tap .v64 .vb .wad .wsc .ws .z64 .zip .7z .rar"

dryrun=0

# Check for --dryrun option
if [ "$1" = "--dryrun" ]; then
  dryrun=1
  shift
fi

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 [--dryrun] <source_directory> <flat_directory>" >&2
  exit 1
fi

src_dir="$1"
flat_dir="$2"

# Validate source directory
if [ ! -d "$src_dir" ]; then
  echo "Error: Source directory '$src_dir' does not exist or is not a directory." >&2
  exit 2
fi

# Validate flat directory
if [ ! -d "$flat_dir" ]; then
  echo "Error: Flat directory '$flat_dir' does not exist or is not a directory." >&2
  exit 3
fi

find "$src_dir" -type f -print0 | while IFS= read -r -d $'\0' file; do
  dest="$flat_dir/$(basename "$file")"
  ext=".${file##*.}"
  # Only process allowed extensions
  if [[ " $allowed_exts " != *" $ext "* ]]; then
    [ "$dryrun" -eq 1 ] && echo "Skipping (ext not allowed): '$file'"
    continue
  fi
  # Avoid linking file onto itself
  if [ "$file" != "$dest" ]; then
    # Skip if destination already exists and is hardlinked to source
    if [ -e "$dest" ] && [ "$(stat -c %i "$file")" = "$(stat -c %i "$dest")" ]; then
      [ "$dryrun" -eq 1 ] && echo "Already linked: '$file' -> '$dest' (skipped)"
      continue
    fi
    # If destination exists and is a regular file, compare hashes
    if [ -e "$dest" ] && [ -f "$dest" ]; then
      src_hash=$(sha256sum "$file" | awk '{print $1}')
      dest_hash=$(sha256sum "$dest" | awk '{print $1}')
      if [ "$src_hash" = "$dest_hash" ]; then
        [ "$dryrun" -eq 1 ] && echo "Already present with same hash: '$file' -> '$dest' (skipped)"
        continue
      fi
    fi
    if [ "$dryrun" -eq 1 ]; then
      echo "Would link: '$file' -> '$dest'"
    else
      ln "$file" "$dest"
    fi
  fi
done
