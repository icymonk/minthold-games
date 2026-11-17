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


## 디버그·테스트용 표기: "m5 s12+ d7?" — 코너 첫 글자, 가격, 꼬리표 기호(+ 할인, * 행사, ~ 냉장, ? PB, $ 금박, x 폐기).
static func parse(text: String) -> Array[Card]:
	const LETTER := {"m": MEAL, "s": SNACK, "d": DRINK, "g": GOODS}
	const MARK := {"+": TAG_DISCOUNT, "*": TAG_EVENT, "~": TAG_CHILLED, "?": TAG_PB, "$": TAG_GOLD}
	var out: Array[Card] = []
	for word in text.split(" ", false):
		var mark := "" if word.right(1).is_valid_int() else word.right(1)
		var c := Card.new(LETTER[word.left(1)], int(word.substr(1, word.length() - 1 - mark.length())), MARK.get(mark, TAG_NONE))
		if mark == "x":
			c.shelf_life = 0
		out.append(c)
	return out


static func standard_deck() -> Array[Card]:
	var deck: Array[Card] = []
	for c in CORNERS:
		for r in range(1, 14):
			deck.append(Card.new(c, r))
	return deck


func copy() -> Card:
	var c := Card.new(corner, rank, tag)
	c.shelf_life = shelf_life
	return c


func is_waste() -> bool:
	return shelf_life == 0


## PB 상품은 어느 코너로도 센다.
func counts_as(c: StringName) -> bool:
	return tag == TAG_PB or corner == c


func _to_string() -> String:
	return "%s%d%s" % [corner.substr(0, 1), rank, "" if tag == TAG_NONE else "+" + tag]
