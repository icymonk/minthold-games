extends SceneTree
## 3-3 도감·이어 하기 찍기: godot --path . --resolution 1920x1080 -s res://tools/codex_shot.gd -- <출력 폴더>

var _out := "user://shots"
var _f := 0
var _game: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)


func _process(_delta: float) -> bool:
	_f += 1
	if _f == 2:
		load("res://scripts/ui/coach.gd").mark_seen(true)
		_game = root.get_node(^"/root/Game")
		_game.save_path = "user://shot.save"
		_game.records_path = "user://shot_records.cfg"
		var kinds: Array = load("res://scripts/rules/records.gd").all_kinds()
		for i in kinds.size():
			if i % 3 != 2:
				_game.records.seen[kinds[i]] = 1
		_game.records.runs = 7
		_game.records.finished = 4
		_game.records.best_year = 1840
		root.add_child(load("res://scenes/main.tscn").instantiate())
	if _f == 4:
		_game.start_run(5)
		for p in 9:
			_game.run.forest.plant(p, {id = 5000 + p, sym = &""}, &"fir")
		_game.run.forest.attach(0, &"Top", {id = 6000}, &"goshawk")
		_game.run.forest.attach(1, &"Left", {id = 6001}, &"red_panda")
		_game.run.forest.attach(2, &"Bottom", {id = 6002}, &"fly_agaric")
		_game.finish_season()
		_game.after_season()
		_game.goto(&"title")
	if _f == 30:
		root.get_texture().get_image().save_png("%s/title_continue.png" % _out)
		_game.continue_run()
	if _f == 90:
		root.get_texture().get_image().save_png("%s/continued.png" % _out)
		_game.goto(&"codex")
	if _f == 200:
		root.get_texture().get_image().save_png("%s/codex.png" % _out)
		for p in ["user://shot.save", "user://shot_records.cfg"]:
			DirAccess.remove_absolute(p)
	return _f > 205
