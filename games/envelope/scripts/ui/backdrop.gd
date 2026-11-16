class_name Backdrop
extends Control
## 바탕: 형광등 아래 책상 위 줄 노트.

const LINE := 56.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Style.PAPER)
	var y := LINE
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(Style.PARTITION, 0.18), 2.0)
		y += LINE
	draw_line(Vector2(96, 0), Vector2(96, size.y), Color(Style.STAMP, 0.18), 2.0)
