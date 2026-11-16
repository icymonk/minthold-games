extends Control
## 1-2 당기기 화면: 식탁보 끝을 잡고 휙 끌면 PullSim 결과를 슬로모션과 와장창으로 보여 준다.

enum State { READY, DRAGGING, PULLING, DONE }

const SIZE := Vector2(1920, 1080)
## 1cm = 8px.
const S := 8.0
const TABLE_CM := 160.0
const TABLE_X := 200.0
const TABLE_Y := 690.0
const CLOTH_H := 9.0
## 식탁 오른쪽 끝에 늘어진 천 길이(cm).
const FLAP_CM := 26.0
const FLOOR_Y := 1050.0
const SLOW_MO := 0.3
const SAFE_SPEED := 700.0
const GAUGE_MAX := 1200.0
const SETUPS := [
	[[&"plate", 80.0]],
	[[&"plate", 50.0], [&"wine_glass", 100.0]],
	[[&"soup_bowl", 40.0], [&"mug", 75.0], [&"wine_glass", 110.0]],
	[[&"plate", 30.0], [&"cake", 70.0], [&"wine_bottle", 106.0], [&"jelly", 132.0]],
	[[&"vase", 22.0], [&"plate", 55.0], [&"wine_glass", 86.0], [&"mug", 112.0], [&"cake", 140.0]],
]
const SHARD_COLORS := {
	&"plate": Color("#F4EFE6"), &"soup_bowl": Color("#F4EFE6"), &"mug": Color("#C9774A"),
	&"wine_glass": Color(0.85, 0.93, 1.0, 0.8), &"wine_bottle": Color("#7A1E2C"), &"vase": Color("#F2C58E"),
	&"cake": Color("#F6B8C8"), &"jelly": Color("#E9964A"),
}
const GLASS := [&"wine_glass", &"wine_bottle"]
const SOFT := [&"cake", &"jelly"]
const ROOM := preload("res://assets/art/room.jpg")
const CHAIR := preload("res://assets/art/chair.png")
const HAND := preload("res://assets/art/kenney/hand.svg")
const SFX := {
	&"glass_break": preload("res://assets/sfx/glass_break.ogg"),
	&"glass_clink": preload("res://assets/sfx/glass_clink.ogg"),
	&"plate_break": preload("res://assets/sfx/plate_break.ogg"),
	&"plate_clink": preload("res://assets/sfx/plate_clink.ogg"),
	&"thud": preload("res://assets/sfx/thud.ogg"),
	&"knock": preload("res://assets/sfx/table_knock.ogg"),
	&"pick": preload("res://assets/sfx/pick.ogg"),
	&"chime": preload("res://assets/sfx/chime.ogg"),
	&"error": preload("res://assets/sfx/error.ogg"),
	&"whoosh": preload("res://assets/sfx/whoosh.ogg"),
}

var state := State.READY
var setup_index := 0
var dishes: Array[Dish] = []
var results: Array[PullSim.Result] = []

var _sim := PullSim.new(TABLE_CM)
var _flick := Flick.new()
var _fx := RandomNumberGenerator.new()
var _stage: Node2D
var _cloth: Node2D
var _sprites: Array[Sprite2D] = []
var _props: Node2D
var _hand: Sprite2D
var _hand_tween: Tween
var _gauge: Control
var _gauge_value := 0.0
var _title: Label
var _sub: Label
var _setup_label: Label
var _buttons: HBoxContainer
var _drag_pos := Vector2.ZERO
var _pulls := 0
var _tag_spots: Array[Vector2] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_scene()
	_build_ui()
	resized.connect(_layout)
	_layout()
	lay_table(0)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func lay_table(index: int) -> void:
	setup_index = index % SETUPS.size()
	state = State.READY
	results.clear()
	dishes.clear()
	_tag_spots.clear()
	_gauge.visible = true
	for s in _sprites:
		s.queue_free()
	_sprites.clear()
	for c in _props.get_children():
		c.queue_free()
	for spec: Array in SETUPS[setup_index]:
		var d := Dish.new(spec[0], spec[1])
		dishes.append(d)
		_sprites.append(_dish_sprite(d))
	_cloth.position = Vector2(TABLE_X, TABLE_Y)
	_cloth.queue_redraw()
	_gauge_value = 0.0
	_gauge.queue_redraw()
	_title.text = tr("PULL_HINT")
	_title.modulate = Style.LINEN
	_title.scale = Vector2.ONE
	_sub.text = tr("PULL_TIP")
	_setup_label.text = tr("PULL_SETUP") % [setup_index + 1, SETUPS.size()]
	_buttons.visible = false
	_show_hand(_pulls == 0)


