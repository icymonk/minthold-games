class_name Hook
extends RefCounted
## 꿀팁·진상 손님·날씨가 같은 발동 지점에 붙는다. 필요한 것만 덮어쓴다.

var id: StringName


func modify_rules(_rules: Combo.Rules) -> void:
	pass


func on_shift_start(_shift: Shift) -> void:
	pass


func on_score_card(_receipt: Receipt, _card: Card) -> void:
	pass


func on_checkout(_receipt: Receipt) -> void:
	pass


func on_discard(_shift: Shift, _cards: Array[Card]) -> void:
	pass
