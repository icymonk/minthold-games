class_name RngStreams
extends RefCounted
## 한 판 시드 하나에서 용도별 RNG를 따로 만든다.
## 한쪽(예: AI 고민)의 난수 사용량이 바뀌어도 다른 쪽(예: 카드 분배)은 그대로 유지된다.

var deal := RandomNumberGenerator.new()
var play := RandomNumberGenerator.new()
var bots := RandomNumberGenerator.new()


func _init(run_seed: int) -> void:
	deal.seed = _derive(run_seed, "deal")
	play.seed = _derive(run_seed, "play")
	bots.seed = _derive(run_seed, "bots")


static func _derive(run_seed: int, stream: String) -> int:
	return hash("%d:%s" % [run_seed, stream])
