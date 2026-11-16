class_name Session
extends RefCounted
## 한 판 진행: 자리 0은 사람, 나머지는 Bot. 화면은 이것과 `view()`(자리 0의 Knowledge)만 읽는다.

const HUMAN := 0

var m: Match
var bots: Array = []
var events: Array[Dictionary] = []   # 공개된 행동 기록(moved 신호 순서)


func _init(players: int, streams: RngStreams) -> void:
	m = Match.deal(players, streams.deal, streams.play)
	for s in players:
		bots.append(null if s == HUMAN else Bot.new(s, streams.bots, (s - 1) % 3 as Bot.Persona))
	m.moved.connect(_on_moved)


func _on_moved(mv: Dictionary) -> void:
	events.append(mv.duplicate())


func view() -> Knowledge:
	return Knowledge.of(m, HUMAN)


func is_over() -> bool:
	return m.is_over()


## 사람이 답하거나 낼 차례라 AI가 더 진행할 수 없으면 true.
func waiting_for_human() -> bool:
	if m.is_over():
		return false
	if not m.pending.is_empty():
		return m.pending.all(func(r: Dictionary) -> bool: return r.seat == HUMAN)
	return m.turn == HUMAN


## AI 한 걸음(결정 요청 답 또는 행동). 진행할 게 없으면 false.
func ai_step() -> bool:
	if m.is_over() or waiting_for_human():
		return false
	for r in m.pending:
		if r.seat != HUMAN:
			var answerer: Bot = bots[r.seat]
			return m.answer(r.seat, answerer.choose_answer(Knowledge.of(m, r.seat)))
	var bot: Bot = bots[m.turn]
	return m.apply(bot.choose_move(Knowledge.of(m, m.turn), m.legal_moves(m.turn)))


func can_play(move: Dictionary) -> bool:
	return waiting_for_human() and m.pending.is_empty() and m.is_legal(move)


func play(move: Dictionary) -> bool:
	return can_play(move) and m.apply(move)


func answer(choice: Variant) -> bool:
	return waiting_for_human() and m.answer(HUMAN, choice)


func result() -> Dictionary:
	return m.resolve() if m.is_over() else {}
