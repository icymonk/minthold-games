extends SceneTree
## 4-2 오늘의 숲·끝없는 해 찍기: godot --path . --resolution 1920x1080 -s res://tools/endless_shot.gd -- <출력 폴더>

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
		_game.album_dir = "user://shot_album"
		_game.records.daily[_game.today()] = 812
		root.add_child(load("res://scenes/main.tscn").instantiate())
	if _f == 40:
		root.get_texture().get_image().save_png("%s/title.png" % _out)
		_game.start_run(9)
		for p in 9:
			_game.run.forest.plant(p, {id = 5000 + p, sym = &""}, [&"oak", &"birch", &"maple"][p % 3])
		_game.run_restored.emit(_game.run.forest)
		for i in 4:
			_game.run.season_index = i
			var log := ScoreLog.new()
			log.total = _game.run.target_of(i) + 30 * (i + 1)
			_game.run.scores.append(log)
		_game.run.season_index = 4
		_game.run.done = true
		_game.photo_pending = false
		_game.goto(&"run_end")
	if _f == 110:
		root.get_texture().get_image().save_png("%s/run_end.png" % _out)
	return _f > 112
