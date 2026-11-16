class_name Box
extends RefCounted
## 짐칸에 싣는 상자 하나. 칸 좌표는 왼쪽 아래 (0,0) 기준, y는 위로 갈수록 커진다.

enum Trait { FRAGILE, HEAVY, FROZEN, UPRIGHT }

const SHAPES := {
	&"1x1": [Vector2i(0, 0)],
	&"2x1": [Vector2i(0, 0), Vector2i(1, 0)],
	&"3x1": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	&"1x2": [Vector2i(0, 0), Vector2i(0, 1)],
	&"2x2": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	&"L": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
	&"J": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
	&"T": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
}

var id: int
var shape: StringName
var stop: int
var traits: Array[Trait] = []
var cells: Array[Vector2i] = []
var broken := false


func _init(box_id: int, box_shape: StringName, box_stop: int, box_traits: Array[Trait] = []) -> void:
	id = box_id
	shape = box_shape
	stop = box_stop
	traits = box_traits
	cells.assign(SHAPES[box_shape])


func has(t: Trait) -> bool:
	return t in traits


func can_rotate() -> bool:
	return not has(Trait.UPRIGHT)


## 시계 방향 90도. "이쪽이 위로" 상자는 그대로 둔다.
func rotate() -> bool:
	if not can_rotate():
		return false
	var turned: Array[Vector2i] = []
	for c in cells:
		turned.append(Vector2i(c.y, -c.x))
	cells = _normalized(turned)
	return true


func size() -> Vector2i:
	var s := Vector2i.ZERO
	for c in cells:
		s = Vector2i(maxi(s.x, c.x + 1), maxi(s.y, c.y + 1))
	return s


func copy() -> Box:
	var b := Box.new(id, shape, stop, traits.duplicate())
	b.cells = cells.duplicate()
	b.broken = broken
	return b


static func _normalized(list: Array[Vector2i]) -> Array[Vector2i]:
	var lo := Vector2i(1 << 20, 1 << 20)
	for c in list:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
	var out: Array[Vector2i] = []
	for c in list:
		out.append(c - lo)
	return out
