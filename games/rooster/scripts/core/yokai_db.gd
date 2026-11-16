class_name YokaiDb
extends RefCounted
## 요괴·적 기본 데이터. 칸 모양(cells)은 왼쪽 위가 (0, 0)인 상대 좌표.
## family: 계열(시너지), tier: 등급(값·등장 밤), trait: 고유 능력.
## belly: 변신까지 먹어야 하는 요괴 수. evolve: 배가 차면 바뀌는 FORMS 키.

const FAMILIES: Array[StringName] = [&"fire", &"water", &"grudge", &"metal", &"divine", &"mountain"]

const ALLIES := {
	&"foxfire": {
		"family": &"fire", "tier": 1, "atk": 2, "hp": 3, "interval": 1.0, "trait": &"charm", "belly": 1, "evolve": &"gumiho",
		"cells": [Vector2i(0, 0)],
	},
	&"bulgae": {
		"family": &"fire", "tier": 1, "atk": 2, "hp": 4, "interval": 1.3, "trait": &"burn", "belly": 2, "evolve": &"sun_bulgae",
		"cells": [Vector2i(0, 0), Vector2i(1, 0)],
	},
	&"hwadeok": {
		"family": &"fire", "tier": 2, "atk": 1, "hp": 8, "interval": 2.0, "trait": &"hearth", "belly": 3, "evolve": &"jowang",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	},
	&"gangcheori": {
		"family": &"fire", "tier": 3, "atk": 3, "hp": 7, "interval": 1.8, "trait": &"drought", "belly": 3, "evolve": &"great_gangcheori",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
	},
	&"mulgwisin": {
		"family": &"water", "tier": 1, "atk": 2, "hp": 4, "interval": 1.8, "trait": &"bind", "belly": 2, "evolve": &"imugi",
		"cells": [Vector2i(0, 0), Vector2i(0, 1)],
	},
	&"ureong": {
		"family": &"water", "tier": 1, "atk": 1, "hp": 4, "interval": 1.4, "trait": &"spring", "belly": 1, "evolve": &"seonnyeo",
		"cells": [Vector2i(0, 0)],
	},
	&"cheonyeo": {
		"family": &"water", "tier": 2, "atk": 3, "hp": 4, "interval": 1.5, "trait": &"sorrow", "belly": 2, "evolve": &"wraith_maiden",
		"cells": [Vector2i(0, 0), Vector2i(0, 1)],
	},
	&"yongwang": {
		"family": &"water", "tier": 3, "atk": 2, "hp": 10, "interval": 2.0, "trait": &"tide", "belly": 3, "evolve": &"sahae_yongwang",
		"cells": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
	},
	&"mongdal": {
		"family": &"grudge", "tier": 1, "atk": 3, "hp": 3, "interval": 1.5, "trait": &"rage", "belly": 2, "evolve": &"wongwi",
		"cells": [Vector2i(0, 0), Vector2i(1, 0)],
	},
	&"dalgyal": {
		"family": &"grudge", "tier": 1, "atk": 2, "hp": 2, "interval": 1.2, "trait": &"curse", "belly": 1, "evolve": &"great_dalgyal",
		"cells": [Vector2i(0, 0)],
	},
	&"yagwang": {
		"family": &"grudge", "tier": 2, "atk": 2, "hp": 4, "interval": 1.2, "trait": &"steal", "belly": 2, "evolve": &"yagwang_king",
		"cells": [Vector2i(0, 0), Vector2i(1, 0)],
	},
	&"mudu": {
		"family": &"grudge", "tier": 2, "atk": 3, "hp": 6, "interval": 1.6, "trait": &"undying", "belly": 3, "evolve": &"mudu_general",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)],
	},
	&"dokkaebi": {
		"family": &"metal", "tier": 1, "atk": 2, "hp": 5, "interval": 1.5, "trait": &"coin", "belly": 2, "evolve": &"dokkaebi_chief",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
	},
	&"bulgasari": {
		"family": &"metal", "tier": 1, "atk": 1, "hp": 5, "interval": 2.0, "trait": &"devour", "belly": 3, "evolve": &"great_bulgasari",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	},
	&"geumdwaeji": {
		"family": &"metal", "tier": 2, "atk": 1, "hp": 6, "interval": 1.8, "trait": &"hoard", "belly": 2, "evolve": &"golden_boar",
		"cells": [Vector2i(0, 0), Vector2i(1, 0)],
	},
	&"dueoksini": {
		"family": &"metal", "tier": 3, "atk": 4, "hp": 10, "interval": 2.0, "trait": &"cleave", "belly": 3, "evolve": &"dueoksini_king",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	},
	&"haetae": {
		"family": &"divine", "tier": 1, "atk": 1, "hp": 9, "interval": 2.0, "trait": &"guard", "belly": 3, "evolve": &"sinsu_haetae",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	},
	&"teoju": {
		"family": &"divine", "tier": 1, "atk": 1, "hp": 5, "interval": 2.0, "trait": &"ward", "belly": 1, "evolve": &"seongju",
		"cells": [Vector2i(0, 0)],
	},
	&"samjokgu": {
		"family": &"divine", "tier": 2, "atk": 3, "hp": 5, "interval": 1.2, "trait": &"hunt", "belly": 2, "evolve": &"heaven_dog",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
	},
	&"bonghwang": {
		"family": &"divine", "tier": 3, "atk": 3, "hp": 7, "interval": 1.6, "trait": &"rebirth", "belly": 3, "evolve": &"ohsaek_bonghwang",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
	},
	&"eodukssini": {
		"family": &"mountain", "tier": 1, "atk": 1, "hp": 4, "interval": 1.3, "trait": &"grow", "belly": 1, "evolve": &"great_eodukssini",
		"cells": [Vector2i(0, 0)],
	},
	&"geuseundae": {
		"family": &"mountain", "tier": 2, "atk": 2, "hp": 6, "interval": 1.7, "trait": &"dread", "belly": 2, "evolve": &"great_geuseundae",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
	},
	&"jangsanbeom": {
		"family": &"mountain", "tier": 2, "atk": 3, "hp": 5, "interval": 1.4, "trait": &"mimic", "belly": 2, "evolve": &"baekho",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
	},
	&"samdugumi": {
		"family": &"mountain", "tier": 3, "atk": 3, "hp": 8, "interval": 1.6, "trait": &"triple", "belly": 3, "evolve": &"gumi_king",
		"cells": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	},
}

