class_name YokaiDb
extends RefCounted
## 요괴·적 기본 데이터. 칸 모양(cells)은 왼쪽 위가 (0, 0)인 상대 좌표.

const ALLIES := {
	&"dokkaebi": {
		"tier": 1, "atk": 2, "hp": 5, "interval": 1.5, "trait": &"coin",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
	},
	&"foxfire": {
		"tier": 1, "atk": 2, "hp": 3, "interval": 1.0, "trait": &"charm",
		"cells": [Vector2i(0, 0)],
	},
	&"mulgwisin": {
		"tier": 1, "atk": 2, "hp": 4, "interval": 1.8, "trait": &"bind",
		"cells": [Vector2i(0, 0), Vector2i(0, 1)],
	},
	&"haetae": {
		"tier": 1, "atk": 1, "hp": 9, "interval": 2.0, "trait": &"guard",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	},
	&"mongdal": {
		"tier": 1, "atk": 3, "hp": 3, "interval": 1.5, "trait": &"rage",
		"cells": [Vector2i(0, 0), Vector2i(1, 0)],
	},
	&"bulgasari": {
		"tier": 1, "atk": 1, "hp": 5, "interval": 2.0, "trait": &"devour",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
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


static func texture(kind: StringName) -> Texture2D:
	if not _textures.has(kind):
		var dir := "yokai" if ALLIES.has(kind) else "enemies"
		_textures[kind] = load("res://assets/%s/%s.png" % [dir, kind])
	return _textures[kind]
