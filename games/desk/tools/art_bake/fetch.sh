#!/usr/bin/env bash
# Kenney CC0 팩을 kenney/ 아래로 내려받고, 3D 가구 모델을 models/로 복사한다.
# kenney.nl은 자산 페이지에서 받은 세션 쿠키가 있어야 download-link를 돌려준다.
set -euo pipefail
cd "$(dirname "$0")"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"
PACKS=(furniture-kit toon-characters interface-sounds impact-sounds rpg-audio)
JAR=$(mktemp)
trap 'rm -f "$JAR"' EXIT
mkdir -p kenney
for s in "${PACKS[@]}"; do
	[ -d "kenney/$s" ] && continue
	curl -sfL -c "$JAR" -b "$JAR" -A "$UA" -o /dev/null "https://kenney.nl/assets/$s"
	id=$(printf "assets/%s" "$s" | xxd -p | tr -d '\n')
	url=$(curl -sfL -c "$JAR" -b "$JAR" -A "$UA" -e "https://kenney.nl/assets/$s" "https://kenney.nl/download-link/$id" | python3 -c 'import sys,json; print(json.load(sys.stdin)["url"])')
	curl -sfL -b "$JAR" -A "$UA" -o "kenney/$s.zip" "$url"
	# 압축을 다 푼 뒤에만 이름을 바꿔, 실패한 팩이 다음 실행에서 캐시로 남지 않게 한다.
	rm -rf "kenney/$s.part"
	unzip -q "kenney/$s.zip" -d "kenney/$s.part"
	mv "kenney/$s.part" "kenney/$s"
	rm "kenney/$s.zip"
done
mkdir -p models
cp -r "kenney/furniture-kit/Models/GLTF format/." models/
