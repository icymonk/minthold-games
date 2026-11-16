class_name RngStreams
extends RefCounted
## 한 판 시드 하나에서 용도별 RNG를 따로 만든다.
## 한쪽(예: 가게)의 난수 사용량이 바뀌어도 다른 쪽(예: 그릇 후보)은 그대로 유지된다.

var deal := RandomNumberGenerator.new()
var shop := RandomNumberGenerator.new()
var events := RandomNumberGenerator.new()


func _init(run_seed: int) -> void:
	deal.seed = _derive(run_seed, "deal")
	shop.seed = _derive(run_seed, "shop")
	events.seed = _derive(run_seed, "events")


static func _derive(run_seed: int, stream: String) -> int:
	return hash("%d:%s" % [run_seed, stream])