## 변신한 모습. atk/hp는 변신할 때 더하는 값이고, interval은 새 공격 간격이다.
const FORMS := {
	&"gumiho": {
		"base": &"foxfire", "atk": 1, "hp": 2, "interval": 0.9,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
	},
	&"sun_bulgae": {
		"base": &"bulgae", "atk": 1, "hp": 3, "interval": 1.2,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	},
	&"jowang": {
		"base": &"hwadeok", "atk": 1, "hp": 5, "interval": 1.9,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	},
	&"great_gangcheori": {
		"base": &"gangcheori", "atk": 2, "hp": 4, "interval": 1.7,
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)],
	},
	&"imugi": {
		"base": &"mulgwisin", "atk": 1, "hp": 3, "interval": 1.7,
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)],
	},
	&"seonnyeo": {
		"base": &"ureong", "atk": 1, "hp": 3, "interval": 1.3,
		"cells": [Vector2i(0, 0), Vector2i(0, 1)],
	},
	&"wraith_maiden": {
		"base": &"cheonyeo", "atk": 2, "hp": 2, "interval": 1.4,
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
	},
	&"sahae_yongwang": {
		"base": &"yongwang", "atk": 1, "hp": 6, "interval": 1.9,
		"cells": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	},
	&"wongwi": {
		"base": &"mongdal", "atk": 2, "hp": 1, "interval": 1.4,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	},
	&"great_dalgyal": {
		"base": &"dalgyal", "atk": 1, "hp": 3, "interval": 1.2,
		"cells": [Vector2i(0, 0), Vector2i(1, 0)],
	},
	&"yagwang_king": {
		"base": &"yagwang", "atk": 1, "hp": 3, "interval": 1.1,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
	},
	&"mudu_general": {
		"base": &"mudu", "atk": 2, "hp": 4, "interval": 1.5,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)],
	},
	&"dokkaebi_chief": {
		"base": &"dokkaebi", "atk": 1, "hp": 3, "interval": 1.4,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
	},
	&"great_bulgasari": {
		"base": &"bulgasari", "atk": 1, "hp": 5, "interval": 2.0,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
	},
	&"golden_boar": {
		"base": &"geumdwaeji", "atk": 2, "hp": 5, "interval": 1.7,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)],
	},
	&"dueoksini_king": {
		"base": &"dueoksini", "atk": 2, "hp": 5, "interval": 1.9,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
	},
	&"sinsu_haetae": {
		"base": &"haetae", "atk": 1, "hp": 6, "interval": 2.0,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	},
	&"seongju": {
		"base": &"teoju", "atk": 1, "hp": 4, "interval": 1.8,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
	},
	&"heaven_dog": {
		"base": &"samjokgu", "atk": 2, "hp": 3, "interval": 1.1,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)],
	},
	&"ohsaek_bonghwang": {
		"base": &"bonghwang", "atk": 2, "hp": 4, "interval": 1.5,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)],
	},
	&"great_eodukssini": {
		"base": &"eodukssini", "atk": 1, "hp": 3, "interval": 1.2,
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
	},
	&"great_geuseundae": {
		"base": &"geuseundae", "atk": 2, "hp": 3, "interval": 1.6,
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)],
	},
	&"baekho": {
		"base": &"jangsanbeom", "atk": 2, "hp": 4, "interval": 1.3,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	},
	&"gumi_king": {
		"base": &"samdugumi", "atk": 2, "hp": 4, "interval": 1.5,
		"cells": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
	},
}

