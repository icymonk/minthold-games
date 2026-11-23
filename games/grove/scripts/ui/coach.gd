class_name Coach
extends Control
## 처음 할 때 안내. 화면을 어둡게 덮고 봐야 할 곳만 비운 뒤, 해 보면 다음 단계로 넘어간다.
## 단계: {text, hole: Callable → Rect2, wait: Signal(없으면 「다음」 버튼), check: Callable(args) → bool}

signal finished

const SETTINGS := "user://settings.cfg"
const HOLE_SHADER := preload("res://shaders/coach_hole.gdshader")

var steps: Array[Dictionary] = []
var index := -1
var _dim: ColorRect
var _bubble: PanelContainer
var _text: Label
var _next: Button
var _wired: Array = []


static func seen() -> bool:
	var cfg := ConfigFile.new()
	return cfg.load(SETTINGS) == OK and cfg.get_value("coach", "done", false)


static func mark_seen(on := true) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("coach", "done", on)
	cfg.save(SETTINGS)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim = ColorRect.new()
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = HOLE_SHADER
	_dim.material = m
	add_child(_dim)
	_bubble = PanelContainer.new()
	_bubble.add_theme_stylebox_override(&"panel", Style.glass())
	_bubble.custom_minimum_size.x = 860
	add_child(_bubble)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 16)
	_bubble.add_child(col)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_override(&"font", Style.bold())
	col.add_child(_text)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override(&"separation", 16)
	col.add_child(row)
	var skip := Button.new()
	skip.text = tr("COACH_SKIP")
	skip.custom_minimum_size = Vector2(240, 88)
	skip.pressed.connect(finish)
	row.add_child(skip)
	_next = Button.new()
	_next.text = tr("COACH_NEXT")
	_next.theme_type_variation = &"AccentButton"
	_next.custom_minimum_size = Vector2(240, 88)
	_next.pressed.connect(advance)
	row.add_child(_next)


func start(s: Array[Dictionary]) -> void:
	steps = s
	index = -1
	advance()


func advance() -> void:
	_unwire()
	index += 1
	if index >= steps.size():
		finish()
		return
	var step := steps[index]
	_text.text = tr(step.text)
	var wait: Signal = step.get("wait", Signal())
	_next.visible = wait.is_null()
	if not wait.is_null():
		var cb := func(a: Variant = null, b: Variant = null) -> void: _on_wait([a, b])
		wait.connect(cb)
		_wired = [wait, cb]
	if is_inside_tree():
		Sfx.play(&"chime", 0.6)


func _on_wait(args: Array) -> void:
	var check: Callable = steps[index].get("check", Callable())
	if check.is_valid() and not check.call(args):
		return
	advance.call_deferred()


func _unwire() -> void:
	if _wired.size() == 2 and _wired[0].is_connected(_wired[1]):
		_wired[0].disconnect(_wired[1])
	_wired = []


func finish() -> void:
	_unwire()
	mark_seen()
	index = steps.size()
	finished.emit()
	queue_free()


func _process(_delta: float) -> void:
	if index < 0 or index >= steps.size():
		return
	var hole_fn: Callable = steps[index].get("hole", Callable())
	var r: Rect2 = hole_fn.call() if hole_fn.is_valid() else Rect2()
	r = r.grow(18.0) if r.has_area() else Rect2()
	var m := _dim.material as ShaderMaterial
	m.set_shader_parameter(&"hole", Vector4(r.position.x, r.position.y, r.size.x, r.size.y))
	m.set_shader_parameter(&"area", size)
	# 말풍선은 구멍과 겹치지 않게 위 또는 아래에
	var below := not r.has_area() or r.get_center().y < size.y * 0.45
	var y := (r.end.y + 32.0) if below and r.has_area() else (r.position.y - _bubble.size.y - 32.0 if r.has_area() else size.y * 0.3)
	_bubble.position = Vector2((size.x - _bubble.size.x) / 2.0, clampf(y, 140.0, size.y - _bubble.size.y - 24.0))