func _process(_delta: float) -> void:
	if state == State.READY:
		_cloth.queue_redraw()


# --- 입력 -------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	if state == State.READY and motion:
		mouse_default_cursor_shape = Control.CURSOR_DRAG if _grab_rect().has_point(_to_stage(motion.position)) else Control.CURSOR_ARROW
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed and state == State.READY and _grab_rect().has_point(_to_stage(button.position)):
			state = State.DRAGGING
			_flick.begin(button.position, _now())
			_drag_pos = _to_stage(button.position)
			_show_hand(false)
			_sfx(&"pick")
		elif not button.pressed and state == State.DRAGGING:
			_flick.move(button.position, _now())
			if _flick.offset().length() >= Flick.MIN_TUG:
				pull(_flick.to_pull())
			else:
				state = State.READY
				_cloth.queue_redraw()
	elif motion and state == State.DRAGGING:
		_flick.move(motion.position, _now())
		_drag_pos = _to_stage(motion.position)
		_gauge_value = _flick.speed_px() * Flick.GAIN
		_gauge.queue_redraw()
		_cloth.queue_redraw()
		if _flick.committed():
			pull(_flick.to_pull())


func _grab_rect() -> Rect2:
	var edge := TABLE_X + TABLE_CM * S
	return Rect2(edge - 40, TABLE_Y - 30, 130, FLAP_CM * S + 90)


func _to_stage(p: Vector2) -> Vector2:
	return p - _stage.position


func _now() -> float:
	return Time.get_ticks_usec() / 1000000.0


# --- 당기기 -----------------------------------------------------------

func pull(p: PullSim.Pull) -> void:
	state = State.PULLING
	_pulls += 1
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	results = _sim.run(dishes, p)
	_gauge_value = p.speed
	_gauge.queue_redraw()
	_title.text = ""
	_sub.text = tr("PULL_STATS") % [roundi(p.speed), roundi(p.angle), roundi(p.wobble * 100.0)]
	Engine.time_scale = SLOW_MO if p.speed >= 450.0 else 1.0
	_sfx(&"whoosh")
	var cloth_time := (TABLE_CM + FLAP_CM + 120.0) / maxf(p.speed, 60.0)
	var cloth_tw := create_tween()
	cloth_tw.tween_property(_cloth, ^"position:x", _cloth.position.x + (TABLE_CM + FLAP_CM + 120.0) * S, cloth_time)
	_cloth.queue_redraw()
	var longest := cloth_time
	for i in results.size():
		var r := results[i]
		var grip := r.dish.grip * (1.0 + p.wobble)
		var contact := r.dish.right() / maxf(p.speed, 1.0)
		var stop := grip * contact / PullSim.TABLE_GRIP
		var t := clampf(contact + stop, 0.05, 2.5)
		longest = maxf(longest, t)
		if r.slide > 0.05:
			var tw := create_tween()
			tw.tween_property(_sprites[i], ^"position:x", _x(minf(r.final_x, TABLE_CM + r.dish.width * 0.3)), t).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(longest + 0.1).timeout
	Engine.time_scale = 1.0
	var breaks := 0
	for i in results.size():
		var r := results[i]
		match r.outcome:
			PullSim.Outcome.FELL:
				breaks += 1
				_fall(_sprites[i], r, i * 0.08)
			PullSim.Outcome.TIPPED:
				breaks += 1
				_tip(_sprites[i], r, i * 0.08)
			_:
				_settle(_sprites[i], r)
	await get_tree().create_timer(1.1 if breaks > 0 else 0.5).timeout
	_finish()


