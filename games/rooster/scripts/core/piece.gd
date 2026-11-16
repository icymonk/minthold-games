class_name Piece
extends RefCounted
## 보따리에 들어가는 요괴 한 마리. 먹기로 칸 모양과 특성이 늘어난다.

const MAX_TRAITS := 3

static var _next_id := 1

var id: int
var kind: StringName
var cells: Array[Vector2i] = []
var pos := Vector2i.ZERO
var atk: int
var hp: int
var interval: float
var traits: Array[StringName] = []
var eaten := 0


static func create(kind: StringName) -> Piece:
	var def: Dictionary = YokaiDb.ALLIES[kind]
	var p := Piece.new()
	p.id = _next_id
	_next_id += 1
	p.kind = kind
	p.cells.assign(def["cells"])
	p.atk = def["atk"]
	p.hp = def["hp"]
	p.interval = def["interval"]
	p.traits.append(def["trait"])
	return p


func world_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in cells:
		out.append(c + pos)
	return out


func size() -> Vector2i:
	var s := Vector2i.ZERO
	for c in cells:
		s = Vector2i(maxi(s.x, c.x + 1), maxi(s.y, c.y + 1))
	return s


## 시계 방향 90도. 회전 후 왼쪽 위를 (0, 0)으로 다시 맞춘다.
func rotate_cw() -> void:
	var rotated: Array[Vector2i] = []
	for c in cells:
		rotated.append(Vector2i(-c.y, c.x))
	cells = normalized(rotated)


static func normalized(raw: Array[Vector2i]) -> Array[Vector2i]:
	var lo := Vector2i(1 << 20, 1 << 20)
	for c in raw:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
	var out: Array[Vector2i] = []
	for c in raw:
		out.append(c - lo)
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return out


func has_trait(t: StringName) -> bool:
	return t in traits
