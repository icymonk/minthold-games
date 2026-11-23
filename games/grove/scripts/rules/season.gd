class_name Season
extends RefCounted
## 계절 하나(규칙 1-1): 계절 덱·손패·공터·숲. 화면을 모르고, 한 일은 log에 사건으로 남긴다.
## 차례 = A) 2장 가져오기(덱 맨 위 또는 공터에서 1장씩) 또는 B) 1장 내기(비용만큼 손패를 공터로).
## 낸 뒤 효과 → 버섯 지속 효과(Hook) → 보너스(비용으로 낸 카드가 모두 같은 나무 색일 때). 차례 끝에 공터가 10장 이상이면 쓸려 간다.
## 덱 아래 1/3에 계절 바람이 섞여 있다. 뽑히면 바람 칸이 차고 1장 더 뽑으며, 마지막 바람이 뜨면 그 즉시 계절이 끝난다.
## log가 SeasonLog다: 화면은 사건을 차례대로 연출만 한다.

const HAND_LIMIT := 10
const CLEARING_LIMIT := 10
const START_HAND := 6
const DRAWS_PER_TURN := 2
const WINDS := 3

var deck: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var clearing: Array[Dictionary] = []
var discard: Array[Dictionary] = []
var forest: Forest
## SeasonLog: [{t = deal|draw|pay|plant|sapling|attach|drift|effect|hook|bonus|free|again|cave|wind|over|sweep, ...}]
var log: Array[Dictionary] = []
var winds := WINDS
var winds_seen := 0
## 계절 사건·정령이 바꾸는 값
var hand_limit := HAND_LIMIT
var clearing_limit := CLEARING_LIMIT
## 첫 바람이 뜰 때 더 뽑는 장수(바람 아이)
var wind_bonus := 0
## 마지막 바람이 떠서 계절이 끝났다. 이후 모든 행동은 거절된다.
var over := false
var _rng := RandomNumberGenerator.new()
var _draws := 0
var _played := false
## 낸 뒤 남은 기회: [{t = free, tag, many?} | {t = more} | {t = stash}]. 차례가 끝나면 사라진다.
var pending: Array[Dictionary] = []


func _init(bag: Array[Dictionary], seed_value: int, grove: Forest = null, wind_count := WINDS) -> void:
	_rng.seed = seed_value
	forest = grove if grove else Forest.new()
	winds = wind_count
	deck = bag.duplicate()
	_shuffle(deck)
	# 덱의 맨 위는 배열 끝이다: 바람은 앞쪽(아래) 1/3에 섞는다
	var bottom := maxi(1, deck.size() / 3)
	for i in winds:
		deck.insert(_rng.randi_range(0, bottom + i), {id = -1 - i, wind = true, sym = &""})
	for i in START_HAND:
		_draw_top(&"deal")


func find(id: int, pile: Array[Dictionary]) -> int:
	for i in pile.size():
		if pile[i].id == id:
			return i
	return -1


## 덱에서 n장 더 나눠 받기(정령: 씨앗 지기)
func deal(n: int) -> void:
	for i in n:
		_draw_top(&"deal")


## 이번 차례에 가져온 장수(1장이라도 가져오면 내기는 못 한다)
func draws() -> int:
	return _draws


func can_draw() -> bool:
	return not over and not _played and _draws < DRAWS_PER_TURN and hand.size() < hand_limit


## A) 1장 가져오기. from = -1이면 덱 맨 위, 아니면 공터의 그 카드 id.
func draw(from: int = -1) -> bool:
	if over or _played or _draws >= DRAWS_PER_TURN or hand.size() >= hand_limit:
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
## pay: 비용으로 공터에 낼 손패 카드 id. picks: pick 효과로 공터에서 고를 카드 id(없으면 최근 것부터).
func play(id: int, half: int, plot: int, pay: Array[int], picks: Array[int] = []) -> bool:
	if not can_play(id, half, plot, pay):
		return false
	var card: Dictionary = hand[find(id, hand)]
	var def := Cards.def_of(card, half)
	var extra := _extra_for(card, half)
	var free: bool = extra.get("t", &"") == &"free"
	if free and not extra.get("many", false):
		pending.erase(extra)
	var hooks: Array[Dictionary] = []
	var paid: Array[Dictionary] = []
	for p in pay:
		var c: Dictionary = hand.pop_at(find(p, hand))
		clearing.append(c)
		paid.append(c)
		log.append({t = &"pay", card = p})
	hand.remove_at(find(id, hand))
	if Cards.is_tree(card):
		hooks = Hook.matching(Hook.collect(forest), &"plant", {})
		forest.plant(plot, card, card.tree)
		log.append({t = &"plant", card = id, plot = plot})
		# 나무를 심으면 덱 맨 위 1장이 공터로 날아간다
		var drift := _take()
		if not drift.is_empty():
			clearing.append(drift)
			log.append({t = &"drift", card = drift.id})
	else:
		var side := Cards.side_of(card, half)
		var species: StringName = card.halves[half]
		hooks = Hook.matching(Hook.collect(forest), &"place", {side = side, tags = Cards.tags_of(species)})
		forest.attach(plot, side, card, species)
		log.append({t = &"attach", card = id, half = half, plot = plot, side = side})
	_played = true
	if free:
		log.append({t = &"free", card = id})
	else:
		_apply(&"effect", id, def.effect, picks)
	for h in hooks:
		_apply(&"hook", h.card, h.give, picks)
	var sym := Cards.sym_of(card, half)
	if not free and not paid.is_empty() and (card.get("deco", &"") == &"gold" or paid.all(func(c: Dictionary) -> bool: return Cards.has_sym(c, sym))):
		_apply(&"bonus", id, def.bonus, picks)
	return true


