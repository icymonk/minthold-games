class_name Bag
extends RefCounted
## 보따리 격자. 오른쪽이 앞(행렬이 오는 쪽), 각 줄(y)이 행렬의 길 하나다.
## width × height는 보따리가 넓어질 수 있는 최대 범위이고, 실제로 쓸 수 있는 칸은 `open`이다.

const DIRS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var width: int
var height: int
var pieces: Array[Piece] = []
## 쓸 수 있는 칸 → true.
var open := {}
## 특수 칸 → 종류(&"well", &"hearth").
var special := {}


func _init(w: int, h: int, full := true) -> void:
	width = w
	height = h
	if full:
		for y in h:
			for x in w:
				open[Vector2i(x, y)] = true


func in_canvas(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


func in_bounds(c: Vector2i) -> bool:
	return open.has(c)


## 조각을 at에 붙일 수 있는지: 범위 안의 빈 땅이고, 한 칸 이상 지금 보따리와 맞닿아야 한다.
func can_expand(plot: Plot, at: Vector2i) -> bool:
	var touches := false
	for c in plot.cells:
		var w := c + at
		if not in_canvas(w) or open.has(w):
			return false
		for d in DIRS:
			if open.has(w + d):
				touches = true
	return touches


func expand(plot: Plot, at: Vector2i) -> bool:
	if not can_expand(plot, at):
		return false
	for c in plot.cells:
		open[c + at] = true
		if plot.special.has(c):
			special[c + at] = plot.special[c]
	return true


## 어떤 방향으로든 조각을 붙일 자리가 있으면 그 자리({"plot", "at"})를, 없으면 빈 사전을 준다. 오른쪽(앞)부터 찾는다.
func expand_spot(plot: Plot) -> Dictionary:
	var p := plot.copy()
	for r in 4:
		for x in range(width - 1, -1, -1):
			for y in height:
				if can_expand(p, Vector2i(x, y)):
					return {"plot": p, "at": Vector2i(x, y)}
		p.rotate_cw()
	return {}


## 요괴가 올라선 특수 칸 종류들.
func specials_under(p: Piece) -> Array[StringName]:
	var out: Array[StringName] = []
	for c in p.world_cells():
		if special.has(c) and special[c] not in out:
			out.append(special[c])
	return out


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
		for d in DIRS:
			if c + d in bc:
				return true
	return false


func neighbors(p: Piece) -> Array[Piece]:
	var out: Array[Piece] = []
	for o in pieces:
		if touching(p, o):
			out.append(o)
	return out


## 다른 종류를 먹을 때 food의 공격·체력 중 eater가 얻는 비율. 같은 종류는 전부 얻는다.
const FEED_SHARE := 0.5
## 같은 종류를 먹으면 배가 이만큼 찬다.
const SAME_KIND_FILL := 2

enum Feed { OK, EVOLVED, SELF, FULL, FOOD_EVOLVED, NO_ROOM }


## eater가 food를 먹는다. 둘 다 보따리 안이든 밖(대기 줄·장터)이든 상관없다. food가 보따리에 있으면 칸이 빈다.
## 배는 1칸(같은 종류면 2칸) + food가 이미 먹은 만큼 찬다. 같은 종류는 공격·체력을 전부, 다른 종류는 절반과 원래 특성을 얻는다.
## 배가 차면 정해진 모양으로 변신한다. eater가 보따리 안에 있는데 변신한 모양을 놓을 자리가 없으면 먹지 않는다.
func feed(eater: Piece, food: Piece) -> Feed:
	if eater == food:
		return Feed.SELF
	if not eater.hungry():
		return Feed.FULL
	if food.evolved:
		return Feed.FOOD_EVOLVED
	var same := eater.base_kind() == food.base_kind()
	var fill := (SAME_KIND_FILL if same else 1) + food.eaten
	var evolves := eater.eaten + fill >= eater.belly
	var form_key: StringName = YokaiDb.ALLIES[eater.kind]["evolve"]
	var form_cells: Array[Vector2i] = []
	var form_pos := eater.pos
	if evolves:
		form_cells.assign(YokaiDb.FORMS[form_key]["cells"])
		if eater in pieces:
			var spot := _evolve_spot(eater, food, form_key)
			if spot.is_empty():
				return Feed.NO_ROOM
			form_cells = spot["cells"]
			form_pos = spot["pos"]
	pieces.erase(food)
	var share := 1.0 if same else FEED_SHARE
	eater.atk += ceili(food.atk * share)
	eater.hp += ceili(food.hp * share)
	var inherited: StringName = YokaiDb.ALLIES[food.base_kind()]["trait"]
	if eater.traits.size() < Piece.MAX_TRAITS and not eater.has_trait(inherited):
		eater.traits.append(inherited)
	eater.eaten = mini(eater.eaten + fill, eater.belly)
	if not evolves:
		return Feed.OK
	var form: Dictionary = YokaiDb.FORMS[form_key]
	eater.kind = form_key
	eater.evolved = true
	eater.cells = form_cells
	eater.pos = form_pos
	eater.atk += form["atk"]
	eater.hp += form["hp"]
	eater.interval = form["interval"]
	return Feed.EVOLVED


## 변신한 모양을 놓을 자리. 지금 차지한 칸과 가장 많이 겹치는 위치(동점이면 더 오른쪽)를 고른다.
func _evolve_spot(eater: Piece, food: Piece, form_key: StringName) -> Dictionary:
	var shape: Array[Vector2i] = []
	shape.assign(YokaiDb.FORMS[form_key]["cells"])
	var mine := eater.world_cells()
	var best := {}
	var best_score := -1
	for r in 4:
		for e in mine:
			for c in shape:
				var at := e - c
				var score := 0
				var ok := true
				for sc in shape:
					var w := sc + at
					var other := piece_at(w)
					if not in_bounds(w) or (other != null and other != eater and other != food):
						ok = false
						break
					if w in mine:
						score += 1
				score = score * 100 + at.x
				if ok and score > best_score:
					best_score = score
					best = {"cells": shape.duplicate(), "pos": at}
		var rotated: Array[Vector2i] = []
		for c in shape:
			rotated.append(Vector2i(-c.y, c.x))
		shape = Piece.normalized(rotated)
	return best
