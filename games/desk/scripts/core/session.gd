class_name Session
extends RefCounted
## 사람 한 명 + AI 한 명의 판. 화면은 `view()`(사람 쪽 `Knowledge`)만 그린다.

var m: Match
var human: int
var bot: Bot


func _init(human_side: int, streams: RngStreams, level: Bot.Level = Bot.Level.NORMAL, persona: Bot.Persona = Bot.Persona.CAREFUL) -> void:
	m = Match.deal(streams.deal)
	human = human_side
	if human == Match.Side.STAFF:
		bot = ChiefBot.new(streams.bots, persona, level)
	else:
		bot = StaffBot.new(streams.bots, persona, level)


func view() -> Knowledge:
	return Knowledge.of(m, human)


func is_over() -> bool:
	return m.is_over()


func waiting_for_human() -> bool:
	return not m.is_over() and m.side == human


func human_moves() -> Array[Dictionary]:
	if not waiting_for_human():
		return [] as Array[Dictionary]
	return m.legal_moves(human)


func play(move: Dictionary) -> bool:
	return waiting_for_human() and move.get(&"side", Match.NONE) == human and m.apply(move)


## AI 차례면 한 수 둔다. 사람 차례거나 끝났으면 false.
func ai_step() -> bool:
	if m.is_over() or m.side == human:
		return false
	var moves := m.legal_moves(m.side)
	if moves.is_empty():
		return false
	return m.apply(bot.pick(Knowledge.of(m, m.side), moves)) or m.apply(moves[0])
