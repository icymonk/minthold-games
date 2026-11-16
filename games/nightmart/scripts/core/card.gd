class_name Card
extends RefCounted
## 상품 카드 한 장. 코너(무늬)·가격(1~13)·꼬리표·유통기한을 가진다.

const MEAL := &"meal"
const SNACK := &"snack"
const DRINK := &"drink"
const GOODS := &"goods"
const CORNERS: Array[StringName] = [MEAL, SNACK, DRINK, GOODS]

## 꼬리표(전단지로 붙임). 값은 Receipt가 계산한다.
const TAG_NONE := &""
const TAG_DISCOUNT := &"discount"
const TAG_EVENT := &"event"
const TAG_CHILLED := &"chilled"
const TAG_PB := &"pb"
const TAG_GOLD := &"gold"

var corner: StringName
var rank: int
var tag: StringName = TAG_NONE
## 남은 밤 수. -1은 유통기한 없음, 0은 폐기.
var shelf_life := -1


func _init(card_corner: StringName, card_rank: int, card_tag: StringName = TAG_NONE) -> void:
	assert(card_corner in CORNERS and card_rank >= 1 and card_rank <= 13)
	corner = card_corner
	rank = card_rank
	tag = card_tag


static func standard_deck() -> Array[Card]:
	var deck: Array[Card] = []
	for c in CORNERS:
		for r in range(1, 14):
			deck.append(Card.new(c, r))
	return deck


func is_waste() -> bool:
	return shelf_life == 0


## PB 상품은 어느 코너로도 센다.
func counts_as(c: StringName) -> bool:
	return tag == TAG_PB or corner == c


func _to_string() -> String:
	return "%s%d%s" % [corner.substr(0, 1), rank, "" if tag == TAG_NONE else "+" + tag]
