#!/usr/bin/env bash
# 가구 3D 모델을 구역 그림으로 굽고, 인물 그림·효과음을 게임 assets/로 복사한다.
# 화면이 있는 환경(DISPLAY)에서 실행한다: bash tools/art_bake/bake.sh
set -euo pipefail
cd "$(dirname "$0")"
bash fetch.sh
GODOT=${GODOT_BIN:-godot}
ART=../../assets/art
SFX=../../assets/sfx
K=kenney
mkdir -p "$ART/people" "$SFX"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --rendering-driver opengl3 --path . -s bake.gd -- "$(realpath $ART)"

# 사원은 남자("자리를 비운 그"), 팀장은 여자 인물(Toon Characters)이다.
M="$K/toon-characters/Male person/PNG/Poses HD/character_malePerson"
F="$K/toon-characters/Female person/PNG/Poses HD/character_femalePerson"
for p in idle run0 run1 cheer0 hurt interact; do cp "${M}_$p.png" "$ART/people/staff_$p.png"; done
for p in idle think talk cheer0 hurt; do cp "${F}_$p.png" "$ART/people/chief_$p.png"; done

IF="$K/interface-sounds/Audio"
IMP="$K/impact-sounds/Audio"
RPG="$K/rpg-audio/Audio"
cp "$IF/tick_002.ogg" "$SFX/tick.ogg"
cp "$RPG/bookPlace1.ogg" "$SFX/place.ogg"
cp "$RPG/bookFlip2.ogg" "$SFX/draw.ogg"
cp "$RPG/bookFlip1.ogg" "$SFX/flip.ogg"
cp "$IMP/footstep_carpet_001.ogg" "$SFX/step.ogg"
cp "$IF/bong_001.ogg" "$SFX/ping.ogg"
cp "$IF/error_004.ogg" "$SFX/miss.ogg"
cp "$IMP/impactPunch_heavy_000.ogg" "$SFX/stamp.ogg"
cp "$K/furniture-kit/License.txt" "$ART/LICENSE-Kenney.txt"
echo "baked"
