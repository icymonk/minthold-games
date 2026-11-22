extends SceneTree
## 화면 확인용 스크린샷: 제목·계절 4개를 찍는다.
## xvfb-run godot --path . --resolution 1920x1080 -s res://tools/shot.gd -- <저장 폴더>

var _f := 0
var _out := "user://shots"
var _game: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)


func _process(_d: float) -> bool:
	_f += 1
	match _f:
		2:
			# 자동 로드(Game)가 붙은 뒤에 main을 불러야 한다
			_game = root.get_node(^"/root/Game")
			root.add_child(load("res://scenes/main.tscn").instantiate())
		12: _save("title")
		13: _game.start_run()
		30: _save("spring")
		31: _game.next_season()
		48: _save("summer")
		49: _game.next_season()
		66: _save("autumn")
		67:
			_game.next_season()
			_game.turn_requested.emit(1)
		90:
			_save("winter")
			return true
	return false


func _save(n: String) -> void:
	root.get_texture().get_image().save_png(_out.path_join("%s.png" % n))
	print("shot ", n)
