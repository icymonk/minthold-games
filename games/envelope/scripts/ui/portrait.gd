class_name Portrait
extends Control
## 동료 얼굴(자리 번호로 머리·옷 색이 다르다).

var kind := -1
var seat := 0


func _init(seat_index := 0, card_kind := -1, side := 72.0) -> void:
	seat = seat_index
	kind = card_kind
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_circle(r.get_center(), minf(size.x, size.y) * 0.5, Color(Style.PARTITION, 0.35))
	Art.portrait(self, r.grow(-minf(size.x, size.y) * 0.05), kind, seat)
