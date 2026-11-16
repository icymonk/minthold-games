#!/usr/bin/env bash
# 3D 모델을 찍어 PNG로 굽고, 2D 그림·효과음을 게임 assets/로 복사한다.
# 화면이 있는 환경(DISPLAY)에서 실행한다: bash tools/art_bake/bake.sh
set -euo pipefail
cd "$(dirname "$0")"
bash fetch.sh
GODOT=${GODOT_BIN:-godot}
ART=../../assets/art
SFX=../../assets/sfx
K=kenney
mkdir -p "$ART/kenney" "$SFX"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --rendering-driver opengl3 --path . -s bake.gd -- "$(realpath $ART)"

IND="$K/platformer-pack-industrial/PNG/Default size/platformIndustrial"
BG="$K/background-elements-remastered/PNG/Retina"
UI="$K/ui-pack/PNG"
cp "${IND}_063.png" "$ART/kenney/hazard.png"
cp "${IND}_049.png" "$ART/kenney/belt.png"
cp "${IND}_067.png" "$ART/kenney/gear.png"
cp "${IND}_054.png" "$ART/kenney/beacon.png"
cp "${IND}_043.png" "$ART/kenney/crate.png"
cp "${IND}_090.png" "$ART/kenney/barrel_blue.png"
cp "${IND}_092.png" "$ART/kenney/barrel_yellow.png"
for h in house1 house2 houseAlt1 houseAlt2 houseSmall1 houseSmallAlt1 cloud1 cloud3 moon; do cp "$BG/$h.png" "$ART/kenney/$h.png"; done
cp "$UI/Grey/Default/button_rectangle_depth_gradient.png" "$ART/kenney/button.png"
cp "$UI/Grey/Default/button_rectangle_depth_flat.png" "$ART/kenney/button_pressed.png"
cp "$UI/Yellow/Default/button_rectangle_depth_gradient.png" "$ART/kenney/button_accent.png"
cp "$UI/Grey/Default/button_square_flat.png" "$ART/kenney/panel.png"
cp "$K/cursor-pack/Vector/Outline/hand_point_n.svg" "$ART/kenney/hand.svg"

IMP="$K/impact-sounds/Audio"
IF="$K/interface-sounds/Audio"
cp "$IMP/impactSoft_heavy_001.ogg" "$SFX/thud.ogg"
cp "$IF/select_002.ogg" "$SFX/pick.ogg"
cp "$IMP/impactWood_light_002.ogg" "$SFX/slide.ogg"
cp "$IF/error_006.ogg" "$SFX/error.ogg"
cp "$IF/switch_002.ogg" "$SFX/rotate.ogg"
cp "$IF/confirmation_002.ogg" "$SFX/chime.ogg"
cp "$K/car-kit/License.txt" "$ART/kenney/LICENSE-Kenney.txt"
echo "baked"
