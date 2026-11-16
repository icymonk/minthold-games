extends GdUnitTestSuite

const TABLE := preload("res://scenes/screens/table.tscn")
const PATH := "user://test_records.cfg"

var _path: String


func before_test() -> void:
	_path = Game.records_path
	Game.records_path = PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	Game.load_records()
	Game.league = null
	Game.seen_intro = true


func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	Game.records_path = _path
	Game.load_records()
	Game.league = null


func _result(roles: Array, winners: Array, priority: int) -> Dictionary:
	return { roles = roles, winners = winners, priority = priority }


func test_points_grow_with_earlier_priority() -> void:
	var C := Cards.Id
	assert_int(League.points(_result([C.NEWBIE, C.CHAIR], [0], 1), 0)).is_equal(5)
	assert_int(League.points(_result([C.CHAIR, C.MISER], [0], 4), 0)).is_equal(2)
	assert_int(League.points(_result([C.CHAIR, C.MISER], [1], 3), 0)).is_equal(0)


func test_league_ends_after_five_games_and_keeps_best() -> void:
	var C := Cards.Id
	Game.league = League.new()
	for i in League.GAMES:
		assert_bool(Game.league.done()).is_false()
		Game.record(_result([C.CHAIR, C.MISER], [0] if i % 2 == 0 else [1], 4 if i % 2 == 0 else 3), 0)
		assert_int(Game.records.best).is_equal(0 if i < League.GAMES - 1 else 6)
	assert_bool(Game.league.done()).is_true()
	assert_int(Game.league.total()).is_equal(6)
	Game.league = League.new()
	for i in League.GAMES:
		Game.record(_result([C.CHAIR, C.MISER], [1], 3), 0)
	assert_int(Game.records.best).is_equal(6)


func test_records_count_role_plays_and_wins_and_persist() -> void:
	var C := Cards.Id
	Game.record(_result([C.CHAIR, C.MISER], [0], 4), 0)
	Game.record(_result([C.CHAIR, C.MISER], [1], 3), 0)
	Game.record(_result([C.THIEF, C.MISER], [0], 2), 0)
	Game.records = {}
	Game.load_records()
	assert_int(Game.records.plays.CHAIR).is_equal(2)
	assert_int(Game.records.wins.CHAIR).is_equal(1)
	assert_int(Game.records.plays.THIEF).is_equal(1)
	assert_int(Game.records.wins.THIEF).is_equal(1)


func test_table_records_once_and_offers_next_league_game() -> void:
	Game.players = 4
	Game.rng = RngStreams.new(3)
	Game.league = League.new()
	var t: Control = auto_free(TABLE.instantiate())
	add_child(t)
	var me := Bot.new(Session.HUMAN, RandomNumberGenerator.new())
	var guard := 0
	while not t.session.is_over() and guard < 400:
		guard += 1
		if t.session.waiting_for_human():
			var k: Knowledge = t.session.view()
			if k.request.is_empty():
				t.session.play(me.choose_move(k, t.session.m.legal_moves(Session.HUMAN)))
			else:
				t.session.answer(me.choose_answer(k))
		else:
			t.session.ai_step()
	t.refresh()
	t.refresh()
	assert_int(Game.league.played()).is_equal(1)
	var plays := 0
	for key in Game.records.plays:
		plays += Game.records.plays[key]
	assert_int(plays).is_equal(1)
	t.result_step = t.get_script().RESULT_STEPS - 1
	t.refresh()
	var labels := PackedStringArray()
	var buttons := PackedStringArray()
	for n in t._overlay.find_children("*", "Label", true, false):
		labels.append((n as Label).text)
	for n in t._overlay.find_children("*", "Button", true, false):
		buttons.append((n as Button).text)
	assert_bool(labels.has(tr("LEAGUE_STATUS") % [1, League.GAMES, t.league_points, Game.league.total()])).is_true()
	assert_bool(buttons.has(tr("LEAGUE_NEXT"))).is_true()
	assert_bool(buttons.has(tr("RESULT_SAME_SEED"))).is_false()
	t._timer.stop()
	remove_child(t)


func test_records_screen_lists_played_roles() -> void:
	Game.record(_result([Cards.Id.CHAIR, Cards.Id.MISER], [0], 4), 0)
	var screen: Control = auto_free(preload("res://scenes/screens/records.tscn").instantiate())
	add_child(screen)
	var labels := PackedStringArray()
	for n in screen.find_children("*", "Label", true, false):
		labels.append((n as Label).text)
	assert_bool(labels.has(tr("RECORDS_ROW") % [tr("CARD_CHAIR"), 1, 1, 100])).is_true()
	remove_child(screen)
