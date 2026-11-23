extends SceneTree
## 온라인 대전 화면 찍기(가짜 DB 두 기기): godot --path . --resolution 1920x1080 -s res://tools/online_shot.gd -- <출력 폴더>

var _out := "user://shots"
var _store := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _wait(s: float) -> void:
	await create_timer(s).timeout


func _snap(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, name])
	print("shot ", name)


func _scr() -> Control:
	for n in root.find_children("*", "Control", true, false):
		if n.has_method(&"_end_match"):
			return n
	return null


func _run() -> void:
	load("res://scripts/ui/coach.gd").mark_seen(true)
	root.add_child(load("res://scenes/main.tscn").instantiate())
	await _wait(1.0)
	var game: Node = root.get_node(^"/root/Game")
	var a := Online.new(MemDb.new(_store, "ua"))
	game.online = a
	game.add_child(a)
	game.nick = "민트"
	var b := Online.new(MemDb.new(_store, "ub"))
	root.add_child(b)
	b.set_process(false)
	game.goto(&"lobby")
	await _wait(1.0)
	await _snap("lobby_entry")
	await a.create("민트")
	await b.join(a.code, "도토리")
	await a.poll()
	await _wait(0.5)
	await _snap("lobby_room")
	await a.start()
	await _wait(2.5)
	await b.poll()
	await _snap("online_my_turn")
	var scr := _scr()
	scr._take_card(-1)
	scr._take_card(-1)
	await _wait(1.0)
	await _snap("online_wait")
	await b.poll()
	for c in b.game.hand_of(b.seat):
		if Cards.is_tree(c) and Cards.cost_of(c, 0) == 0:
			b.act({k = "play", id = c.id, half = 0, plot = 0, pay = []})
			break
	if b.my_turn():
		b.act({k = "draw"})
		b.act({k = "draw"})
	await _wait(0.5)
	await a.poll()
	await _wait(0.5)
	scr._view(1)
	await _wait(1.5)
	await _snap("online_view_rival")
	scr._view(0)
	await _wait(0.5)
	scr._end_match()
	await _wait(1.0)
	await _snap("online_ranking")
	quit()
