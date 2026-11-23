extends SceneTree
## 카드 표시·상세 창·숲 카드 살펴보기·끌어 돌리기 찍기: godot --path . --resolution 1920x1080 -s res://tools/cards_shot.gd -- <출력 폴더>
## 자동 로드를 쓰는 클래스(Hand·ForestView)는 이름으로 부르지 않는다.

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
	if args.size() > 1:
		TranslationServer.set_locale(args[1])
	DirAccess.make_dir_recursive_absolute(_out)


func _process(delta: float) -> bool:
	_f += 1
	if _f == 2:
		load("res://scripts/ui/coach.gd").mark_seen(true)
		root.add_child(load("res://scenes/main.tscn").instantiate())
	if _f == 4:
		root.get_node(^"/root/Game").start_run(4)
		_plan = [
			[1.5, _snap.bind("hand")], [0.0, _detail], [0.6, _snap.bind("hand_detail")],
			[0.0, _detail_split], [0.6, _detail], [0.6, _snap.bind("hand_detail_split")],
			[0.0, _clearing], [0.4, _clearing_show], [0.8, _snap.bind("clearing_detail")],
			[0.0, _grow], [2.5, _inspect.bind(&"Top")], [0.4, _snap.bind("inspect_neighbor")],
			[0.0, _inspect.bind(&"")], [0.4, _snap.bind("inspect_tree")],
			[0.0, _spin], [0.6, _snap.bind("dragged")],
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


func _detail() -> void:
	var h = _scr().hand
	h.show_detail(h.cards[0])


## 왼/오른 반쪽 카드를 손패 맨 앞에 넣고 상세 창
func _detail_split() -> void:
	var scr := _scr()
	scr.hand.hide_detail()
	var s: Season = scr.season
	s.hand.push_front(Cards.full_pair(7000, 24))
	s.hand.push_front(Cards.full_pair(7001, 63))
	scr.hand.sync(s.hand)


## 공터에 카드를 놓고 하나에 마우스를 올린 것처럼 상세 창
func _clearing() -> void:
	var scr := _scr()
	scr.hand.hide_detail()
	var s: Season = scr.season
	for i in [44, 71, 22]:
		s.clearing.append(Cards.full_pair(7100 + i, i))
	scr._refresh()


func _clearing_show() -> void:
	var scr := _scr()
	var s: Season = scr.season
	var box: Control = scr._clearing.get_child(scr._clearing.get_child_count() - 1)
	scr._show_clearing_detail(box, s.clearing.back())


func _inspect(side: StringName) -> void:
	_scr().hand.hide_detail()
	if is_instance_valid(_scr()._clearing_detail):
		_scr()._clearing_detail.queue_free()
	var w = _scr().world
	var at: Vector2 = w.screen_position({plot = 0, side = side}) if side != &"" else w.screen_position({plot = 2, side = &""})
	_scr()._inspect(at)


func _spin() -> void:
	_scr()._inspect(Vector2.INF)
	var w = _scr().world
	for i in 20:
		w.drag_yaw(-12.0)
	w.end_drag_yaw()


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


func _snap(name: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [_out, name])
	print("shot ", name)
