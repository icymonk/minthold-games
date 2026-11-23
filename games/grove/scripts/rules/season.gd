class_name Season
extends RefCounted
## 계절 하나(규칙 1-1): 계절 덱·손패·빈터·숲. 화면을 모르고, 한 일은 log에 사건으로 남긴다.
## 차례 = A) 2장 가져오기(덱 맨 위 또는 빈터에서 1장씩) 또는 B) 1장 내기(비용만큼 손패를 빈터로).
## 낸 뒤 효과 → 보너스(비용으로 낸 카드가 모두 같은 나무 색일 때). 차례 끝에 빈터가 10장 이상이면 쓸려 간다.

const HAND_LIMIT := 10
const CLEARING_LIMIT := 10
const START_HAND := 6
const DRAWS_PER_TURN := 2

var deck: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var clearing: Array[Dictionary] = []
var discard: Array[Dictionary] = []
var forest: Forest
## [{t = draw|pay|plant|sapling|attach|drift|effect|bonus|sweep, ...}]
var log: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _draws := 0
var _played := false


func _init(bag: Array[Dictionary], seed_value: int, grove: Forest = null) -> void:
	_rng.seed = seed_value
	forest = grove if grove else Forest.new()
	deck = bag.duplicate()
	_shuffle(deck)
	for i in START_HAND:
		_draw_top(&"deal")


func find(id: int, pile: Array[Dictionary]) -> int:
	for i in pile.size():
		if pile[i].id == id:
			return i
	return -1


## A) 1장 가져오기. from = -1이면 덱 맨 위, 아니면 빈터의 그 카드 id.
func draw(from: int = -1) -> bool:
	if _played or _draws >= DRAWS_PER_TURN or hand.size() >= HAND_LIMIT:
		return false
	if from < 0:
		if not _draw_top(&"deck"):
			return false
	else:
		var i := find(from, clearing)
		if i < 0:
			return false
		var c: Dictionary = clearing.pop_at(i)
		hand.append(c)
		log.append({t = &"draw", card = c.id, from = &"clearing"})
	_draws += 1
	return true


## B) 1장 내기. 나무 카드는 빈 땅 plot에 심고(side 무시), 이웃 카드는 half 반쪽을 plot 나무의 그 방향 자리에 붙인다.
## pay: 비용으로 빈터에 낼 손패 카드 id. picks: pick 효과로 빈터에서 고를 카드 id(없으면 최근 것부터).
func play(id: int, half: int, plot: int, pay: Array[int], picks: Array[int] = []) -> bool:
	if not can_play(id, half, plot, pay):
		return false
	var card: Dictionary = hand[find(id, hand)]
	var def := Cards.def_of(card, half)
	var paid: Array[Dictionary] = []
	for p in pay:
		var c: Dictionary = hand.pop_at(find(p, hand))
		clearing.append(c)
		paid.append(c)
		log.append({t = &"pay", card = p})
	hand.remove_at(find(id, hand))
	if Cards.is_tree(card):
		forest.plant(plot, card, card.tree)
		log.append({t = &"plant", card = id, plot = plot})
		# 나무를 심으면 덱 맨 위 1장이 빈터로 날아간다
		if not deck.is_empty():
			var drift: Dictionary = deck.pop_back()
			clearing.append(drift)
			log.append({t = &"drift", card = drift.id})
	else:
		var side := Cards.side_of(card, half)
		forest.attach(plot, side, card, card.halves[half])
		log.append({t = &"attach", card = id, half = half, plot = plot, side = side})
	_played = true
	_apply(&"effect", id, def.effect, picks)
	if not paid.is_empty() and paid.all(func(c: Dictionary) -> bool: return c.sym == card.sym):
		_apply(&"bonus", id, def.bonus, picks)
	return true


func can_play(id: int, half: int, plot: int, pay: Array[int]) -> bool:
	var i := find(id, hand)
	if _played or _draws > 0 or i < 0 or half < 0 or half > 1:
		return false
	var card: Dictionary = hand[i]
	if pay.size() != Cards.cost_of(card, half) or pay.has(id):
		return false
	var seen := {}
	for p in pay:
		if seen.has(p) or find(p, hand) < 0:
			return false
		seen[p] = true
	if Cards.is_tree(card):
		return forest.is_free(plot)
	return forest.can_attach(plot, Cards.side_of(card, half), card.halves[half])


## 아무 카드나 뒷면으로 묘목으로 심는다(비용·효과 없음).
func sapling(id: int, plot: int) -> bool:
	var i := find(id, hand)
	if _played or _draws > 0 or i < 0 or not forest.is_free(plot):
		return false
	forest.plant(plot, hand.pop_at(i), Forest.SAPLING)
	log.append({t = &"sapling", card = id, plot = plot})
	_played = true
	return true


## 차례 끝: 빈터가 넘치면 바람이 쓸어 간다.
func end_turn() -> void:
	if clearing.size() >= CLEARING_LIMIT:
		log.append({t = &"sweep", count = clearing.size()})
		discard.append_array(clearing)
		clearing.clear()
	_draws = 0
	_played = false


func _apply(kind: StringName, id: int, what: Dictionary, picks: Array[int]) -> void:
	if what.is_empty():
		return
	log.append({t = kind, card = id, what = what})
	for i in what.get("draw", 0):
		if hand.size() >= HAND_LIMIT or not _draw_top(kind):
			break
	for i in what.get("pick", 0):
		if hand.size() >= HAND_LIMIT or clearing.is_empty():
			break
		var at := -1
		for p in picks:
			at = find(p, clearing)
			if at >= 0:
				picks.erase(p)
				break
		var c: Dictionary = clearing.pop_at(at if at >= 0 else clearing.size() - 1)
		hand.append(c)
		log.append({t = &"draw", card = c.id, from = &"clearing"})
	for i in what.get("cave", 0):
		if deck.is_empty():
			break
		var c: Dictionary = deck.pop_back()
		forest.cave.append(c)
		log.append({t = &"cave", card = c.id})


func _draw_top(why: StringName) -> bool:
	if deck.is_empty():
		return false
	var c: Dictionary = deck.pop_back()
	hand.append(c)
	log.append({t = &"draw", card = c.id, from = why})
	return true


func _shuffle(pile: Array[Dictionary]) -> void:
	for i in range(pile.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := pile[i]
		pile[i] = pile[j]
		pile[j] = tmp
