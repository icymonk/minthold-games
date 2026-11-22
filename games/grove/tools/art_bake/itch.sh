#!/usr/bin/env bash
# usage: itch.sh <game-url> <out-dir>  — 무료 itch.io 에셋의 업로드 파일을 모두 받는다
set -euo pipefail
G=$1; OUT=$2; UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120 Safari/537.36"
CJ=$(mktemp); trap 'rm -f "$CJ"' EXIT
c() { curl -sfL -c "$CJ" -b "$CJ" -A "$UA" "$@"; }
csrf=$(c "$G" | grep -oE 'name="csrf_token" value="[^"]+"' | head -1 | sed 's/.*value="//;s/"$//')
DL=$(c -X POST --data-urlencode "csrf_token=$csrf" "$G/download_url" | python3 -c 'import sys,json;print(json.load(sys.stdin)["url"])')
mkdir -p "$OUT"
c "$DL" | python3 -c '
import sys,re,html
s=sys.stdin.read()
for m in re.finditer(r"data-upload_id=\"(\d+)\".*?title=\"([^\"]+)\" class=\"name\"", s, re.S):
    print(m.group(1), html.unescape(m.group(2)))' | while read -r up name; do
  U=$(c -X POST --data-urlencode "csrf_token=$csrf" "$G/file/$up?source=view_game&as_props=1&after_download_lightbox=true" | python3 -c 'import sys,json;print(json.load(sys.stdin)["url"])')
  echo "$name" >&2
  curl -sfL -o "$OUT/$name" "$U"
done
