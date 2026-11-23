extends SceneTree
## 2-1 계절 화면 찍기: godot --path . --resolution 1920x1080 -s res://tools/season_shot.gd -- <출력 폴더>
## 자동 로드를 쓰는 클래스(Hand·ForestView)는 이름으로 부르지 않는다.
## 규칙 손패로 나무를 끌어(예상 점수) → 비용 고르기 → 심기 → 숲을 채운 뒤 계절 끝 점수 연출을 찍는다.

var _out := "user://shots"
var _f := 0
var _t := 0.0
var _plan: Array = []
var _cur: Array = []
var _screen: Control


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
		root.get_node(^"/root/Game").start_run(4)
		_plan = [
			[1.5, _snap.bind("season_start")], [0.0, _give_oak], [0.6, _hold_oak], [0.5, _snap.bind("drag_gain")],
			[0.0, _drop], [0.4, _snap.bind("pay")], [0.0, _confirm], [1.6, _snap.bind("planted")],
			[0.0, _grow], [2.5, _snap.bind("grown")], [0.0, _end], [1.6, _snap.bind("tally")], [4.0, _snap.bind("result")],
		]
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


func _scr() -> Control:
	if not is_instance_valid(_screen):
		for n in root.find_children("*", "Control", true, false):
			if n.has_method(&"_end_season"):
				_screen = n
	return _screen


func _give_oak() -> void:
	var s: Season = _scr().season
	s.hand.append(Cards.tree(900, &"oak"))
	_scr().hand.sync(s.hand)


func _hold_oak() -> void:
	var h = _scr().hand
	for v in h.cards:
		if v.card.id == 900 and h.begin_drag(v, 0):
			var targets: Array[Dictionary] = _scr()._targets(v.card, 0)
			h.move_drag(h.world.screen_position(targets[4 if targets.size() > 4 else 0]))


func _drop() -> void:
	_scr().hand.end_drag()


func _confirm() -> void:
	_scr()._confirm_pay()


## 숲을 규칙과 화면에 함께 채운다(연출 확인용)
func _grow() -> void:
	var s: Season = _scr().season
	var w = _scr().world
	var id := 1000
	for p in s.forest.free_plots():
		var kind: StringName = [&"fir", &"birch", &"chestnut", &"pine", &"maple", &"beech", &"linden", &"chestnut"][p % 8]
		s.forest.plant(p, Cards.tree(id, kind), kind)
		w.place({plot = p, side = &""}, kind)
		id += 1
	for put in [[0, &"Top", &"tawny_owl"], [1, &"Bottom", &"moss"], [2, &"Left", &"fox"], [3, &"Right", &"hare"], [3, &"Top", &"peacock_butterfly"], [5, &"Bottom", &"wood_ant"]]:
		if s.forest.attach(put[0], put[1], {id = id, sym = &""}, put[2]):
			w.place({plot = put[0], side = put[1]}, put[2])
		id += 1
	_scr()._refresh()


func _end() -> void:
	_scr().season.over = true
	_scr()._end_season()


func _snap(name: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [_out, name])
	print("shot ", name)
