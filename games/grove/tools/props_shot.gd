extends SceneTree
## 3-2 계절 소품 찍기: godot --path . --resolution 1920x1080 -s res://tools/props_shot.gd -- <출력 폴더>

var _out := "user://shots"
var _f := 0
const NAMES := ["spring", "summer", "autumn", "winter"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)


func _process(_delta: float) -> bool:
	_f += 1
	if _f == 2:
		load("res://scripts/ui/coach.gd").mark_seen(true)
		root.add_child(load("res://scenes/main.tscn").instantiate())
	for i in 4:
		if _f == 10 + i * 40:
			for w in root.find_children("*", "Node3D", true, false):
				if w.has_method("open_plots"):
					w.set_season(i, false)
		if _f == 40 + i * 40:
			root.get_texture().get_image().save_png("%s/%s.png" % [_out, NAMES[i]])
	return _f > 170
