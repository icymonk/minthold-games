class_name ChiefBot
extends Bot
## AI 팀장. 뽑기는 사원이 곧 쓸 번호가 든 더미를 막고(길막), 짚기는 Deduce 확률이 가장 높은 번호를 고른다.
## 확실한 번호가 있으면 한꺼번에 짚는다.

const SAMPLES := { Bot.Level.EASY: 60, Bot.Level.NORMAL: 200, Bot.Level.HARD: 300 }
## 눈치: 가장 최근 뒷면 기록 쪽 번호에 더 기운다.
const RECENT_BOOST := 0.5
const DRAW_WINDOW := 6

const A := Match.Action


func _init(r: RandomNumberGenerator, p: Bot.Persona = Bot.Persona.CAREFUL, l: Bot.Level = Bot.Level.HARD) -> void:
	super(Match.Side.CHIEF, r, p, l)


func choose(k: Knowledge, moves: Array[Dictionary]) -> Dictionary:
	if moves[0].action == A.DRAW:
		return _draw(k, moves)
	return _guess(k, moves)


## 사원이 지금 어디쯤 있을지 대강 어림한 번호.
static func frontier(k: Knowledge) -> int:
	var x := 0.0
	for h in k.hideouts:
		x = float(h.card) if h.card != Knowledge.HIDDEN else x + 2.0 + 1.5 * h.sprint_count
	return mini(int(x), Cards.LAST)


func _draw(k: Knowledge, moves: Array[Dictionary]) -> Dictionary:
	var est := frontier(k)
	var best: Dictionary = moves[0]
	var best_s := -INF
	for mv in moves:
		var r: Vector2i = Cards.ZONE_RANGES[mv.zone]
		var hits := 0
		for c in range(est + 1, est + 1 + DRAW_WINDOW):
			if c >= r.x and c <= r.y:
				hits += 1
		var s: float = float(hits) / DRAW_WINDOW + 0.01 * mv.zone + _noise()
		if s > best_s:
			best_s = s
			best = mv
	return best


func _guess(k: Knowledge, moves: Array[Dictionary]) -> Dictionary:
	var d := Deduce.run(k, rng, SAMPLES[level])
	var sure := d.sure()
	if not sure.is_empty():
		var nums: Array[int] = sure
		if k.phase == Match.Phase.MANHUNT:
			nums = [sure[0]]
		return { side = side, action = A.GUESS, numbers = nums }
	var odds := d.odds()
	if persona == Bot.Persona.REACTIVE:
		for i in range(k.hideouts.size() - 1, -1, -1):
			if not k.is_known(i):
				for c in Deduce.SIZE:
					odds[c] += d.probs[i][c] * RECENT_BOOST
				break
	var best: Dictionary = moves[0]
	var best_s := -INF
	for mv in moves:
		var s: float = odds[mv.numbers[0]] + _noise()
		if s > best_s:
			best_s = s
			best = mv
	return best
