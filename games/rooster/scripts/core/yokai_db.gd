class_name YokaiDb
extends RefCounted
## 요괴·적 기본 데이터. 칸 모양(cells)은 왼쪽 위가 (0, 0)인 상대 좌표.
## belly: 변신까지 먹어야 하는 요괴 수. evolve: 배가 차면 바뀌는 FORMS 키.

const ALLIES := {
	&"dokkaebi": {
		"tier": 1, "atk": 2, "hp": 5, "interval": 1.5, "trait": &"coin", "belly": 2, "evolve": &"dokkaebi_chief",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
	},
	&"foxfire": {
		"tier": 1, "atk": 2, "hp": 3, "interval": 1.0, "trait": &"charm", "belly": 1, "evolve": &"gumiho",
		"cells": [Vector2i(0, 0)],
	},
	&"mulgwisin": {
		"tier": 1, "atk": 2, "hp": 4, "interval": 1.8, "trait": &"bind", "belly": 2, "evolve": &"imugi",
		"cells": [Vector2i(0, 0), Vector2i(0, 1)],
	},
	&"haetae": {
		"tier": 1, "atk": 1, "hp": 9, "interval": 2.0, "trait": &"guard", "belly": 3, "evolve": &"sinsu_haetae",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	},
	&"mongdal": {
		"tier": 1, "atk": 3, "hp": 3, "interval": 1.5, "trait": &"rage", "belly": 2, "evolve": &"wongwi",
		"cells": [Vector2i(0, 0), Vector2i(1, 0)],
	},
	&"bulgasari": {
		"tier": 1, "atk": 1, "hp": 5, "interval": 2.0, "trait": &"devour", "belly": 3, "evolve": &"great_bulgasari",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	},
}

## 변신한 모습. atk/hp는 변신할 때 더하는 값이고, interval은 새 공격 간격이다.
const FORMS := {
	&"dokkaebi_chief": {
		"base": &"dokkaebi", "atk": 1, "hp": 3, "interval": 1.4,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
	},
	&"gumiho": {
		"base": &"foxfire", "atk": 1, "hp": 2, "interval": 0.9,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
	},
	&"imugi": {
		"base": &"mulgwisin", "atk": 1, "hp": 3, "interval": 1.7,
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)],
	},
	&"sinsu_haetae": {
		"base": &"haetae", "atk": 1, "hp": 6, "interval": 2.0,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	},
	&"wongwi": {
		"base": &"mongdal", "atk": 2, "hp": 1, "interval": 1.4,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	},
	&"great_bulgasari": {
		"base": &"bulgasari", "atk": 1, "hp": 5, "interval": 2.0,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
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

static var _textures := {}


static func ally_kinds() -> Array[StringName]:
	var kinds: Array[StringName] = []
	kinds.assign(ALLIES.keys())
	return kinds


static func cost(kind: StringName) -> int:
	return COST_BY_TIER[ALLIES[kind]["tier"]]


static func is_ally(kind: StringName) -> bool:
	return ALLIES.has(kind) or FORMS.has(kind)


static func texture(kind: StringName) -> Texture2D:
	if FORMS.has(kind):
		kind = FORMS[kind]["base"]
	if not _textures.has(kind):
		var dir := "yokai" if ALLIES.has(kind) else "enemies"
		_textures[kind] = load("res://assets/%s/%s.png" % [dir, kind])
	return _textures[kind]
