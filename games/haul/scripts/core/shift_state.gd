class_name ShiftState
extends RefCounted
## 하루 근무: 오늘의 배송 집 수, 짐칸, 아직 싣지 않은 상자(컨베이어).

const PRACTICE_SHAPES: Array[StringName] = [&"1x1", &"2x1", &"3x1", &"1x2", &"2x2", &"L", &"J", &"T"]

var stops: int
var bay: Bay
var queue: Array[Box] = []


func _init(stop_count: int, bay_size := Vector2i(8, 4)) -> void:
	stops = stop_count
	bay = Bay.new(bay_size.x, bay_size.y)


## 속성 없는 연습용 하루. 상자 칸 합이 짐칸의 max_fill 비율을 넘지 않게 만든다.
static func practice(rng: RandomNumberGenerator, stop_count := 4, per_stop := 2, max_fill := 0.75) -> ShiftState:
	var shift := ShiftState.new(stop_count)
	var budget := int(shift.bay.width * shift.bay.height * max_fill)
	var next_id := 1
	for stop in range(1, stop_count + 1):
		for i in per_stop:
			var shape := PRACTICE_SHAPES[rng.randi_range(0, PRACTICE_SHAPES.size() - 1)]
			var cells: int = Box.SHAPES[shape].size()
			var left := (stop_count - stop) * per_stop + (per_stop - i - 1)
			if budget - cells < left:
				shape = &"1x1"
				cells = 1
			budget -= cells
			shift.queue.append(Box.new(next_id, shape, stop))
			next_id += 1
	return shift


func snapshot() -> Dictionary:
	return {bay = bay.copy(), queue = queue.map(func(b: Box) -> Box: return b.copy())}


func restore(snap: Dictionary) -> void:
	bay = snap.bay.copy()
	queue.assign(snap.queue.map(func(b: Box) -> Box: return b.copy()))
