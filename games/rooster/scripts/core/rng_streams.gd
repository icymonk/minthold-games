class_name RngStreams
extends RefCounted
## 원정 시드 하나에서 용도별 RNG를 따로 만든다.
## 한쪽(예: 전투)의 난수 사용량이 바뀌어도 다른 쪽(예: 장터 진열)은 그대로 유지된다.

var market := RandomNumberGenerator.new()
var battle := RandomNumberGenerator.new()
var events := RandomNumberGenerator.new()


func _init(run_seed: int) -> void:
	market.seed = _derive(run_seed, "market")
	battle.seed = _derive(run_seed, "battle")
	events.seed = _derive(run_seed, "events")


static func _derive(run_seed: int, stream: String) -> int:
	return hash("%d:%s" % [run_seed, stream])
