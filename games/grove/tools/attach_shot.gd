extends SceneTree
## 0-3 카드 → 숲 붙이기 장면 찍기: godot --path . --resolution 1920x1080 -s res://tools/attach_shot.gd -- <출력 폴더>
## 손패 카드를 코드로 끌어 자리 빛·미리 보기·등장 연출 도중·뒤를 찍는다.

var _out := "user://shots"
var _f := 0
var _t := 0.0
var _plan: Array = []
var _cur: Array = []
## 자동 로드(Game·Sfx)를 쓰는 클래스는 이름으로 부르지 않는다(이 스크립트가 먼저 컴파일된다)
var _hand: Control


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)


func _process(delta: float) -> bool:
	_f += 1
	if _f == 2:
		root.add_child(load("res://scenes/main.tscn").instantiate())
	if _f == 4:
		root.get_node(^"/root/Game").start_run()
		# [기다릴 초, 할 일]: 앞 단계 뒤 그만큼 기다렸다가 한다
		var tree := func(c: Dictionary) -> bool: return DemoCards.is_tree(c)
		var owl := func(c: Dictionary) -> bool: return c.get("axis") == &"v" and c.halves[0] == &"owl"
		var fox := func(c: Dictionary) -> bool: return c.get("axis") == &"h"
		var fly := func(c: Dictionary) -> bool: return c.get("axis") == &"v" and c.halves[0] == &"butterfly"
		_plan = [
			[1.8, _snap.bind("coach")], [0.0, _skip_coach],
			[0.4, _hold.bind(tree, 0)], [0.5, _snap.bind("drag_tree")], [0.0, _drop],
			[0.35, _snap.bind("grow_mid")], [1.2, _snap.bind("grown")],
			[0.2, _hold.bind(owl, 0)], [0.5, _snap.bind("drag_owl")], [0.0, _drop], [0.6, _snap.bind("fly_mid")],
			[1.4, _hold.bind(fox, 0)], [0.5, _snap.bind("drag_fox")], [0.0, _drop], [0.8, _snap.bind("walk_mid")],
			[2.0, _hold.bind(fly, 1)], [0.5, _snap.bind("drag_axolotl")], [0.0, _drop], [0.45, _snap.bind("hop_mid")],
			[1.2, _hold.bind(owl, 1)], [0.0, _drop], [0.25, _snap.bind("pop_mid")],
			[1.0, _hold.bind(fly, 0)], [0.0, _drop], [0.8, _snap.bind("flutter_mid")],
			[2.0, _snap.bind("after")], [0.0, _turn], [1.0, _snap.bind("turned")],
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


func _hand_node() -> Control:
	if not is_instance_valid(_hand):
		_hand = root.find_children("*", "Hand", true, false)[0]
	return _hand


func _skip_coach() -> void:
	for c in root.find_children("*", "Coach", true, false):
		c.finish()
	load("res://scripts/ui/coach.gd").mark_seen(false)


func _hold(pick: Callable, half: int) -> void:
	var h := _hand_node()
	for v in h.cards:
		if pick.call(v.card):
			if h.begin_drag(v, half):
				# 카메라에 가장 가까운(화면 아래쪽) 자리로 가져간다
				var targets: Array = h.world.targets_for(v.kind(), v.side())
				targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return h.world.screen_position(a).y > h.world.screen_position(b).y)
				h.move_drag(h.world.screen_position(targets[0]))
			return
	print("no card")


func _drop() -> void:
	_hand_node().end_drag()


func _turn() -> void:
	root.get_node(^"/root/Game").turn_requested.emit(1)


func _snap(n: String) -> void:
	root.get_texture().get_image().save_png(_out.path_join("%s.png" % n))
	print("shot ", n)
