class_name Coach
extends CanvasLayer
## 처음 할 때 단계별 안내(driver.js식): 화면을 어둡게 하고 대상 하나만 밝힌 뒤 말풍선을 띄운다.
## 단계는 {"id", "text", "wait"} 데이터다. wait가 &"tap"이면 화면을 누르면, 아니면 notify(wait)가 오면 넘어간다.

signal finished

const SAVE_PATH := "user://coach.cfg"
const DIM := Color(0.03, 0.02, 0.03, 0.72)
const SHADER := """
shader_type canvas_item;
uniform vec4 hole;
uniform vec2 size;
uniform float radius = 24.0;
uniform float glow = 0.0;
uniform vec4 dim : source_color;
uniform vec4 rim : source_color;
void fragment() {
	vec2 p = UV * size;
	vec2 c = hole.xy + hole.zw * 0.5;
	vec2 q = abs(p - c) - hole.zw * 0.5 + radius;
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
	float inside = 1.0 - smoothstep(-1.5, 1.5, d);
	float ring = (1.0 - smoothstep(0.0, 6.0 + glow * 6.0, abs(d - 4.0))) * (0.55 + glow * 0.45);
	COLOR = mix(dim, vec4(0.0), inside);
	COLOR = mix(COLOR, rim, ring * step(0.0, d));
}
"""

var id := &""
## 대상 칸(화면 좌표)을 돌려주는 함수: func(step_id: StringName) -> Rect2
var rect_of: Callable
var steps: Array = []
var index := -1
var save_path := SAVE_PATH

var _shade: _Shade
var _bubble: PanelContainer
var _icon: TextureRect
var _text: Label
var _dots: Label
var _skip: Button
var _hole := Rect2()
var _hole_tween: Tween


class _Shade extends ColorRect:
	var coach: Coach

	func _has_point(point: Vector2) -> bool:
		return coach.waiting_for() == &"tap" or not coach.current_rect().has_point(point)

	func _gui_input(event: InputEvent) -> void:
		var b := event as InputEventMouseButton
		if b and b.pressed and coach.waiting_for() == &"tap":
			accept_event()
			coach.notify(&"tap")


func _init() -> void:
	layer = 50
	visible = false


func _ready() -> void:
	_shade = _Shade.new()
	_shade.coach = self
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = SHADER
	mat.set_shader_parameter(&"dim", DIM)
	mat.set_shader_parameter(&"rim", Style.NEON)
	_shade.material = mat
	add_child(_shade)
	_bubble = PanelContainer.new()
	_bubble.add_theme_stylebox_override(&"panel", Style.box(Style.FLUORESCENT, 24, Style.NEON, 4))
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bubble)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", 28)
	_bubble.add_child(row)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(110, 110)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.modulate = Style.NIGHT_DEEP
	row.add_child(_icon)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override(&"separation", 10)
	row.add_child(col)
	_text = Label.new()
	_text.add_theme_font_override(&"font", Style.bold())
	_text.add_theme_font_size_override(&"font_size", 48)
	_text.add_theme_color_override(&"font_color", Style.NIGHT_DEEP)
	col.add_child(_text)
	var foot := HBoxContainer.new()
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_theme_constant_override(&"separation", 40)
	col.add_child(foot)
	_dots = Label.new()
	_dots.add_theme_font_size_override(&"font_size", 32)
	_dots.add_theme_color_override(&"font_color", Style.NEON_DARK)
	_dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_dots)
	_skip = Button.new()
	_skip.text = tr("COACH_SKIP")
	_skip.flat = true
	_skip.add_theme_font_size_override(&"font_size", 32)
	_skip.add_theme_color_override(&"font_color", Color(Style.NIGHT_DEEP, 0.6))
	_skip.add_theme_color_override(&"font_hover_color", Style.NEON_DARK)
	_skip.pressed.connect(skip)
	foot.add_child(_skip)
	var pulse := create_tween().set_loops()
	pulse.tween_method(func(v: float) -> void: mat.set_shader_parameter(&"glow", v), 0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	pulse.tween_method(func(v: float) -> void: mat.set_shader_parameter(&"glow", v), 1.0, 0.0, 0.6).set_trans(Tween.TRANS_SINE)


## 이 안내를 이미 봤으면 false를 돌려주고 아무것도 하지 않는다.
func start(coach_id: StringName, coach_steps: Array) -> bool:
	id = coach_id
	steps = coach_steps
	if seen():
		index = steps.size()
		return false
	index = 0
	_show_step()
	return true


func running() -> bool:
	return index >= 0 and index < steps.size()


func current_id() -> StringName:
	return steps[index]["id"] if running() else &""


func waiting_for() -> StringName:
	return steps[index]["wait"] if running() else &""


func current_rect() -> Rect2:
	return _hole if running() and visible else Rect2()


## 화면이 일을 알린다(예: &"grabbed"). 지금 단계가 기다리던 일이면 다음 단계로 간다.
func notify(event: StringName) -> void:
	if running() and waiting_for() == event:
		index += 1
		if running():
			_show_step()
		else:
			_finish()


## 지금 단계를 잠깐 숨긴다(연출이 도는 동안). resume()으로 다시 띄운다.
func pause() -> void:
	visible = false


func resume() -> void:
	if running():
		_show_step()


func skip() -> void:
	index = steps.size()
	_finish()


func seen() -> bool:
	var cfg := ConfigFile.new()
	return cfg.load(save_path) == OK and cfg.get_value("seen", String(id), false)


func _finish() -> void:
	visible = false
	var cfg := ConfigFile.new()
	cfg.load(save_path)
	cfg.set_value("seen", String(id), true)
	cfg.save(save_path)
	finished.emit()


func _show_step() -> void:
	if not is_inside_tree():
		return
	var step: Dictionary = steps[index]
	var target: Rect2 = rect_of.call(step["id"]) if rect_of.is_valid() else Rect2()
	_text.text = tr(step["text"])
	_icon.texture = step.get("icon")
	_icon.visible = _icon.texture != null
	var dots := PackedStringArray()
	for i in steps.size():
		dots.append("●" if i <= index else "○")
	_dots.text = " ".join(dots)
	var was_visible := visible
	visible = true
	if _hole_tween:
		_hole_tween.kill()
	if was_visible:
		_hole_tween = create_tween()
		_hole_tween.tween_method(_set_hole, _hole, target, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_set_hole(target)
	_bubble.reset_size()
	_bubble.modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(_bubble, ^"modulate:a", 1.0, 0.25)
	_place_bubble.call_deferred(target)


func _set_hole(r: Rect2) -> void:
	_hole = r
	var mat := _shade.material as ShaderMaterial
	mat.set_shader_parameter(&"size", _shade.size)
	mat.set_shader_parameter(&"hole", Vector4(r.position.x, r.position.y, r.size.x, r.size.y))


## 말풍선을 대상 위나 아래, 공간이 넓은 쪽에 붙인다.
func _place_bubble(target: Rect2) -> void:
	var view := _shade.size
	var b := _bubble.size
	var x := clampf(target.get_center().x - b.x / 2.0, view.x * 0.05, view.x * 0.95 - b.x)
	var below := target.end.y + 40.0
	var above := target.position.y - 40.0 - b.y
	var y := below if view.y - target.end.y > target.position.y else above
	_bubble.position = Vector2(x, clampf(y, view.y * 0.05, view.y * 0.95 - b.y))