func _finish() -> void:
	state = State.DONE
	var stayed := results.filter(func(r: PullSim.Result) -> bool: return r.outcome == PullSim.Outcome.STAYED).size()
	if stayed == results.size():
		_title.text = tr("PULL_CLEAN")
		_title.modulate = Style.CANDLE
		_sfx(&"chime")
		_confetti()
	else:
		_title.text = tr("PULL_CRASH") % [stayed, results.size()]
		_title.modulate = Style.CRASH
		_sfx(&"error")
	_title.pivot_offset = _title.size / 2.0
	_title.scale = Vector2(1.6, 1.6)
	create_tween().tween_property(_title, ^"scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_buttons.visible = true
	_gauge.visible = false
	(_buttons.get_child(1) as Button).grab_focus()


func _fall(sprite: Sprite2D, r: PullSim.Result, delay: float) -> void:
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(sprite, ^"position:x", _x(TABLE_CM) + r.dish.width * S * 0.5, 0.12)
	tw.tween_callback(_sfx.bind(&"knock"))
	tw.set_parallel()
	tw.tween_property(sprite, ^"position", Vector2(_x(TABLE_CM) + 90.0 + _fx.randf_range(0, 120), FLOOR_Y + 10), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(sprite, ^"rotation", _fx.randf_range(1.6, 2.8), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(_smash.bind(sprite, r, true))


func _tip(sprite: Sprite2D, r: PullSim.Result, delay: float) -> void:
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(sprite, ^"rotation", -0.25, 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sprite, ^"rotation", -PI / 2.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_smash.bind(sprite, r, r.dish.kind in GLASS))


func _settle(sprite: Sprite2D, r: PullSim.Result) -> void:
	var lean := 0.04 + r.tip * 0.25
	var tw := create_tween()
	tw.tween_property(sprite, ^"rotation", -lean, 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sprite, ^"rotation", lean * 0.4, 0.22 + r.tip * 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sprite, ^"rotation", 0.0, 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_sfx.bind(&"glass_clink" if r.dish.kind in GLASS else &"plate_clink", 0.4))
	var tag := ""
	if r.miracle():
		tag = tr("TAG_MIRACLE")
	elif _sim.near_edge(r):
		tag = tr("TAG_NEAR_EDGE")
	elif r.perfect():
		tag = tr("TAG_PERFECT")
	if tag != "":
		_tag(tag, sprite, Style.CANDLE)


func _smash(sprite: Sprite2D, r: PullSim.Result, breaks: bool) -> void:
	var kind := r.dish.kind
	_shake(18.0 if breaks else 8.0)
	if not breaks:
		_sfx(&"thud" if kind in SOFT else &"plate_clink")
		_tag(tr("TAG_TIPPED"), sprite, Style.CRASH)
		return
	_sfx(&"thud" if kind in SOFT else (&"glass_break" if kind in GLASS else &"plate_break"))
	_tag(tr("TAG_BROKEN"), sprite, Style.CRASH)
	var at := sprite.position + Vector2(0, -8)
	sprite.visible = false
	var color: Color = SHARD_COLORS.get(kind, Style.LINEN)
	for i in 14:
		var shard := Polygon2D.new()
		var size := _fx.randf_range(8, 22)
		shard.polygon = PackedVector2Array([Vector2(-size, 0), Vector2(size * 0.4, -size * 0.8), Vector2(size * 0.7, size * 0.5)])
		shard.color = color.darkened(_fx.randf_range(0, 0.3))
		shard.position = at
		_props.add_child(shard)
		var floor_y := FLOOR_Y + _fx.randf_range(-20, 25) if r.outcome == PullSim.Outcome.FELL else TABLE_Y + _fx.randf_range(-6, 4)
		var land := Vector2(at.x + _fx.randf_range(-160, 160), floor_y)
		var t := _fx.randf_range(0.35, 0.6)
		var tw := shard.create_tween().set_parallel()
		tw.tween_property(shard, ^"position:x", land.x, t)
		tw.tween_property(shard, ^"position:y", at.y - _fx.randf_range(60, 200), t * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.chain().tween_property(shard, ^"position:y", land.y, t * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(shard, ^"rotation", _fx.randf_range(-8, 8), t)


# --- 연출 -------------------------------------------------------------

func _shake(power: float) -> void:
	var base := _stage_origin()
	var tw := create_tween()
	for i in 6:
		tw.tween_property(_stage, ^"position", base + Vector2(_fx.randf_range(-power, power), _fx.randf_range(-power, power)) * (1.0 - i / 6.0), 0.035)
	tw.tween_property(_stage, ^"position", base, 0.04)


func _tag(text: String, sprite: Sprite2D, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override(&"font", Style.bold())
	label.add_theme_font_size_override(&"font_size", 40)
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_outline_color", Style.NIGHT_DEEP)
	label.add_theme_constant_override(&"outline_size", 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(300, 60)
	var top := minf(sprite.position.y - sprite.texture.get_height() * sprite.scale.y, TABLE_Y - 80.0)
	label.position = Vector2(clampf(sprite.position.x, 150, SIZE.x - 150) - 150, top - 70)
	for spot in _tag_spots:
		if absf(spot.x - label.position.x) < 260 and absf(spot.y - label.position.y) < 70:
			label.position.y = spot.y - 70
	_tag_spots.append(label.position)
	_props.add_child(label)
	var tw := label.create_tween()
	tw.tween_property(label, ^"position:y", label.position.y - 40, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _confetti() -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(SIZE.x / 2.0, -20)
	p.amount = 160
	p.one_shot = true
	p.explosiveness = 0.85
	p.lifetime = 2.2
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(SIZE.x / 2.0, 10)
	p.direction = Vector2.DOWN
	p.spread = 30
	p.initial_velocity_min = 200
	p.initial_velocity_max = 520
	p.gravity = Vector2(0, 420)
	p.angular_velocity_min = -360
	p.angular_velocity_max = 360
	p.scale_amount_min = 6
	p.scale_amount_max = 12
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Style.CANDLE, Style.WINE, Style.LINEN, Color("#6FC3A8")])
	ramp.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	p.color_initial_ramp = ramp
	p.emitting = true
	_props.add_child(p)


func _show_hand(on: bool) -> void:
	if _hand_tween:
		_hand_tween.kill()
	_hand.visible = on
	if not on:
		return
	var from := Vector2(TABLE_X + TABLE_CM * S + 14, TABLE_Y + FLAP_CM * S - 10)
	_hand.position = from
	_hand_tween = create_tween().set_loops()
	_hand_tween.tween_property(_hand, ^"modulate:a", 1.0, 0.2).from(0.0)
	_hand_tween.tween_interval(0.35)
	_hand_tween.tween_property(_hand, ^"position", from + Vector2(260, -30), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_hand_tween.tween_property(_hand, ^"modulate:a", 0.0, 0.2)
	_hand_tween.tween_property(_hand, ^"position", from, 0.0)
	_hand_tween.tween_interval(0.5)


func _sfx(key: StringName, volume := 1.0) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = SFX[key]
	player.volume_db = linear_to_db(volume)
	player.pitch_scale = _fx.randf_range(0.92, 1.08)
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


# --- 그리기 -----------------------------------------------------------

func _build_scene() -> void:
	var bg := TextureRect.new()
	var room := AtlasTexture.new()
	room.atlas = ROOM
	room.region = Rect2(0, 48, ROOM.get_width(), ROOM.get_height() - 48)
	bg.texture = room
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.5, 0.42, 0.45)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var shade := TextureRect.new()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0, 0, 0, 0), Color(Style.NIGHT_DEEP, 0.85)])
	var vignette := GradientTexture2D.new()
	vignette.gradient = grad
	vignette.fill = GradientTexture2D.FILL_RADIAL
	vignette.fill_from = Vector2(0.5, 0.55)
	vignette.fill_to = Vector2(1.1, 1.1)
	shade.texture = vignette
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_stage = Node2D.new()
	add_child(_stage)
	var glow_grad := Gradient.new()
	glow_grad.colors = PackedColorArray([Color(Style.CANDLE, 0.35), Color(Style.CANDLE, 0.0)])
	var glow_tex := GradientTexture2D.new()
	glow_tex.gradient = glow_grad
	glow_tex.fill = GradientTexture2D.FILL_RADIAL
	glow_tex.fill_from = Vector2(0.5, 0.5)
	glow_tex.fill_to = Vector2(1.0, 0.5)
	glow_tex.width = 512
	glow_tex.height = 512
	var glow := Sprite2D.new()
	glow.texture = glow_tex
	glow.scale = Vector2(3.2, 1.6)
	glow.position = Vector2(_x(TABLE_CM / 2.0), TABLE_Y - 60)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = add
	_stage.add_child(glow)
	var chair := Sprite2D.new()
	chair.texture = CHAIR
	chair.centered = false
	chair.scale = Vector2.ONE * 560.0 / CHAIR.get_height()
	chair.position = Vector2(TABLE_X - 200, SIZE.y - 560)
	chair.modulate = Color(0.7, 0.6, 0.6)
	_stage.add_child(chair)
	var table := Node2D.new()
	table.draw.connect(_draw_table.bind(table))
	_stage.add_child(table)
	_cloth = Node2D.new()
	_cloth.draw.connect(_draw_cloth)
	_stage.add_child(_cloth)
	_props = Node2D.new()
	_stage.add_child(_props)
	_hand = Sprite2D.new()
	_hand.texture = HAND
	_hand.centered = false
	_hand.offset = Vector2(-14.4, -2)
	_hand.scale = Vector2(3, 3)
	_stage.add_child(_hand)


func _dish_sprite(d: Dish) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/art/%s.png" % d.kind)
	var w := float(sprite.texture.get_width())
	sprite.centered = false
	sprite.offset = Vector2(-w / 2.0, -sprite.texture.get_height() + 2)
	sprite.scale = Vector2.ONE * d.width * S / w
	sprite.position = Vector2(_x(d.x), TABLE_Y)
	_stage.add_child(sprite)
	_stage.move_child(sprite, _props.get_index())
	return sprite


func _x(cm: float) -> float:
	return TABLE_X + cm * S


## 짙은 원목 식탁: 상판, 앞판, 다리 둘.
func _draw_table(ci: Node2D) -> void:
	var top := TABLE_Y + CLOTH_H
	var left := TABLE_X - 14
	var width := TABLE_CM * S + 28
	var wood := Color("#7A4A2B")
	ci.draw_rect(Rect2(left + 30, FLOOR_Y - 6, width - 60, 18), Color(0, 0, 0, 0.35))
	for lx: float in [left + 40, left + width - 96]:
		ci.draw_rect(Rect2(lx, top + 30, 56, FLOOR_Y - top - 30), wood.darkened(0.35))
		ci.draw_rect(Rect2(lx + 6, top + 30, 12, FLOOR_Y - top - 30), Color(1, 1, 1, 0.06))
	ci.draw_rect(Rect2(left + 30, top + 30, width - 60, 46), wood.darkened(0.2))
	ci.draw_rect(Rect2(left + 30, top + 70, width - 60, 6), Color(0, 0, 0, 0.25))
	ci.draw_rect(Rect2(left, top, width, 32), wood)
	ci.draw_rect(Rect2(left, top, width, 6), wood.lightened(0.25))
	ci.draw_rect(Rect2(left, top + 26, width, 6), wood.darkened(0.3))


func _draw_cloth() -> void:
	var l := TABLE_CM * S
	if state == State.PULLING or state == State.DONE:
		_band(Rect2(0, 0, l + FLAP_CM * S, CLOTH_H))
		return
	_band(Rect2(0, 0, l, CLOTH_H))
	var tip := Vector2(l + 12, FLAP_CM * S)
	if state == State.DRAGGING:
		tip = _drag_pos - _cloth.position
	var pts := PackedVector2Array([Vector2(l - 6, CLOTH_H * 0.5), Vector2(l + 8, CLOTH_H + 6), tip])
	_cloth.draw_polyline(pts, Style.WINE.darkened(0.25), 30, true)
	_cloth.draw_polyline(pts, Style.WINE, 22, true)
	_cloth.draw_polyline(pts, Color(1, 1, 1, 0.15), 6, true)
	if state == State.READY:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 180.0)
		_cloth.draw_circle(tip, 26 + pulse * 10, Color(Style.CANDLE, 0.25 + pulse * 0.2))
		_cloth.draw_circle(tip, 14, Style.CANDLE)


func _band(rect: Rect2) -> void:
	_cloth.draw_rect(rect, Style.WINE)
	var x := rect.position.x
	while x < rect.end.x:
		_cloth.draw_rect(Rect2(x, rect.position.y, minf(14, rect.end.x - x), rect.size.y), Color(1, 1, 1, 0.16))
		x += 28
	_cloth.draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2)), Color(1, 1, 1, 0.25))


