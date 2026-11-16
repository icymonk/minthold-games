#!/usr/bin/env bash
# Kenney CC0 팩을 kenney/ 아래로 내려받고, 3D 모델을 models/로 복사한다.
set -euo pipefail
cd "$(dirname "$0")"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"
PACKS=(car-kit city-kit-commercial platformer-pack-industrial background-elements-remastered ui-pack cursor-pack impact-sounds interface-sounds)
mkdir -p kenney
for s in "${PACKS[@]}"; do
	[ -d "kenney/$s" ] && continue
	id=$(printf "assets/%s" "$s" | xxd -p | tr -d '\n')
	url=$(curl -s -A "$UA" "https://kenney.nl/download-link/$id" | python3 -c 'import sys,json; print(json.load(sys.stdin)["url"])')
	curl -sL -A "$UA" -o "kenney/$s.zip" "$url"
	mkdir -p "kenney/$s" && unzip -qo "kenney/$s.zip" -d "kenney/$s" && rm "kenney/$s.zip"
done
mkdir -p models/car models/city
cp -r "kenney/car-kit/Models/GLB format/." models/car/
cp -r "kenney/city-kit-commercial/Models/GLB format/." models/city/
