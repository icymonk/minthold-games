#!/usr/bin/env bash
# Gobkit Free Animal Pack(CC0) 네 묶음을 gobkit/ 아래로 받고, 쓰는 동물만 assets/models/animals/로 옮긴다.
set -euo pipefail
cd "$(dirname "$0")"
PACKS="gobkit-free-animal-pack gobkit-free-animal-pack-vol-2 gobkit-free-animal-pack-vol-5 gobkit-free-animal-pack-vol-8"
for p in $PACKS; do
	if [ ! -d "gobkit/$p/x" ]; then
		rm -rf "gobkit/$p" && mkdir -p "gobkit/$p"
		bash itch.sh "https://gobkit.itch.io/$p" "gobkit/$p"
		unzip -q "gobkit/$p"/*.zip -d "gobkit/$p/x"
	fi
done
DST=../../assets/models/animals
mkdir -p "$DST"
for m in Owl GouldianFinch Bat Bee Mole Axolotl Dingo Goat Boar Bunnykit Marmot; do
	cp "$(find gobkit -name "$m.glb" | head -1)" "$DST/"
done
cp gobkit/gobkit-free-animal-pack/x/LICENSE.txt "$DST/LICENSE-Gobkit.txt"
echo "$(ls "$DST"/*.glb | wc -l) animals -> $DST"
