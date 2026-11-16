class_name Bag
extends RefCounted
## 보따리 격자. 오른쪽이 앞(행렬이 오는 쪽), 각 줄(y)이 행렬의 길 하나다.

var width: int
var height: int
var pieces: Array[Piece] = []


func _init(w: int, h: int) -> void:
	width = w
	height = h


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


func piece_at(c: Vector2i) -> Piece:
	for p in pieces:
		if c in p.world_cells():
			return p
	return null


func can_place(p: Piece, at: Vector2i) -> bool:
	for c in p.cells:
		var w := c + at
		if not in_bounds(w):
			return false
		var other := piece_at(w)
		if other != null and other != p:
			return false
	return true


func place(p: Piece, at: Vector2i) -> bool:
	if not can_place(p, at):
		return false
	p.pos = at
	if p not in pieces:
		pieces.append(p)
	return true


func remove(p: Piece) -> void:
	pieces.erase(p)


func touching(a: Piece, b: Piece) -> bool:
	if a == b:
		return false
	var bc := b.world_cells()
	for c in a.world_cells():
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if c + d in bc:
				return true
	return false


func neighbors(p: Piece) -> Array[Piece]:
	var out: Array[Piece] = []
	for o in pieces:
		if touching(p, o):
			out.append(o)
	return out


## eater가 food를 먹는다. 둘이 맞닿아 있어야 하고, 칸 모양은 지금 놓인 그대로 합쳐진다.
func merge(eater: Piece, food: Piece) -> bool:
	if eater not in pieces or food not in pieces or not touching(eater, food):
		return false
	var union: Array[Vector2i] = eater.world_cells()
	union.append_array(food.world_cells())
	var lo := Vector2i(width, height)
	for c in union:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
	eater.pos = lo
	eater.cells = Piece.normalized(union)
	eater.atk += ceili(food.atk / 2.0)
	eater.hp += ceili(food.hp / 2.0)
	for t in food.traits:
		if eater.traits.size() < Piece.MAX_TRAITS and not eater.has_trait(t):
			eater.traits.append(t)
	eater.eaten += 1 + food.eaten
	pieces.erase(food)
	return true