## 지금 이 반쪽을 낼 수 있는 때인지(이번 차례에 이미 냈으면 남은 기회가 맞아야 한다)
func allows(card: Dictionary, half: int) -> bool:
	return not _played or not _extra_for(card, half).is_empty()


## 지금 이 반쪽을 낼 때 비용(공짜로 낼 수 있으면 0)
func cost_now(card: Dictionary, half: int) -> int:
	return 0 if _extra_for(card, half).get("t", &"") == &"free" else Cards.cost_of(card, half)


## 카드를 낸 뒤 더 낼 수 있는 기회(공짜·두더지)가 이 반쪽에 맞는지. 아직 안 냈으면 {}.
func _extra_for(card: Dictionary, half: int) -> Dictionary:
	if not _played:
		return {}
	var tags := Cards.tags_of(Cards.kind_of(card, half))
	for e in pending:
		if e.t == &"free" and e.tag in tags:
			return e
	for e in pending:
		if e.t == &"more":
			return e
	return {}


## 더 낼 기회가 남았는지(공짜·두더지). 손패 굴에 넣기(stash)는 따로 고른다.
func can_play_more() -> bool:
	return not over and pending.any(func(e: Dictionary) -> bool: return e.t != &"stash")


func wants_stash() -> bool:
	return not over and pending.any(func(e: Dictionary) -> bool: return e.t == &"stash")


## 남은 기회를 버리고 차례를 끝낼 준비
func skip() -> void:
	pending.clear()


## 라쿤: 손패에서 고른 카드를 굴에 넣고 그만큼 덱에서 뽑는다.
func stash(ids: Array[int]) -> bool:
	var at := pending.find_custom(func(e: Dictionary) -> bool: return e.t == &"stash")
	if at < 0:
		return false
	pending.remove_at(at)
	var n := 0
	for id in ids:
		var i := find(id, hand)
		if i < 0:
			continue
		forest.cave.append(hand.pop_at(i))
		log.append({t = &"cave", card = id})
		n += 1
	for i in n:
		if not _draw_top(&"stash"):
			break
	return true


func can_play(id: int, half: int, plot: int, pay: Array[int]) -> bool:
	var i := find(id, hand)
	if over or _draws > 0 or i < 0 or half < 0 or half > 1:
		return false
	var card: Dictionary = hand[i]
	if _played and _extra_for(card, half).is_empty():
		return false
	if pay.size() != cost_now(card, half) or pay.has(id):
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
	if over or _played or _draws > 0 or i < 0 or not forest.is_free(plot):
		return false
	forest.plant(plot, hand.pop_at(i), Forest.SAPLING)
	log.append({t = &"sapling", card = id, plot = plot})
	_played = true
	return true


## 차례 끝: 공터가 넘치면 바람이 쓸어 간다.
func end_turn() -> void:
	if clearing.size() >= clearing_limit:
		log.append({t = &"sweep", count = clearing.size()})
		discard.append_array(clearing)
		clearing.clear()
	_draws = 0
	_played = false
	pending.clear()


func _apply(kind: StringName, id: int, what: Dictionary, picks: Array[int]) -> void:
	if what.is_empty():
		return
	log.append({t = kind, card = id, what = what})
	for i in what.get("draw", 0):
		if hand.size() >= hand_limit or not _draw_top(kind):
			break
	for i in what.get("pick", 0):
		if hand.size() >= hand_limit or clearing.is_empty():
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
	if what.get("again", false):
		log.append({t = &"again", card = id})
	if what.has("free"):
		pending.append({t = &"free", tag = what.free})
	if what.has("free_all"):
		pending.append({t = &"free", tag = what.free_all, many = true})
	if what.get("more", false):
		pending.append({t = &"more"})
	if what.get("stash", false):
		pending.append({t = &"stash"})
	if what.has("draw_per"):
		var n := 0
		for o in forest.neighbors():
			if o.species == what.draw_per or what.draw_per in Cards.tags_of(o.species):
				n += 1
		for i in n:
			if hand.size() >= hand_limit or not _draw_top(kind):
				break
	if what.get("clear_to_cave", false):
		for c in clearing:
			log.append({t = &"cave", card = c.id})
		forest.cave.append_array(clearing)
		clearing.clear()
	for i in what.get("cave", 0):
		var c := _take()
		if c.is_empty():
			break
		forest.cave.append(c)
		log.append({t = &"cave", card = c.id})


func _draw_top(why: StringName) -> bool:
	var c := _take()
	if c.is_empty():
		return false
	hand.append(c)
	log.append({t = &"draw", card = c.id, from = why})
	return true


## 덱 맨 위 카드 1장. 바람이면 바람 칸을 채우고 다음 장으로 넘어간다. 마지막 바람이면 계절 끝({}).
func _take() -> Dictionary:
	while not over and not deck.is_empty():
		var c: Dictionary = deck.pop_back()
		if not c.get("wind", false):
			return c
		winds_seen += 1
		log.append({t = &"wind", n = winds_seen})
		if winds_seen >= winds:
			over = true
			log.append({t = &"over"})
		elif winds_seen == 1:
			for k in wind_bonus:
				var extra := _take()
				if extra.is_empty() or hand.size() >= hand_limit:
					if not extra.is_empty():
						clearing.append(extra)
					break
				hand.append(extra)
				log.append({t = &"draw", card = extra.id, from = &"wind"})
	return {}


func _shuffle(pile: Array[Dictionary]) -> void:
	for i in range(pile.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := pile[i]
		pile[i] = pile[j]
		pile[j] = tmp
