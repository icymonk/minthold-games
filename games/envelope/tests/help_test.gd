extends GdUnitTestSuite

const TABLE := preload("res://scenes/screens/table.tscn")
const SETTINGS := "user://test_settings.cfg"


func before_test() -> void:
	Game.settings_path = SETTINGS
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	Game.load_settings()


func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	Game.settings_path = Game.SETTINGS
	Game.seen_intro = true


func test_every_card_has_ability_and_win_text_in_both_languages() -> void:
	for locale in ["ko", "en"]:
		var tr_obj := TranslationServer.get_translation_object(locale)
		for id in Cards.DEFS:
			for key in ["ABILITY_%s" % Cards.DEFS[id].key, "WIN_%s" % Cards.Win.keys()[Cards.win(id)], Cards.name_key(id)]:
				assert_str(String(tr_obj.get_message(key))).override_failure_message("%s %s" % [locale, key]).is_not_empty()
		for key in ["HELP_FIRST", "HELP_RULES", "HELP_CARD_META", "HELP_TAB_FIRST", "HELP_TAB_RULES", "HELP_TAB_CARDS"]:
			assert_str(String(tr_obj.get_message(key))).override_failure_message("%s %s" % [locale, key]).is_not_empty()


func test_card_dictionary_lists_all_cards_with_deck_counts() -> void:
	Game.players = 3
	var h: HelpPanel = auto_free(HelpPanel.new())
	add_child(h)
	h.open(&"CARDS")
	assert_int(h._body.get_child_count()).is_equal(Cards.DEFS.size())
	assert_str(HelpPanel.card_meta(Cards.Id.ACCOUNTANT)).contains("%d" % Cards.deck(3).count(Cards.Id.ACCOUNTANT))
	h.close()
	assert_bool(h.visible).is_false()


func test_first_game_guide_shows_once() -> void:
	assert_bool(Game.seen_intro).is_false()
	Game.players = 4
	Game.rng = RngStreams.new(2)
	var t: Control = auto_free(TABLE.instantiate())
	add_child(t)
	assert_bool(t.help.visible).is_true()
	assert_str(t.help.tab).is_equal(&"FIRST")
	t._timer.stop()
	remove_child(t)
	Game.seen_intro = false
	Game.load_settings()
	assert_bool(Game.seen_intro).is_true()
	Game.rng = RngStreams.new(2)
	var again: Control = auto_free(TABLE.instantiate())
	add_child(again)
	assert_bool(again.help.visible).is_false()
	again._timer.stop()
	remove_child(again)


func test_ai_waits_while_help_is_open() -> void:
	Game.seen_intro = true
	Game.players = 5
	Game.rng = RngStreams.new(3)
	var t: Control = auto_free(TABLE.instantiate())
	add_child(t)
	t._timer.stop()
	var me := Bot.new(0, RandomNumberGenerator.new(), Bot.Persona.CAREFUL)
	while t.session.waiting_for_human():
		if t.session.m.pending.is_empty():
			t.session.play(me.choose_move(t.session.view(), t.session.m.legal_moves(0)))
		else:
			t.session.answer(me.choose_answer(t.session.view()))
	t.help.open()
	var before: int = t.session.events.size()
	t._on_tick()
	assert_int(t.session.events.size()).is_equal(before)
	t.help.close()
	t._on_tick()
	assert_int(t.session.events.size()).is_greater(before)
	t._timer.stop()
	remove_child(t)
