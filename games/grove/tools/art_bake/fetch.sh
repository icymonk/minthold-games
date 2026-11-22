#!/usr/bin/env bash
# Quaternius Stylized Nature MegaKit(CC0)을 quaternius/ 아래로 받고, 쓰는 모델만 assets/models/nature/로 옮긴다.
# 웹 용량을 줄이려고 노멀맵은 빼고 텍스처는 512px로 줄인다.
set -euo pipefail
cd "$(dirname "$0")"
if [ ! -d quaternius/mk ]; then
	rm -rf quaternius && mkdir -p quaternius
	bash itch.sh https://quaternius.itch.io/stylized-nature-megakit quaternius
	unzip -q quaternius/*.zip -d quaternius/mk.part && mv quaternius/mk.part quaternius/mk
fi
python3 - <<'PY'
import json, os, shutil
from PIL import Image
SRC = "quaternius/mk/glTF"
DST = "../../assets/models/nature"
MODELS = [
	"CommonTree_1", "CommonTree_2", "CommonTree_3", "CommonTree_4", "CommonTree_5",
	"Pine_1", "Pine_2", "Pine_3", "Pine_4", "Pine_5", "TwistedTree_1", "TwistedTree_3",
	"Grass_Common_Short", "Grass_Common_Tall", "Grass_Wispy_Short", "Grass_Wispy_Tall",
	"Flower_3_Group", "Flower_4_Group", "Bush_Common", "Bush_Common_Flowers", "Fern_1",
	"Clover_1", "Plant_1", "Mushroom_Common", "Mushroom_Laetiporus",
	"Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3", "Pebble_Round_1", "Pebble_Round_2", "Pebble_Round_3",
]
os.makedirs(DST, exist_ok=True)
images = set()
for m in MODELS:
	g = json.load(open(f"{SRC}/{m}.gltf"))
	for mat in g.get("materials", []):
		mat.pop("normalTexture", None)
	used = {mat["pbrMetallicRoughness"]["baseColorTexture"]["index"]
		for mat in g["materials"] if "baseColorTexture" in mat.get("pbrMetallicRoughness", {})}
	remap, textures = {}, []
	for i, t in enumerate(g.get("textures", [])):
		if i in used:
			remap[i] = len(textures)
			textures.append(t)
	for mat in g["materials"]:
		tex = mat.get("pbrMetallicRoughness", {}).get("baseColorTexture")
		if tex:
			tex["index"] = remap[tex["index"]]
	src_imgs = g.get("images", [])
	keep = sorted({t["source"] for t in textures})
	g["images"] = [src_imgs[i] for i in keep]
	for t in textures:
		t["source"] = keep.index(t["source"])
	g["textures"] = textures
	if not g["images"]:
		for k in ("images", "textures", "samplers"):
			g.pop(k, None)
	images.update(i["uri"] for i in g.get("images", []))
	json.dump(g, open(f"{DST}/{m}.gltf", "w"), indent=1)
	shutil.copy(f"{SRC}/{m}.bin", DST)
for uri in images:
	im = Image.open(f"{SRC}/{uri}")
	if max(im.size) > 512:
		im = im.resize((512, 512), Image.LANCZOS)
	im.save(f"{DST}/{uri}", optimize=True)
cp = "quaternius/mk/License_Standard.txt"
shutil.copy(cp, f"{DST}/LICENSE-Quaternius.txt")
print(len(MODELS), "models,", len(images), "textures ->", DST)
PY
