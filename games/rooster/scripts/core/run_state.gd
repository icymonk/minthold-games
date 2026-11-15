class_name RunState
extends RefCounted
## 원정 한 판의 진행 상태. 씬 트리에 의존하지 않는 순수 로직.

const NIGHTS := 7
const BOSS_NIGHTS: Array[int] = [3, 7]
const START_LANTERNS := 3
const BOSS_LANTERN_LOSS := 2

var seed: int
var night: int = 1
var lanterns: int = START_LANTERNS
var rng: RngStreams


func _init(run_seed: int) -> void:
	seed = run_seed
	rng = RngStreams.new(run_seed)


func is_boss_night() -> bool:
	return night in BOSS_NIGHTS


func win_night() -> void:
	assert(not is_over())
	night += 1


func lose_night() -> void:
	assert(not is_over())
	var loss := BOSS_LANTERN_LOSS if is_boss_night() else 1
	lanterns = maxi(lanterns - loss, 0)
	if lanterns > 0:
		night += 1


func is_victory() -> bool:
	return night > NIGHTS and lanterns > 0


func is_defeat() -> bool:
	return lanterns <= 0


func is_over() -> bool:
	return is_victory() or is_defeat()
