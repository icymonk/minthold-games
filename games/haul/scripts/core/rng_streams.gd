class_name RngStreams
extends RefCounted
## 한 판 시드 하나에서 용도별 RNG를 따로 만든다.
## 한쪽(예: 변수)의 난수 사용량이 바뀌어도 다른 쪽(예: 배송 경로)은 그대로 유지된다.

var route := RandomNumberGenerator.new()
var cargo := RandomNumberGenerator.new()
var events := RandomNumberGenerator.new()


func _init(run_seed: int) -> void:
	route.seed = _derive(run_seed, "route")
	cargo.seed = _derive(run_seed, "cargo")
	events.seed = _derive(run_seed, "events")


static func _derive(run_seed: int, stream: String) -> int:
	return hash("%d:%s" % [run_seed, stream])
