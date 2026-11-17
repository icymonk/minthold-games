class_name Expansions
extends RefCounted
## 매장 확장: 그 런 동안 계속 붙어 있는 Hook. 꿀팁보다 먼저 발동한다.

const MAKERS := {
	&"extra_register": ExtraRegister,
	&"storage": Storage,
}


static func make(expansion_id: StringName) -> Hook:
	var h: Hook = MAKERS[expansion_id].new()
	h.id = expansion_id
	return h


## 계산대 하나 더: 계산 +1
class ExtraRegister:
	extends Hook

	func on_shift_start(shift: Shift) -> void:
		shift.checkouts_left += 1


## 창고: 손패 +1
class Storage:
	extends Hook

	func on_shift_start(shift: Shift) -> void:
		shift.hand_size += 1
