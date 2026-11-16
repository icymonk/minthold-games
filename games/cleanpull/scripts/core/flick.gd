class_name Flick
extends RefCounted
## 식탁보를 끄는 손동작을 PullSim.Pull로 바꾼다. 좌표는 화면 px, 시간은 초.

## 화면 px/s를 판정용 cm/s로 바꾸는 배율.
const GAIN := 0.4
## 이만큼 끌면 식탁보가 손을 떠나 빠진다(px).
const COMMIT := 160.0
## 이보다 짧게 끌고 놓으면 당기지 않은 것으로 본다(px).
const MIN_TUG := 30.0
## 순간 속도를 재는 구간(초).
const WINDOW := 0.06

var _start := Vector2.ZERO
var _points := PackedVector2Array()
var _times := PackedFloat64Array()
var _peak := 0.0


func begin(pos: Vector2, t: float) -> void:
	_start = pos
	_points = PackedVector2Array([pos])
	_times = PackedFloat64Array([t])
	_peak = 0.0


func move(pos: Vector2, t: float) -> void:
	_points.append(pos)
	_times.append(t)
	_peak = maxf(_peak, speed_px())


func offset() -> Vector2:
	return _points[_points.size() - 1] - _start if not _points.is_empty() else Vector2.ZERO


## 오른쪽으로 COMMIT 이상 끌었는가.
func committed() -> bool:
	return offset().x >= COMMIT


## 오른쪽으로 MIN_TUG 이상 끌었는가.
func tugged() -> bool:
	return offset().x >= MIN_TUG


## 마지막 WINDOW초 동안의 속도(px/s).
func speed_px() -> float:
	var last := _points.size() - 1
	if last < 1:
		return 0.0
	var i := last - 1
	while i > 0 and _times[last] - _times[i - 1] <= WINDOW:
		i -= 1
	var dt := _times[last] - _times[i]
	return 0.0 if dt <= 0.0 else _points[last].distance_to(_points[i]) / dt


func to_pull() -> PullSim.Pull:
	var d := offset()
	var now := speed_px()
	var angle := rad_to_deg(atan2(-d.y, d.x)) if d != Vector2.ZERO else 0.0
	var wobble := 0.0 if _peak <= 0.0 else 1.0 - now / _peak
	return PullSim.Pull.new(now * GAIN, angle, wobble)
