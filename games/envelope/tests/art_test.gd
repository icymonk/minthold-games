extends GdUnitTestSuite
## 3-1: 도형 그림과 코드 효과음.


func test_every_card_face_draws() -> void:
	for kind in Cards.DEFS:
		var b := Button.new()
		b.size = Vector2(150, 200)
		var face := CardFace.new(kind, tr(Cards.name_key(kind)), "x")
		b.add_child(face)
		add_child(b)
		face.size = b.size
		face.queue_redraw()
		await get_tree().process_frame
		assert_object(face).is_not_null()
		b.queue_free()


func test_portrait_draws_for_seats_and_cards() -> void:
	var p := Portrait.new(3, -1, 64)
	add_child(p)
	await get_tree().process_frame
	assert_vector(p.custom_minimum_size).is_equal(Vector2(64, 64))
	p.queue_free()


func test_band_colors_follow_camp() -> void:
	assert_object(Art.band(Cards.Id.THIEF)).is_equal(Style.STAMP)
	assert_object(Art.band(Cards.Id.BUDDY)).is_equal(Style.STAMP)
	assert_object(Art.band(Cards.Id.HR)).is_not_equal(Art.band(Cards.Id.BOSS))


func test_sounds_are_generated_and_respect_toggle() -> void:
	var before := Game.sound
	for id in [&"card", &"rustle", &"peel", &"stamp", &"turn", &"win", &"lose"]:
		var w: AudioStreamWAV = Sfx.streams[id]
		assert_int(w.data.size()).is_greater(1000)
	Game.sound = false
	assert_bool(Sfx.play(&"card")).is_false()
	Game.sound = true
	assert_bool(Sfx.play(&"card")).is_true()
	assert_bool(Sfx.play(&"nope")).is_false()
	Game.sound = before


func test_sound_setting_persists() -> void:
	var before_path := Game.settings_path
	var before := Game.sound
	Game.settings_path = "user://test_sound.cfg"
	Game.set_sound(false)
	Game.sound = true
	Game.load_settings()
	assert_bool(Game.sound).is_false()
	DirAccess.remove_absolute(Game.settings_path)
	Game.load_settings()
	assert_bool(Game.sound).is_true()
	Game.settings_path = before_path
	Game.load_settings()
	Game.sound = before
