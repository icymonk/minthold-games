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


## 먹을 때 food의 공격·체력 중 eater가 얻는 비율.
const FEED_SHARE := 0.5

enum Feed { OK, EVOLVED, NOT_TOUCHING, FULL, FOOD_EVOLVED, NO_ROOM }


## eater가 맞닿은 food를 먹는다. food는 사라져 칸이 비고, eater는 공격·체력 절반과 food의 원래 특성을 얻는다.
## 배(belly)가 차면 정해진 모양으로 변신하는데, 놓을 자리가 없으면 먹지 않는다.
func feed(eater: Piece, food: Piece) -> Feed:
	if eater not in pieces or food not in pieces or not touching(eater, food):
		return Feed.NOT_TOUCHING
	if not eater.hungry():
		return Feed.FULL
	if food.evolved:
		return Feed.FOOD_EVOLVED
	var evolves := eater.eaten + 1 >= eater.belly
	var form_cells: Array[Vector2i] = []
	var form_pos := eater.pos
	if evolves:
		pieces.erase(food)
		var spot := _evolve_spot(eater, YokaiDb.ALLIES[eater.kind]["evolve"])
		if spot.is_empty():
			pieces.append(food)
			return Feed.NO_ROOM
		form_cells = spot["cells"]
		form_pos = spot["pos"]
	pieces.erase(food)
	eater.atk += ceili(food.atk * FEED_SHARE)
	eater.hp += ceili(food.hp * FEED_SHARE)
	var inherited: StringName = YokaiDb.ALLIES[food.base_kind()]["trait"]
	if eater.traits.size() < Piece.MAX_TRAITS and not eater.has_trait(inherited):
		eater.traits.append(inherited)
	eater.eaten += 1
	if not evolves:
		return Feed.OK
	var form_key: StringName = YokaiDb.ALLIES[eater.kind]["evolve"]
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
func _evolve_spot(eater: Piece, form_key: StringName) -> Dictionary:
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
					if not in_bounds(w) or (other != null and other != eater):
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
