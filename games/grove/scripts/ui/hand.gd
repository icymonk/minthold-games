class_name Hand
extends Control
## 손패. 카드를 끌어 숲 위에 가져가면 붙일 자리가 빛나고, 가까운 자리에 반투명 미리 보기가 선다.
## 들고 있는 동안 오른쪽 클릭·휠·Tab으로 쓸 반쪽을 바꾼다. 놓으면 카드가 빛 조각으로 흩어진다.

signal drag_started(card: Dictionary)
signal played(card: Dictionary, target: Dictionary)

const HAND_SIZE := 5

var world: ForestView
var cards: Array[CardView] = []
var portraits: Portrait
var _rng := RandomNumberGenerator.new()
var _drag: CardView
var _float: CardView
var _targets: Array[Dictionary] = []
var _target := {}


func _ready() -> void:
	_rng.seed = 7
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y = CardView.CARD.y
	portraits = Portrait.new()
	add_child(portraits)
	resized.connect(_layout)
	for c in DemoCards.starting_hand():
		add_card(c)


func add_card(c: Dictionary) -> CardView:
	var v := CardView.make(c, portraits)
	v.gui_input.connect(_on_card_input.bind(v))
	v.mouse_entered.connect(_hover.bind(v, true))
	v.mouse_exited.connect(_hover.bind(v, false))
	add_child(v)
	v.position = Vector2(size.x + 200, 0)
	cards.append(v)
	_layout()
	return v


## 카드 사이 간격을 맞추고 부채꼴로 살짝 기울인다.
func _layout() -> void:
	var n := cards.size()
	if n == 0:
		return
	var step := minf(CardView.CARD.x + 20.0, (size.x - CardView.CARD.x) / maxf(n - 1, 1))
	var x0 := (size.x - (step * (n - 1) + CardView.CARD.x)) / 2.0
	for i in n:
		var mid := i - (n - 1) / 2.0
		var v := cards[i]
		var tw := v.create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(v, ^"position", Vector2(x0 + i * step, absf(mid) * absf(mid) * 6.0), 0.3)
		tw.tween_property(v, ^"rotation", mid * 0.035, 0.3)


func _hover(v: CardView, on: bool) -> void:
	if _drag or not v in cards:
		return
	v.z_index = 1 if on else 0
	v.create_tween().tween_property(v, ^"scale", Vector2.ONE * (1.08 if on else 1.0), 0.12)


func _on_card_input(event: InputEvent, v: CardView) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and not _drag:
		begin_drag(v, v.half_at(mb.position))
		accept_event()


func _input(event: InputEvent) -> void:
	if not _drag:
		return
	if event is InputEventMouseMotion:
		move_drag(get_global_mouse_position())
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		flip()
		get_viewport().set_input_as_handled()
	elif mb and not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		end_drag()
		get_viewport().set_input_as_handled()
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode in [KEY_TAB, KEY_SPACE]:
		flip()
		get_viewport().set_input_as_handled()


func dragging() -> bool:
	return _drag != null


## 카드를 든다. 붙일 곳이 하나도 없으면 빨갛게 떨고 들지 않는다.
func begin_drag(v: CardView, half := 0) -> bool:
	v.set_half(half)
	_targets = world.targets_for(v.kind(), v.side())
	if _targets.is_empty() and not DemoCards.is_tree(v.card):
		v.set_half(1 - half)
		_targets = world.targets_for(v.kind(), v.side())
	if _targets.is_empty():
		v.shake()
		return false
	Sfx.play(&"click")
	_drag = v
	v.scale = Vector2.ONE
	v.modulate.a = 0.25
	_float = CardView.make(v.card, portraits)
	_float.set_half(v.half)
	_float.top_level = true
	_float.z_index = 10
	_float.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_float)
	_float.global_position = v.global_position
	_target = {}
	world.show_targets(_targets)
	drag_started.emit(v.card)
	move_drag(get_global_mouse_position())
	return true


func move_drag(at: Vector2) -> void:
	if not _float:
		return
	_float.global_position = at - CardView.CARD / 2.0
	var t := world.nearest(_targets, at)
	if t == _target:
		return
	_target = t
	world.preview(t, _drag.kind())
	var tw := _float.create_tween().set_parallel()
	tw.tween_property(_float, ^"scale", Vector2.ONE * (0.5 if not t.is_empty() else 0.85), 0.12)
	tw.tween_property(_float, ^"modulate:a", 0.55 if not t.is_empty() else 1.0, 0.12)


## 쓸 반쪽 바꾸기
func flip() -> void:
	if not _drag or DemoCards.is_tree(_drag.card):
		return
	_drag.set_half(1 - _drag.half)
	_float.set_half(_drag.half)
	_targets = world.targets_for(_drag.kind(), _drag.side())
	world.show_targets(_targets)
	if _targets.is_empty():
		_float.shake()
	_target = {"_": true}
	move_drag(get_global_mouse_position())


func end_drag() -> void:
	if not _drag:
		return
	var v := _drag
	var f := _float
	_drag = null
	_float = null
	if _target.has("plot"):
		var kind := v.kind()
		var target := _target
		cards.erase(v)
		v.queue_free()
		_shatter(f)
		world.place(target, kind)
		played.emit(v.card, target)
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			if is_inside_tree():
				add_card(DemoCards.deal(_rng)))
		_layout()
	else:
		world.clear_targets()
		var tw := f.create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(f, ^"global_position", v.global_position, 0.2)
		tw.tween_property(f, ^"scale", Vector2.ONE, 0.2)
		tw.chain().tween_callback(f.queue_free)
		tw.chain().tween_callback(func() -> void: v.modulate.a = 1.0)
	_target = {}


## 카드가 노을빛 조각으로 흩어진다.
func _shatter(f: CardView) -> void:
	var p := CPUParticles2D.new()
	p.top_level = true
	p.z_index = 11
	p.global_position = f.global_position + CardView.CARD * f.scale / 2.0
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 48
	p.lifetime = 0.7
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = CardView.CARD * f.scale / 2.0
	p.spread = 180.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 380.0
	p.gravity = Vector2(0, -200)
	p.scale_amount_min = 6.0
	p.scale_amount_max = 14.0
	var g := Gradient.new()
	g.colors = PackedColorArray([Style.CREAM, Style.SUNSET, Color(Style.SUNSET, 0.0)])
	p.color_ramp = g
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	var tw := f.create_tween().set_parallel()
	tw.tween_property(f, ^"scale", f.scale * 1.3, 0.18)
	tw.tween_property(f, ^"modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(f.queue_free)


## Coach 구멍용: 조건에 맞는 첫 카드의 화면 사각형
func card_rect(pick: Callable) -> Rect2:
	for v in cards:
		if pick.call(v.card):
			return v.get_global_rect()
	return Rect2()
