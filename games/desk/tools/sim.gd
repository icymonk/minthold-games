extends SceneTree
## 헤드리스 시뮬레이터(아키텍처 5장): AI끼리 돌려 사원 승률, 차례 수, 마지막 추궁, 뛰기 사용량을 본다.
## godot --headless -s tools/sim.gd -- --games 500 --chief careful --staff careful --seed 1


func _init() -> void:
	var args := _args()
	var stats := run(
		int(args.get("games", "500")),
		Bot.NAMES[args.get("chief", "careful")],
		Bot.NAMES[args.get("staff", "careful")],
		int(args.get("seed", "1")))
	print(JSON.stringify(stats, "  "))
	quit()


static func run(games: int, chief: int, staff: int, base_seed: int) -> Dictionary:
	var staff_wins := 0
	var turns := 0
	var manhunts := 0
	var manhunt_caught := 0
	var sprints := 0
	var records := 0
	var stalled := 0
	for g in games:
		var streams := RngStreams.new(base_seed * 100003 + g)
		var m := Match.deal(streams.deal)
		var bots := [StaffBot.new(streams.bots, staff), ChiefBot.new(streams.bots, chief)]
		var steps := 0
		var hunted := false
		while Bot.step(m, bots):
			hunted = hunted or m.phase == Match.Phase.MANHUNT
			steps += 1
			if steps > 2000:
				stalled += 1
				break
		if m.winner == Match.Side.STAFF:
			staff_wins += 1
		if hunted:
			manhunts += 1
			if m.winner == Match.Side.CHIEF:
				manhunt_caught += 1
		turns += m.turns[Match.Side.STAFF]
		for i in range(1, m.hideouts.size()):
			records += 1
			sprints += m.hideouts[i].sprints.size()
	var n := maxf(1, games)
	return {
		games = games, stalled = stalled,
		staff_win_pct = snappedf(100.0 * staff_wins / n, 0.1),
		avg_staff_turns = snappedf(turns / n, 0.1),
		avg_records = snappedf(records / n, 0.1),
		avg_sprint_cards = snappedf(sprints / n, 0.1),
		manhunt_pct = snappedf(100.0 * manhunts / n, 0.1),
		manhunt_caught_pct = snappedf(100.0 * manhunt_caught / maxf(1, manhunts), 0.1),
	}


static func _args() -> Dictionary:
	var out := {}
	var a := OS.get_cmdline_user_args()
	for i in a.size():
		if a[i].begins_with("--") and i + 1 < a.size():
			out[a[i].substr(2)] = a[i + 1]
	return out
