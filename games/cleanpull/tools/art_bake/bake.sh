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
"$GODOT" --rendering-method gl_compatibility --rendering-driver opengl3 --path . -s bake.gd -- "$(realpath $ART)"

UI="$K/ui-pack/PNG"
cp "$UI/Grey/Default/button_rectangle_depth_gradient.png" "$ART/kenney/button.png"
cp "$UI/Grey/Default/button_rectangle_depth_flat.png" "$ART/kenney/button_pressed.png"
cp "$UI/Yellow/Default/button_rectangle_depth_gradient.png" "$ART/kenney/button_accent.png"
cp "$UI/Grey/Default/button_square_flat.png" "$ART/kenney/panel.png"
cp "$K/cursor-pack/Vector/Outline/hand_point_n.svg" "$ART/kenney/hand.svg"
GI="$K/game-icons/PNG/White/2x"
cp "$GI/home.png" "$ART/kenney/icon_home.png"
cp "$GI/return.png" "$ART/kenney/icon_retry.png"
cp "$GI/arrowRight.png" "$ART/kenney/icon_next.png"
cp "$GI/fastForward.png" "$ART/kenney/icon_fast.png"

IMP="$K/impact-sounds/Audio"
IF="$K/interface-sounds/Audio"
cp "$IMP/impactGlass_heavy_002.ogg" "$SFX/glass_break.ogg"
cp "$IMP/impactGlass_light_001.ogg" "$SFX/glass_clink.ogg"
cp "$IMP/impactPlate_heavy_001.ogg" "$SFX/plate_break.ogg"
cp "$IMP/impactPlate_light_002.ogg" "$SFX/plate_clink.ogg"
cp "$IMP/impactSoft_heavy_001.ogg" "$SFX/thud.ogg"
cp "$IMP/impactWood_heavy_001.ogg" "$SFX/table_knock.ogg"
cp "$IF/select_002.ogg" "$SFX/pick.ogg"
cp "$IF/drop_002.ogg" "$SFX/place.ogg"
cp "$IF/error_006.ogg" "$SFX/error.ogg"
cp "$IF/confirmation_002.ogg" "$SFX/chime.ogg"
cp "$IF/maximize_006.ogg" "$SFX/whoosh.ogg"
cp "$K/food-kit/License.txt" "$ART/kenney/LICENSE-Kenney.txt"
echo "baked"
