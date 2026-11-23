extends SceneTree
## 2-2 오두막·런 끝 찍기: godot --path . --resolution 1920x1080 -s res://tools/cabin_shot.gd -- <출력 폴더>
## 자동 로드를 쓰는 클래스(ForestView 등)는 이름으로 부르지 않는다.

var _out := "user://shots"
var _f := 0
var _t := 0.0
var _plan: Array = []
var _cur: Array = []
var _game: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)


func _process(delta: float) -> bool:
	_f += 1
	if _f == 2:
		load("res://scripts/ui/coach.gd").mark_seen(true)
		root.add_child(load("res://scenes/main.tscn").instantiate())
	if _f == 4:
		_game = root.get_node(^"/root/Game")
		_game.start_run(4)
		_plan = [[1.0, _pass], [2.0, _snap.bind("cabin")], [0.0, _land], [2.5, _snap.bind("land")], [0.0, _game.next_season], [2.0, _snap.bind("summer")], [0.0, _end], [2.5, _snap.bind("run_end")]]
	if _f < 5:
		return false
	_t -= delta
	if _t > 0.0:
		return false
	if not _cur.is_empty():
		_cur[1].call()
		_cur = []
	if _plan.is_empty():
		return true
	_cur = _plan.pop_front()
	_t = _cur[0]
	return false


func _world() -> Node:
	return root.get_tree().get_first_node_in_group(&"forest_view")


func _pass() -> void:
	var run: Run = _game.run
	run.events[0] = &"doves"
	var kinds := [&"fir", &"fir", &"fir", &"fir", &"maple", &"fir", &"fir", &"fir", &"fir"]
	for p in 9:
		run.forest.plant(p, Cards.tree(1000 + p, kinds[p]), kinds[p])
		_world().place({plot = p, side = &""}, kinds[p])
	print("score ", Score.count(run.forest).total)
	_game.finish_season()
	run.acorns = 14
	_game.after_season()


func _land() -> void:
	for c in root.find_children("*", "Control", true, false):
		if c.has_method(&"_buy"):
			c._buy({t = &"land"})
			return


func _end() -> void:
	var run: Run = _game.run
	for i in 3:
		run.scores.append(run.scores[0])
	run.lost = false
	run.done = true
	_game.goto(&"run_end")


func _snap(name: String) -> void:
	root.get_texture().get_image().save_png("%s/%s.png" % [_out, name])
	print("shot ", name)
