class_name Tour
extends Control
## 화면 안내: 나머지를 어둡게 덮고 한 곳만 밝혀 말풍선으로 설명한다(driver.js처럼).
## 단계마다 { target: Control, title: String, body: String }.

signal finished

const PAD := 14.0
const MOVE_TIME := 0.25
const BUBBLE_W := 620.0
const GAP := 24.0

var steps: Array[Dictionary] = []
var index := 0
var hole := Rect2()

var _bubble: PanelContainer
var _title: Label
var _body: Label
var _count: Label
var _prev: Button
var _next: Button
var _skip: Button
var _tween: Tween


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_bubble = PanelContainer.new()
	_bubble.add_theme_stylebox_override(&"panel", Style.panel(Color.WHITE, 28))
	_bubble.custom_minimum_size = Vector2(BUBBLE_W, 0)
	add_child(_bubble)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 14)
	_bubble.add_child(box)
	var head := HBoxContainer.new()
	_title = Label.new()
	_title.add_theme_font_override(&"font", Style.bold())
	_title.add_theme_font_size_override(&"font_size", Style.HEAD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_count = Label.new()
	_count.modulate = Color(Style.INK, 0.55)
	head.add_child(_count)
	box.add_child(head)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(BUBBLE_W - 56, 0)
	box.add_child(_body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	_skip = _button(tr("TOUR_SKIP"), stop)
	_skip.flat = true
	row.add_child(_skip)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_prev = _button(tr("TOUR_PREV"), go.bind(-1))
	row.add_child(_prev)
	_next = _button(tr("TOUR_NEXT"), go.bind(1))
	_next.theme_type_variation = &"AccentButton"
	row.add_child(_next)
	box.add_child(row)
	resized.connect(func() -> void:
		if visible:
			_show(false))


func _button(text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(150, 64)
	b.pressed.connect(on_pressed)
	return b


func start(list: Array[Dictionary]) -> void:
	steps = list.filter(func(s: Dictionary) -> bool: return is_instance_valid(s.target) and s.target.is_visible_in_tree())
	if steps.is_empty():
		return
	index = 0
	visible = true
	move_to_front()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_show(false)


func is_active() -> bool:
	return visible


func go(delta: int) -> void:
	var to := index + delta
	if to >= steps.size():
		stop()
		return
	index = clampi(to, 0, steps.size() - 1)
	_show(true)


func stop() -> void:
	if not visible:
		return
	visible = false
	finished.emit()


func current() -> Dictionary:
	return steps[index] if visible else {}


func _show(animate: bool) -> void:
	var s := steps[index]
	_title.text = s.title
	_body.text = s.body
	_count.text = "%d / %d" % [index + 1, steps.size()]
	_prev.disabled = index == 0
	_next.text = tr("TOUR_DONE" if index == steps.size() - 1 else "TOUR_NEXT")
	_next.grab_focus()
	var c: Control = s.target
	var to := Rect2(c.get_global_rect().position - global_position, c.get_global_rect().size).grow(PAD)
	if _tween != null:
		_tween.kill()
	if animate:
		_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_method(_set_hole, hole, to, MOVE_TIME)
	else:
		_set_hole(to)


func _set_hole(r: Rect2) -> void:
	hole = r
	_bubble.reset_size()
	_bubble.position = bubble_position(hole, _bubble.size, size)
	queue_redraw()


## 밝힌 곳 아래, 모자라면 위, 그것도 안 되면 옆에 말풍선을 둔다(화면 밖으로 안 나가게).
static func bubble_position(target: Rect2, bubble: Vector2, screen: Vector2) -> Vector2:
	var x := clampf(target.get_center().x - bubble.x / 2, GAP, screen.x - bubble.x - GAP)
	if target.end.y + GAP + bubble.y <= screen.y - GAP:
		return Vector2(x, target.end.y + GAP)
	if target.position.y - GAP - bubble.y >= GAP:
		return Vector2(x, target.position.y - GAP - bubble.y)
	var y := clampf(target.get_center().y - bubble.y / 2, GAP, screen.y - bubble.y - GAP)
	if target.position.x - GAP - bubble.x >= GAP:
		return Vector2(target.position.x - GAP - bubble.x, y)
	return Vector2(clampf(target.end.x + GAP, GAP, screen.x - bubble.x - GAP), y)


func _draw() -> void:
	var shade := Color(0, 0, 0, 0.62)
	var r := hole.intersection(Rect2(Vector2.ZERO, size))
	draw_rect(Rect2(0, 0, size.x, r.position.y), shade)
	draw_rect(Rect2(0, r.end.y, size.x, size.y - r.end.y), shade)
	draw_rect(Rect2(0, r.position.y, r.position.x, r.size.y), shade)
	draw_rect(Rect2(r.end.x, r.position.y, size.x - r.end.x, r.size.y), shade)
	draw_style_box(Style.box(Color(0, 0, 0, 0), 16, Style.POSTIT, 5), hole)


func _gui_input(_event: InputEvent) -> void:
	accept_event()


func _owns_focus() -> bool:
	var f := get_viewport().gui_get_focus_owner()
	return f != null and is_ancestor_of(f)


## 안내 중에는 포커스가 말풍선 버튼 밖(뒤의 게임판)으로 나가지 않게 한다.
func _cycle_focus(step: int) -> void:
	var buttons := [_skip, _prev, _next].filter(func(b: Button) -> bool: return not b.disabled)
	var i := buttons.find(get_viewport().gui_get_focus_owner())
	(buttons[posmod(i + step, buttons.size()) if i >= 0 else buttons.size() - 1] as Button).grab_focus()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		stop()
	elif event.is_action_pressed(&"ui_focus_next") or event.is_action_pressed(&"ui_focus_prev") \
			or event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"ui_down"):
		_cycle_focus(-1 if event.is_action_pressed(&"ui_focus_prev") or event.is_action_pressed(&"ui_up") else 1)
	elif event.is_action_pressed(&"ui_accept") and not _owns_focus():
		go(1)
	elif event.is_action_pressed(&"ui_right"):
		go(1)
	elif event.is_action_pressed(&"ui_left"):
		go(-1)
	else:
		return
	get_viewport().set_input_as_handled()
