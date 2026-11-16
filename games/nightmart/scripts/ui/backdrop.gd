class_name Backdrop
extends Control
## 새벽 편의점 배경: 위가 밝은 남색 그라데이션, 가장자리 비네트, 가끔 깜빡이는 형광등.

var _light := 1.0
var _rng := RandomNumberGenerator.new()
var _tex: GradientTexture2D
var _glow: GradientTexture2D


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new()
	g.set_color(0, Style.NIGHT.lightened(0.14))
	g.set_color(1, Style.NIGHT_DEEP)
	_tex = GradientTexture2D.new()
	_tex.gradient = g
	_tex.fill = GradientTexture2D.FILL_RADIAL
	_tex.fill_from = Vector2(0.5, 0.0)
	_tex.fill_to = Vector2(1.1, 1.2)
	var gg := Gradient.new()
	gg.set_color(0, Color(Style.FLUORESCENT, 0.16))
	gg.set_color(1, Color(Style.FLUORESCENT, 0.0))
	_glow = GradientTexture2D.new()
	_glow.gradient = gg
	_glow.fill = GradientTexture2D.FILL_RADIAL
	_glow.fill_from = Vector2(0.5, 0.5)
	_glow.fill_to = Vector2(0.5, 1.0)
	resized.connect(queue_redraw)
	_rng.randomize()
	_schedule_flicker()


func _draw() -> void:
	draw_texture_rect(_tex, Rect2(Vector2.ZERO, size), false)
	draw_texture_rect(_glow, Rect2(size.x * 0.1, -size.y * 0.45, size.x * 0.8, size.y), false, Color(1, 1, 1, _light))
	var y := 22.0
	draw_line(Vector2(size.x * 0.32, y), Vector2(size.x * 0.68, y), Color(Style.FLUORESCENT, 0.3 + 0.6 * _light), 8.0, true)


func _set_light(v: float) -> void:
	_light = v
	queue_redraw()


func _schedule_flicker() -> void:
	var tw := create_tween()
	tw.tween_interval(_rng.randf_range(3.0, 8.0))
	for v in [0.2, 1.0, 0.45, 1.0]:
		tw.tween_method(_set_light, _light, v, 0.05)
	tw.tween_callback(_schedule_flicker)
