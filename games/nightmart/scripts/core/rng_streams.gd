class_name RngStreams
extends RefCounted
## 런 seed 하나에서 용도별 RNG를 따로 만든다.
## 한쪽(예: 발주 목록)의 난수 사용량이 바뀌어도 다른 쪽(예: 진열대 섞기)은 그대로 유지된다.

var deck := RandomNumberGenerator.new()
var shop := RandomNumberGenerator.new()
var night := RandomNumberGenerator.new()
var bots := RandomNumberGenerator.new()


func _init(run_seed: int) -> void:
	deck.seed = _derive(run_seed, "deck")
	shop.seed = _derive(run_seed, "shop")
	night.seed = _derive(run_seed, "night")
	bots.seed = _derive(run_seed, "bots")


static func _derive(run_seed: int, stream: String) -> int:
	return hash("%d:%s" % [run_seed, stream])
