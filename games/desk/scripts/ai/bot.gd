class_name Bot
extends RefCounted
## AI 1차(기획서 5장). `Knowledge`만 읽고 `Match.legal_moves` 중 하나(또는 그걸 고친 행동)를 고른다.

enum Persona { CAREFUL, REACTIVE, WILD }

const NAMES := { careful = Persona.CAREFUL, reactive = Persona.REACTIVE, wild = Persona.WILD }
## 점수에 더하는 무작위 폭(0~1 점수 기준). 막무가내일수록 크다.
const NOISE := { Persona.CAREFUL: 0.02, Persona.REACTIVE: 0.06, Persona.WILD: 0.3 }

var side: int
var persona: Persona
var rng: RandomNumberGenerator


func _init(s: int, r: RandomNumberGenerator, p: Persona = Persona.CAREFUL) -> void:
	side = s
	rng = r
	persona = p


## 지금 차례인 쪽 봇으로 한 걸음 진행한다. bots[side]. 끝났으면 false.
static func step(m: Match, bots: Array) -> bool:
	if m.is_over():
		return false
	var moves := m.legal_moves(m.side)
	if moves.is_empty():
		return false
	var b: Bot = bots[m.side]
	if m.apply(b.choose(Knowledge.of(m, m.side), moves)):
		return true
	return m.apply(moves[0])


func choose(_k: Knowledge, moves: Array[Dictionary]) -> Dictionary:
	return moves[0]


func _noise() -> float:
	return rng.randf() * NOISE[persona]
