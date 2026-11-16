class_name LoadingGuide
extends RefCounted
## 상차 화면 안내: 첫 근무 연습(단계별 손가락 안내)과 평소 한 줄 도움말.

enum Step { INTRO, ROUTE, LOAD_LAST, LOAD_MIDDLE, ROTATE, LOAD_FIRST, FIX_TIP, DEPART, DONE }

## 단계별 문구 키. 손가락 대상은 target()이 정한다.
const TEXT := {
	Step.INTRO: &"TUT_INTRO",
	Step.ROUTE: &"TUT_ROUTE",
	Step.LOAD_LAST: &"TUT_LOAD_LAST",
	Step.LOAD_MIDDLE: &"TUT_LOAD_MIDDLE",
	Step.ROTATE: &"TUT_ROTATE",
	Step.LOAD_FIRST: &"TUT_LOAD_FIRST",
	Step.FIX_TIP: &"TUT_FIX_TIP",
	Step.DEPART: &"TUT_DEPART",
}
## [다음] 버튼으로 넘기는 설명 단계.
const MANUAL: Array[Step] = [Step.INTRO, Step.ROUTE, Step.FIX_TIP]

var step := Step.INTRO
var rotated := false


## 연습용 하루: 3집, 상자 3개. 컨베이어 순서를 일부러 거꾸로(1번 집이 맨 앞) 둬서
## "앞에 있는 것부터"가 아니라 "늦게 갈 집부터" 실어야 한다는 걸 배운다.
static func tutorial_shift() -> ShiftState:
	var shift := ShiftState.new(3)
	shift.queue.append(Box.new(1, &"3x1", 1))
	shift.queue.append(Box.new(2, &"1x2", 2))
	shift.queue.append(Box.new(3, &"2x2", 3))
	return shift


func is_manual() -> bool:
	return step in MANUAL


func next() -> void:
	if is_manual():
		_go(step + 1)


func on_rotated() -> void:
	rotated = true


func on_departed() -> void:
	if step == Step.DEPART:
		_go(Step.DONE)


## 상태를 보고 다음 단계로 넘어간다. 넘어가면 true.
func update(shift: ShiftState, held: Box) -> bool:
	var before := step
	# 되돌리기로 이미 실은 상자가 빠지면 그 상자 단계로 돌아간다.
	if step >= Step.LOAD_MIDDLE and step <= Step.DEPART and not _loaded(shift, 3):
		_go(Step.LOAD_LAST)
	elif step >= Step.ROTATE and step <= Step.DEPART and not _loaded(shift, 2):
		_go(Step.LOAD_MIDDLE)
	elif step >= Step.FIX_TIP and step <= Step.DEPART and not _loaded(shift, 1):
		_go(Step.LOAD_FIRST)
	match step:
		Step.LOAD_LAST:
			if _loaded(shift, 3):
				_go(Step.LOAD_MIDDLE)
		Step.LOAD_MIDDLE:
			if _loaded(shift, 2):
				_go(Step.ROTATE)
		Step.ROTATE:
			if rotated and held != null:
				_go(Step.LOAD_FIRST)
			elif _loaded(shift, 1):
				_go(Step.FIX_TIP)
		Step.LOAD_FIRST:
			if _loaded(shift, 1):
				_go(Step.FIX_TIP)
	return step != before


## 손가락이 가리킬 곳: {kind = &"slot", box_id} / {kind = &"cell", cell} / {kind = &"button", name} / {}.
func target(shift: ShiftState, held: Box) -> Dictionary:
	match step:
		Step.ROUTE:
			return {kind = &"route"}
		Step.LOAD_LAST:
			return _load_target(shift, held, 3)
		Step.LOAD_MIDDLE:
			return _load_target(shift, held, 2)
		Step.ROTATE:
			if held == null or held.stop != 1:
				return _slot_of(shift, 1)
			return {kind = &"button", name = &"rotate"}
		Step.LOAD_FIRST:
			return _load_target(shift, held, 1)
		Step.DEPART:
			return {kind = &"button", name = &"depart"}
	return {}


func text_key(shift: ShiftState) -> StringName:
	if step in [Step.LOAD_MIDDLE, Step.ROTATE, Step.LOAD_FIRST] and not shift.bay.out_of_order().is_empty():
		return &"TUT_WRONG_ORDER"
	return TEXT.get(step, &"")


## 평소 도움말: [문구 키, 인자]. suggest = 지금 집으면 좋은 상자 id(-1 없음).
static func hint(shift: ShiftState, held: Box) -> Dictionary:
	if not shift.bay.out_of_order().is_empty():
		return {key = &"HINT_BLOCKING", arg = null, suggest = -1}
	if held != null:
		return {key = &"HINT_HOLDING", arg = held.stop, suggest = -1}
	if shift.queue.is_empty():
		return {key = &"HINT_DEPART", arg = null, suggest = -1}
	var best: Box = shift.queue[0]
	for b in shift.queue:
		if b.stop > best.stop:
			best = b
	return {key = &"HINT_NEXT", arg = best.stop, suggest = best.id}


## 상자를 바닥에 붙여 운전석 쪽부터 차곡차곡 넣을 칸: 바닥 줄에서 마지막 상자 바로 오른쪽.
static func next_floor_cell(bay: Bay) -> Vector2i:
	var x := 0
	for id in bay.boxes:
		var o: Vector2i = bay.origins[id]
		for c in bay.boxes[id].cells:
			x = maxi(x, o.x + c.x + 1)
	return Vector2i(mini(x, bay.width - 1), 0)


func _load_target(shift: ShiftState, held: Box, stop: int) -> Dictionary:
	if held != null and held.stop == stop:
		return {kind = &"cell", cell = next_floor_cell(shift.bay)}
	return _slot_of(shift, stop)


func _slot_of(shift: ShiftState, stop: int) -> Dictionary:
	for b in shift.queue:
		if b.stop == stop:
			return {kind = &"slot", box_id = b.id}
	return {}


func _loaded(shift: ShiftState, stop: int) -> bool:
	for id in shift.bay.boxes:
		if shift.bay.boxes[id].stop == stop:
			return true
	return false


func _go(s: int) -> void:
	step = s as Step
	if step == Step.ROTATE:
		rotated = false
