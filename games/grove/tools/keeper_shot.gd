extends SceneTree
## 4-1 숲지기·등급·앨범 찍기: godot --path . --resolution 1920x1080 -s res://tools/keeper_shot.gd -- <출력 폴더>

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
		TranslationServer.set_locale("ko")
		_game = root.get_node(^"/root/Game")
		_game.save_path = "user://shot.save"
		_game.records_path = "user://shot_records.cfg"
		_game.album_dir = "user://shot_album"
		_game.records.runs = 3
		_game.records.finished = 1
		_game.records.best_grade = 2
		root.add_child(load("res://scenes/main.tscn").instantiate())
	if _f == 4:
		_game.keeper = &"bird_doctor"
		_game.grade = 2
		_game.goto(&"setup")
	if _f == 40:
		root.get_texture().get_image().save_png("%s/setup.png" % _out)
		_game.start_run(9)
		for p in 9:
			_game.run.forest.plant(p, {id = 5000 + p, sym = &""}, &"oak")
		_game.run_restored.emit(_game.run.forest)
		_game.finish_season()
		_game.after_season()
	if _f == 120:
		root.get_texture().get_image().save_png("%s/run_end.png" % _out)
		_game.goto(&"album")
	if _f == 150:
		root.get_texture().get_image().save_png("%s/album.png" % _out)
	return _f > 152
