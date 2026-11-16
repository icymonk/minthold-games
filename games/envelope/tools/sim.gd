extends SceneTree
## 헤드리스 시뮬레이터(architecture 4장): AI끼리 돌려 진영별 승률을 본다.
## godot --headless -s tools/sim.gd -- --games 2000 --players 5 --seed 1

const C := Cards.Id
const STAFF := [C.CHAIR, C.ACCOUNTANT, C.HR, C.SNIFFER, C.BUSYBODY, C.BROADCAST, C.SUPPLIES]


func _init() -> void:
	var args := _args()
	var games: int = int(args.get("games", "1000"))
	var players: int = int(args.get("players", "5"))
	var base_seed: int = int(args.get("seed", "1"))
	if args.has("target"):
		Cards.tune[&"target"] = int(args.target)
	for knob in ["add", "remove"]:
		if args.has(knob):
			var ids: Array[int] = []
			for key in String(args[knob]).split(",", false):
				ids.append(Cards.Id[key])
			Cards.tune[StringName(knob)] = ids
	for pair in String(args.get("bot", "")).split(",", false):
		var kv := pair.split("=")
		Bot.tune[StringName(kv[0])] = float(kv[1])
	var stats := run(games, players, base_seed)
	print(JSON.stringify(stats, "  "))
	quit()


static func run(games: int, players: int, base_seed: int) -> Dictionary:
	var side := { staff = 0, thief = 0, boss = 0, other = 0, none = 0 }
	var by_role := {}
	var funded := 0
	var caught := 0
	var thief_games := 0
	var fund_total := 0
	var stalled := 0
	for g in games:
		var streams := RngStreams.new(base_seed * 100003 + g)
		var m := Match.deal(players, streams.deal, streams.play)
		var bots: Array = []
		for s in players:
			bots.append(Bot.new(s, streams.bots, (s + g) % 3 as Bot.Persona))
		var steps := 0
		while Bot.step(m, bots):
			steps += 1
			if steps > 1000:
				stalled += 1
				break
		var r := m.resolve()
		funded += int(r.funded)
		fund_total += r.fund
		if not r.no_thief:
			thief_games += 1
			for s in players:
				if r.roles[s] == C.THIEF and r.confined[s]:
					caught += 1
		var label := "none"
		if not r.winners.is_empty():
			var role: int = r.roles[r.winners[0]]
			label = "staff" if STAFF.has(role) else "thief" if role == C.THIEF or role == C.BUDDY else "boss" if role == C.BOSS else "other"
			if r.priority == 4:
				for w in r.winners:
					if STAFF.has(r.roles[w]):
						label = "staff"
		side[label] += 1
		for w in r.winners:
			var key := Cards.DEFS[r.roles[w]].key as StringName
			by_role[key] = by_role.get(key, 0) + 1
	var pct := func(n: int) -> float: return snappedf(100.0 * n / maxf(1, games), 0.1)
	var side_pct := {}
	for key in side:
		side_pct[key] = pct.call(side[key])
	return {
		games = games, players = players, stalled = stalled,
		side_win_pct = side_pct,
		funded_pct = pct.call(funded),
		thief_caught_pct = snappedf(100.0 * caught / maxf(1, thief_games), 0.1),
		avg_fund = snappedf(float(fund_total) / maxf(1, games), 0.01),
		target = Cards.target(players),
		role_wins = by_role,
	}


func _args() -> Dictionary:
	var out := {}
	var a := OS.get_cmdline_user_args()
	for i in a.size():
		if a[i].begins_with("--") and i + 1 < a.size():
			out[a[i].substr(2)] = a[i + 1]
	return out
