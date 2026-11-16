class_name Plot
extends RefCounted
## 밤을 넘길 때 보따리 가장자리에 붙이는 조각. 1~3칸이고, 칸이 적을수록 특수 칸이 붙기 쉽다.

const SPECIALS: Array[StringName] = [&"well", &"hearth"]
const SHAPES := {
	1: [[Vector2i(0, 0)]],
	2: [[Vector2i(0, 0), Vector2i(1, 0)]],
	3: [[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]],
}
const SPECIAL_CHANCE := {1: 1.0, 2: 0.5, 3: 0.0}

var cells: Array[Vector2i] = []
## 조각 안 좌표 → 특수 칸 종류.
var special := {}


static func roll(n: int, rng: RandomNumberGenerator) -> Plot:
	var p := Plot.new()
	var shapes: Array = SHAPES[n]
	p.cells.assign(shapes[rng.randi_range(0, shapes.size() - 1)])
	if rng.randf() < SPECIAL_CHANCE[n]:
		p.special[p.cells[rng.randi_range(0, n - 1)]] = SPECIALS[rng.randi_range(0, SPECIALS.size() - 1)]
	return p


## 밤마다 고를 조각 세 개: 1칸(특수 칸), 2칸, 3칸.
static func offers(rng: RandomNumberGenerator) -> Array[Plot]:
	var out: Array[Plot] = []
	for n in [1, 2, 3]:
		out.append(roll(n, rng))
	return out


func copy() -> Plot:
	var p := Plot.new()
	p.cells = cells.duplicate()
	p.special = special.duplicate()
	return p


func size() -> Vector2i:
	var hi := Vector2i.ZERO
	for c in cells:
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	return hi + Vector2i.ONE


func rotate_cw() -> void:
	var raw: Array[Vector2i] = []
	for c in cells:
		raw.append(Vector2i(-c.y, c.x))
	var lo := Vector2i(1 << 20, 1 << 20)
	for c in raw:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
	var moved := {}
	for c in special:
		moved[Vector2i(-c.y, c.x) - lo] = special[c]
	cells.clear()
	for c in raw:
		cells.append(c - lo)
	special = moved
