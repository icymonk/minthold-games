#!/usr/bin/env bash
# 상품 3D 모델을 PNG로 굽고, 카드 틀·UI·아이콘·효과음을 게임 assets/로 복사한다.
# 화면이 있는 환경(DISPLAY)에서 실행한다: bash tools/art_bake/bake.sh
set -euo pipefail
cd "$(dirname "$0")"
bash fetch.sh
GODOT=${GODOT_BIN:-godot}
ART=../../assets/art
SFX=../../assets/sfx
K=kenney
mkdir -p "$ART/products" "$ART/kenney" "$SFX"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --rendering-method gl_compatibility --rendering-driver opengl3 --path . -s bake.gd -- "$(realpath $ART/products)"

cp "$K/cursor-pack/Vector/Outline/hand_point_n.svg" "$ART/kenney/hand.svg"
GI="$K/game-icons/PNG/White/2x"
for i in home:home return:retry arrowRight:next shoppingCart:checkout trashcan:discard audioOn:sound_on audioOff:sound_off question:help gear:settings star:flyer; do
	cp "$GI/${i%%:*}.png" "$ART/kenney/icon_${i##*:}.png"
done

CA="$K/casino-audio/Audio"
IF="$K/interface-sounds/Audio"
cp "$CA/card-slide-1.ogg" "$SFX/pick.ogg"
cp "$CA/card-place-1.ogg" "$SFX/place.ogg"
cp "$CA/card-shuffle.ogg" "$SFX/shuffle.ogg"
cp "$CA/card-fan-1.ogg" "$SFX/deal.ogg"
cp "$CA/chips-stack-1.ogg" "$SFX/cash.ogg"
cp "$IF/bong_001.ogg" "$SFX/scan.ogg"
cp "$IF/click_002.ogg" "$SFX/click.ogg"
cp "$IF/error_006.ogg" "$SFX/error.ogg"
cp "$IF/confirmation_002.ogg" "$SFX/chime.ogg"
cp "$K/food-kit/License.txt" "$ART/kenney/LICENSE-Kenney.txt"
echo "baked"
