class_name Shift
extends RefCounted
## 손님 한 명. 진열대(덱)를 섞어 손패를 채우고, 계산·바꾸기로 목표 매출을 넘긴다.

const HAND_SIZE := 8
const CHECKOUTS := 4
const SWAPS := 3
const LEFTOVER_BONUS := 1000

var target: int
var score := 0
var money := 0
var hand_size := HAND_SIZE
var max_cards := Combo.MAX_CARDS
## 뒷면으로 나오는 카드(진상 손님·날씨)
var hidden_corners: Array[StringName] = []
var hidden_cards: Array[Card] = []
var checkouts_left := CHECKOUTS
var swaps_left := SWAPS
var hand: Array[Card] = []
var draw_pile: Array[Card] = []
var discard_pile: Array[Card] = []
var receipts: Array[Receipt] = []
var hooks: Array[Hook]
var levels: Dictionary


func _init(deck: Array[Card], target_sales: int, rng: RandomNumberGenerator, tips: Array[Hook] = [], combo_levels: Dictionary = {}) -> void:
	target = target_sales
	hooks = tips
	levels = combo_levels
	draw_pile = deck.duplicate()
	for i in range(draw_pile.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = t
	for h in hooks:
		h.on_shift_start(self)
	_refill()


func is_hidden(c: Card) -> bool:
	return hidden_cards.has(c) or hidden_corners.has(c.corner)


func cleared() -> bool:
	return score >= target


## 계산을 다 쓰거나, 진열대가 비어 낼 카드가 없으면 실패.
func failed() -> bool:
	return not cleared() and (checkouts_left <= 0 or hand.is_empty())


func is_over() -> bool:
	return cleared() or failed()


## 손님을 보냈을 때 남은 계산 1번당 보너스.
func leftover_bonus() -> int:
	return checkouts_left * LEFTOVER_BONUS if cleared() else 0


func can_play(cards: Array[Card]) -> bool:
	return not is_over() and checkouts_left > 0 and cards.size() <= max_cards and _valid(cards)


func can_discard(cards: Array[Card]) -> bool:
	return not is_over() and swaps_left > 0 and _valid(cards)


func play(cards: Array[Card]) -> Receipt:
	if not can_play(cards):
		return null
	for c in cards:
		hand.erase(c)
	var r := Receipt.ring_up(cards, levels, hooks, hand.duplicate(), checkouts_left)
	checkouts_left -= 1
	score += r.total()
	money += r.money
	discard_pile.append_array(cards)
	receipts.append(r)
	if not cleared():
		_refill()
	return r


## 계산하지 않고 점수만 본다(조합 미리 보기·봇).
func preview(cards: Array[Card]) -> Receipt:
	var held := hand.filter(func(c: Card) -> bool: return not cards.has(c))
	return Receipt.ring_up(cards, levels, hooks, Array(held, TYPE_OBJECT, &"RefCounted", Card), checkouts_left, true)


func discard(cards: Array[Card]) -> bool:
	if not can_discard(cards):
		return false
	for c in cards:
		hand.erase(c)
	swaps_left -= 1
	discard_pile.append_array(cards)
	for h in hooks:
		h.on_discard(self, cards)
	_refill()
	return true


func _valid(cards: Array[Card]) -> bool:
	if cards.is_empty() or cards.size() > Combo.MAX_CARDS:
		return false
	var seen := {}
	for c in cards:
		if seen.has(c) or not hand.has(c):
			return false
		seen[c] = true
	return true


func _refill() -> void:
	while hand.size() < hand_size and not draw_pile.is_empty():
		hand.append(draw_pile.pop_back())
