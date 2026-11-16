class_name Bay
extends RefCounted
## 트럭 짐칸을 옆에서 본 단면 격자. x=0은 운전석 쪽 벽, x=width-1 오른쪽이 뒷문, y=0이 바닥.
## 상자는 문에서 밀어 넣고(그 높이의 길이 열려 있어야 함) 중력으로 떨어진다.

enum Fail { OK, OUT_OF_BOUNDS, BLOCKED, NOT_ON_HEAVY, NOT_IN_BAY, COVERED, PATH_BLOCKED, ALREADY_IN_BAY }

var width: int
var height: int
var boxes := {}  # id -> Box
var origins := {}  # id -> Vector2i
var _grid := {}  # Vector2i -> id


func _init(w := 8, h := 4) -> void:
	width = w
	height = h


func box_at(cell: Vector2i) -> Box:
	return boxes.get(_grid.get(cell, -1))


func is_free(cell: Vector2i, ignore_id := -1) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return false
	var owner: int = _grid.get(cell, -1)
	return owner == -1 or owner == ignore_id


## 상자를 origin 높이로 문에서 밀어 넣었을 때 떨어져 멈추는 자리. 못 넣으면 Error를 담아 돌려준다.
## 결과: {error, origin, fall}
func preview(box: Box, origin: Vector2i) -> Dictionary:
	if boxes.has(box.id):
		return {error = Fail.ALREADY_IN_BAY}
	for c in box.cells:
		var p := origin + c
		if p.x < 0 or p.y < 0 or p.x >= width or p.y >= height:
			return {error = Fail.OUT_OF_BOUNDS}
	if not _path_open(box, origin):
		return {error = Fail.BLOCKED}
	var rest := origin
	while _fits(box, rest + Vector2i(0, -1)):
		rest += Vector2i(0, -1)
	if box.has(Box.Trait.HEAVY) and not _on_heavy_or_floor(box, rest):
		return {error = Fail.NOT_ON_HEAVY}
	return {error = Fail.OK, origin = rest, fall = origin.y - rest.y}


## 실은 결과: {error, origin, broken: Array[int]}
func place(box: Box, origin: Vector2i) -> Dictionary:
	var p := preview(box, origin)
	if p.error != Fail.OK:
		return p
	_put(box, p.origin)
	var broken: Array[int] = []
	if box.has(Box.Trait.FRAGILE) and (p.fall > 1 or not _boxes_above(box, p.origin).is_empty()):
		_break(box, broken)
	for below in _boxes_below(box, p.origin):
		if below.has(Box.Trait.FRAGILE):
			_break(below, broken)
	p.broken = broken
	return p


func can_unload(box_id: int) -> Fail:
	if not boxes.has(box_id):
		return Fail.NOT_IN_BAY
	var box: Box = boxes[box_id]
	var o: Vector2i = origins[box_id]
	for c in box.cells:
		var above := o + c + Vector2i(0, 1)
		if above.y < height and not is_free(above, box_id):
			return Fail.COVERED
	if not _path_open(box, o, box_id):
		return Fail.PATH_BLOCKED
	return Fail.OK


## 꺼낸 결과: {error, box, broken: Array[int], moved: Array[int]}
func unload(box_id: int) -> Dictionary:
	var e := can_unload(box_id)
	if e != Fail.OK:
		return {error = e}
	var box: Box = boxes[box_id]
	_remove(box_id)
	var result := settle()
	result.error = Fail.OK
	result.box = box
	return result


## 받침이 없는 상자를 아래로 떨어뜨린다. 결과: {broken, moved}
func settle() -> Dictionary:
	var broken: Array[int] = []
	var moved: Array[int] = []
	var ids := boxes.keys()
	ids.sort_custom(func(a: int, b: int) -> bool: return origins[a].y < origins[b].y)
	for id in ids:
		var box: Box = boxes[id]
		var start: Vector2i = origins[id]
		_remove(id)
		var rest := start
		while _fits(box, rest + Vector2i(0, -1)):
			rest += Vector2i(0, -1)
		_put(box, rest)
		if rest == start:
			continue
		moved.append(id)
		if box.has(Box.Trait.FRAGILE) and start.y - rest.y > 1:
			_break(box, broken)
		for below in _boxes_below(box, rest):
			if below.has(Box.Trait.FRAGILE):
				_break(below, broken)
	return {broken = broken, moved = moved}


func free_cells() -> int:
	return width * height - _grid.size()


func copy() -> Bay:
	var b := Bay.new(width, height)
	for id in boxes:
		b._put(boxes[id].copy(), origins[id])
	return b


func _fits(box: Box, origin: Vector2i, ignore_id := -1) -> bool:
	for c in box.cells:
		if not is_free(origin + c, ignore_id):
			return false
	return true


## origin에서 오른쪽 문 밖까지 상자를 그대로 미는 길이 비어 있는가.
func _path_open(box: Box, origin: Vector2i, ignore_id := -1) -> bool:
	for c in box.cells:
		var p := origin + c
		for x in range(p.x, width):
			if not is_free(Vector2i(x, p.y), ignore_id):
				return false
	return true


func _on_heavy_or_floor(box: Box, origin: Vector2i) -> bool:
	for c in _bottom_cells(box):
		var below := origin + c + Vector2i(0, -1)
		if below.y < 0:
			continue
		var under := box_at(below)
		if under == null or not under.has(Box.Trait.HEAVY):
			return false
	return true


func _bottom_cells(box: Box) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in box.cells:
		if not (c + Vector2i(0, -1)) in box.cells:
			out.append(c)
	return out


func _boxes_below(box: Box, origin: Vector2i) -> Array[Box]:
	var out: Array[Box] = []
	for c in _bottom_cells(box):
		var under := box_at(origin + c + Vector2i(0, -1))
		if under != null and not under in out:
			out.append(under)
	return out


func _boxes_above(box: Box, origin: Vector2i) -> Array[Box]:
	var out: Array[Box] = []
	for c in box.cells:
		var over := box_at(origin + c + Vector2i(0, 1))
		if over != null and over != box and not over in out:
			out.append(over)
	return out


func _break(box: Box, broken: Array[int]) -> void:
	box.broken = true
	if not box.id in broken:
		broken.append(box.id)


func _put(box: Box, origin: Vector2i) -> void:
	boxes[box.id] = box
	origins[box.id] = origin
	for c in box.cells:
		_grid[origin + c] = box.id


func _remove(box_id: int) -> void:
	var box: Box = boxes[box_id]
	for c in box.cells:
		_grid.erase(origins[box_id] + c)
	boxes.erase(box_id)
	origins.erase(box_id)
