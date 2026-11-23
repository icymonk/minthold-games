extends GdUnitTestSuite


func test_six_entrances_are_all_used() -> void:
	var seen := {Dweller.Entrance.TREE: true}
	for k in Dweller.KINDS:
		seen[Dweller.KINDS[k].entrance] = true
	assert_int(seen.size()).is_equal(Dweller.Entrance.size())


func test_every_kind_builds_and_fits_a_socket() -> void:
	for k in Dweller.KINDS:
		var d: Dweller = auto_free(Dweller.make(k))
		assert_object(d.get_node("Body/Model")).is_not_null()
		for side in Dweller.KINDS[k].sides:
			assert_bool(side in ForestTree.SOCKETS).is_true()


func test_every_side_has_neighbors() -> void:
	for side in ForestTree.SOCKETS:
		var fits := Dweller.KINDS.keys().filter(func(k: StringName) -> bool: return side in Dweller.KINDS[k].sides)
		assert_int(fits.size()).is_greater_equal(2)


func test_animals_play_idle() -> void:
	var d: Dweller = auto_free(Dweller.make(&"fox"))
	add_child(d)
	var ap := d.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_object(ap).is_not_null()
	assert_bool(ap.is_playing()).is_true()


func test_ghost_is_see_through() -> void:
	var d: Dweller = auto_free(Dweller.make(&"tawny_owl"))
	Fx.ghostify(d)
	for g: GeometryInstance3D in d.find_children("*", "GeometryInstance3D", true, false):
		assert_float(g.transparency).is_greater(0.0)


func test_every_kind_has_a_name() -> void:
	var csv := FileAccess.get_file_as_string("res://i18n/strings.csv")
	for k in Dweller.KINDS.keys() + ForestTree.SPECIES.keys():
		assert_str(csv).contains("\nKIND_%s," % String(k).to_upper())