func _build_ui() -> void:
	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.position = Vector2(-700, 60)
	top.custom_minimum_size = Vector2(1400, 0)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	_title = _make_label(64)
	top.add_child(_title)
	_sub = _make_label(30)
	_sub.modulate = Color(Style.LINEN, 0.8)
	top.add_child(_sub)
	_setup_label = _make_label(26)
	_setup_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_setup_label.position = Vector2(40, 30)
	_setup_label.modulate = Style.CANDLE
	add_child(_setup_label)
	_gauge = Control.new()
	_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge.draw.connect(_draw_gauge)
	add_child(_gauge)
	_buttons = HBoxContainer.new()
	_buttons.add_theme_constant_override(&"separation", 24)
	_buttons.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_buttons.position = Vector2(-460, -150)
	add_child(_buttons)
	for spec: Array in [["BACK_TO_TITLE", func() -> void: Game.goto(&"title")], ["PULL_RETRY", func() -> void: lay_table(setup_index)], ["PULL_NEXT", func() -> void: lay_table(setup_index + 1)]]:
		var b := Button.new()
		b.text = tr(spec[0])
		b.custom_minimum_size = Vector2(290, 76)
		b.add_theme_font_size_override(&"font_size", 28)
		b.pressed.connect(spec[1])
		_buttons.add_child(b)
	(_buttons.get_child(2) as Button).theme_type_variation = &"AccentButton"


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override(&"font", Style.bold())
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_outline_color", Style.NIGHT_DEEP)
	label.add_theme_constant_override(&"outline_size", 10)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## 오른쪽 위 속도 막대. 초록 칸까지 차면 안전하다.