const ENEMIES := {
	&"field_ghost": {"atk": 1, "hp": 4, "interval": 1.5},
	&"ghost_fire": {"atk": 1, "hp": 3, "interval": 1.0},
	&"shade": {"atk": 2, "hp": 6, "interval": 1.6},
	&"ox_brute": {"atk": 3, "hp": 12, "interval": 2.2},
	&"reaper": {"atk": 3, "hp": 26, "interval": 2.0},
	&"leader": {"atk": 5, "hp": 48, "interval": 2.0},
}

const COST_BY_TIER := [0, 3, 4, 5]
## 등급별로 장터에 처음 나오는 밤.
const TIER_NIGHT := [0, 1, 2, 4]

static var _textures := {}


static func ally_kinds() -> Array[StringName]:
	var kinds: Array[StringName] = []
	kinds.assign(ALLIES.keys())
	return kinds


## 이 밤 장터에 나올 수 있는 요괴. 같은 등급이 여러 번 들어가 낮은 등급이 더 자주 나온다.
static func market_pool(night: int) -> Array[StringName]:
	var pool: Array[StringName] = []
	for kind in ALLIES:
		var tier: int = ALLIES[kind]["tier"]
		if night < TIER_NIGHT[tier]:
			continue
		for i in 4 - tier:
			pool.append(kind)
	return pool


static func base_of(kind: StringName) -> StringName:
	return FORMS[kind]["base"] if FORMS.has(kind) else kind


static func family(kind: StringName) -> StringName:
	return ALLIES[base_of(kind)]["family"]


static func tier(kind: StringName) -> int:
	return ALLIES[base_of(kind)]["tier"]


static func cost(kind: StringName) -> int:
	return COST_BY_TIER[ALLIES[kind]["tier"]]


static func is_ally(kind: StringName) -> bool:
	return ALLIES.has(kind) or FORMS.has(kind)


## 칸 모양에 맞춰 그린 그림. 변신 형태도 자기 그림이 있다.
static func texture(kind: StringName) -> Texture2D:
	if not _textures.has(kind):
		var dir := "yokai" if is_ally(kind) else "enemies"
		_textures[kind] = load("res://assets/%s/%s.png" % [dir, kind])
	return _textures[kind]


## 카드·정보 패널용 정사각 그림. 변신 형태는 모양 그림을 그대로 쓴다.
static func icon(kind: StringName) -> Texture2D:
	if not ALLIES.has(kind):
		return texture(kind)
	var key := StringName("icon_" + kind)
	if not _textures.has(key):
		var path := "res://assets/yokai/icons/%s.png" % kind
		_textures[key] = load(path) if ResourceLoader.exists(path) else texture(kind)
	return _textures[key]


## 그림이 그려진 기준(회전 전) 모양.
static func base_cells(kind: StringName) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign((ALLIES[kind] if ALLIES.has(kind) else FORMS[kind])["cells"])
	return out
