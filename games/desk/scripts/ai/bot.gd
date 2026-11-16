class_name Bot
extends RefCounted
## AI 1차(기획서 5장). `Knowledge`만 읽고 `Match.legal_moves` 중 하나(또는 그걸 고친 행동)를 고른다.

enum Persona { CAREFUL, REACTIVE, WILD }
## 난이도(사람이 상대할 AI의 세기). 실수는 정해진 확률로 아무 합법 수나 둔다.
enum Level { EASY, NORMAL, HARD }

const NAMES := { careful = Persona.CAREFUL, reactive = Persona.REACTIVE, wild = Persona.WILD }
## 점수에 더하는 무작위 폭(0~1 점수 기준). 막무가내일수록 크다.
const NOISE := { Persona.CAREFUL: 0.02, Persona.REACTIVE: 0.06, Persona.WILD: 0.3 }
const LEVELS := { easy = Level.EASY, normal = Level.NORMAL, hard = Level.HARD }
## 팀장의 실수 한 번이 사원보다 훨씬 크게 작용해 쪽마다 따로 둔다.
const BLUNDER := {
	Match.Side.STAFF: { Level.EASY: 0.3, Level.NORMAL: 0.06, Level.HARD: 0.0 },
	Match.Side.CHIEF: { Level.EASY: 0.2, Level.NORMAL: 0.06, Level.HARD: 0.0 },
}

var side: int
var persona: Persona
var rng: RandomNumberGenerator
var level := Level.HARD


func _init(s: int, r: RandomNumberGenerator, p: Persona = Persona.CAREFUL, l: Level = Level.HARD) -> void:
	side = s
	rng = r
	persona = p
	level = l


## 지금 차례인 쪽 봇으로 한 걸음 진행한다. bots[side]. 끝났으면 false.
static func step(m: Match, bots: Array) -> bool:
	if m.is_over():
		return false
	var moves := m.legal_moves(m.side)
	if moves.is_empty():
		return false
	var b: Bot = bots[m.side]
	if m.apply(b.pick(Knowledge.of(m, m.side), moves)):
		return true
	return m.apply(moves[0])


## 난이도에 따른 실수를 섞은 choose.
func pick(k: Knowledge, moves: Array[Dictionary]) -> Dictionary:
	if rng.randf() < BLUNDER[side][level]:
		return moves[rng.randi() % moves.size()]
	return choose(k, moves)


func choose(_k: Knowledge, moves: Array[Dictionary]) -> Dictionary:
	return moves[0]


func _noise() -> float:
	return rng.randf() * NOISE[persona]