func _draw_gauge() -> void:
	var rect := Rect2(0, 0, 360, 26)
	var safe := rect.size.x * SAFE_SPEED / GAUGE_MAX
	var font := Style.bold()
	_gauge.draw_string(font, Vector2(0, -14), tr("PULL_GAUGE"), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Style.LINEN)
	_gauge.draw_rect(rect.grow(4), Style.NIGHT_DEEP)
	_gauge.draw_rect(Rect2(0, 0, safe, rect.size.y), Color(Style.CRASH, 0.35))
	_gauge.draw_rect(Rect2(safe, 0, rect.size.x - safe, rect.size.y), Color("#6FC3A8", 0.35))
	var fill := clampf(_gauge_value / GAUGE_MAX, 0.0, 1.0) * rect.size.x
	_gauge.draw_rect(Rect2(0, 0, fill, rect.size.y), Style.CRASH.lerp(Color("#6FC3A8"), clampf(_gauge_value / SAFE_SPEED, 0, 1)))
	_gauge.draw_line(Vector2(safe, -6), Vector2(safe, rect.size.y + 6), Style.LINEN, 3)
	_gauge.draw_string(font, Vector2(0, rect.size.y + 32), tr("PULL_GAUGE_SLOW"), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(Style.LINEN, 0.7))
	_gauge.draw_string(font, Vector2(safe + 8, rect.size.y + 32), tr("PULL_GAUGE_FAST"), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#6FC3A8"))


func _stage_origin() -> Vector2:
	return ((size - SIZE) / 2.0).floor()


func _layout() -> void:
	_stage.position = _stage_origin()
	_gauge.position = _stage.position + Vector2(TABLE_X + TABLE_CM * S + 30, TABLE_Y - 230)
	_gauge.size = Vector2(360, 60)
