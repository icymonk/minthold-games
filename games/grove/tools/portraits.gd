extends SceneTree
## 카드 초상을 모두 구워 PNG로 남긴다: godot --path . -s res://tools/portraits.gd -- <출력 폴더>

var _out := "user://portraits"
var _f := 0
var _left := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)


func _process(_d: float) -> bool:
	_f += 1
	if _f == 2:
		var studio: SubViewport = load("res://scripts/ui/portrait.gd").new()
		root.add_child(studio)
		var kinds: Array = load("res://scripts/world/dweller.gd").KINDS.keys() + load("res://scripts/world/forest_tree.gd").SPECIES.keys()
		_left = kinds.size()
		for k: StringName in kinds:
			studio.request(k, _save.bind(k))
	return _f > 3 and _left == 0


func _save(tex: Texture2D, kind: StringName) -> void:
	_left -= 1
	if tex:
		tex.get_image().save_png(_out.path_join("%s.png" % kind))
