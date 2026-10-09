#!/usr/bin/env zsh

ffdesc() {
  if [[ $# -ne 2 ]]; then
    print -u2 'Usage: ffdesc /path/to/video.mp4 "description"'
    return 2
  fi

  local input dir filename ext tmpdir tmpout description
  input=$(realpath -- "$1") || return 1
  description=$2

  if [[ ! -f "$input" ]]; then
    print -u2 "Not a regular file: $input"
    return 1
  fi

  dir=${input:h}
  filename=${input:t}

  if [[ "$filename" != *.* ]]; then
    print -u2 "The video filename needs an extension so FFmpeg can detect its format."
    return 1
  fi
  ext=${filename##*.}

  tmpdir=$(mktemp -d -- "$dir/.ffdesc.XXXXXX") || return 1
  tmpout="$tmpdir/output.$ext"

  if ! ffmpeg -nostdin -i "$input" -map 0 -c copy \
      -metadata "description=$description" "$tmpout"; then
    rm -rf -- "$tmpdir"
    return 1
  fi

  if ! chmod --reference="$input" "$tmpout" ||
     ! mv -f -- "$tmpout" "$input"; then
    rm -rf -- "$tmpdir"
    return 1
  fi

  rmdir -- "$tmpdir"
}
