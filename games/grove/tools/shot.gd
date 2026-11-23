extends SceneTree
## 1080p 스크린샷: godot --path . --resolution 1920x1080 -s res://tools/shot.gd -- <출력 폴더>

## 계절 색 전환(1.2초)이 끝난 뒤 찍는다.
const SETTLE := 1.6

var _out := "user://shots"
var _game: Node
var _step := 0
var _wait := 0.0
var _f := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)


func _process(delta: float) -> bool:
	_f += 1
	if _f == 2:
		_game = root.get_node(^"/root/Game")
		root.add_child(load("res://scenes/main.tscn").instantiate())
	if _f < 3:
		return false
	_wait -= delta
	if _wait > 0.0:
		return false
	_wait = SETTLE
	_step += 1
	match _step:
		1: pass
		2:
			_save("title")
			_game.start_run()
		3:
			_save("spring")
			_game.next_season()
		4:
			_save("summer")
			_game.next_season()
		5:
			_save("autumn")
			_game.next_season()
			_game.turn_requested.emit(1)
		6:
			_save("winter")
			return true
	return false


func _save(n: String) -> void:
	root.get_texture().get_image().save_png(_out.path_join("%s.png" % n))
	print("shot ", n)
