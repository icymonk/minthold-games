extends SceneTree
## 헤드리스 시뮬레이터(규칙 1-3): 탐욕 봇이 한 해를 여러 판 돌려 계절별 통과율·점수·도토리를 본다.
## godot --headless -s tools/sim.gd -- --runs 50 --seed 1


func _init() -> void:
	var args := {}
	var a := OS.get_cmdline_user_args()
	for i in range(0, a.size() - 1, 2):
		args[a[i].trim_prefix("--")] = a[i + 1]
	print(JSON.stringify(run(int(args.get("runs", "50")), int(args.get("seed", "1")), StringName(args.get("keeper", "grandma")), int(args.get("grade", "0"))), "  "))
	quit()


static func run(runs: int, base_seed: int, keeper: StringName = &"grandma", grade := 0) -> Dictionary:
	var reached := [0, 0, 0, 0]
	var sums := [0, 0, 0, 0]
	var all := [[], [], [], []]
	var turns := 0
	var done := 0
	var acorns := 0
	for r in runs:
		var run := Run.new(base_seed * 100003 + r, keeper, grade)
		turns += Bot.play_run(run)
		for i in run.scores.size():
			reached[i] += 1
			sums[i] += run.scores[i].total
			all[i].append(run.scores[i].total)
		done += 1 if run.done else 0
		acorns += run.acorns
	var out := {runs = runs, finished = float(done) / runs, acorns = float(acorns) / runs, turns = float(turns) / runs, seasons = []}
	var probe := Run.new(0, keeper, grade)
	for i in 4:
		all[i].sort()
		var pct := func(q: float) -> int: return all[i][int(q * (all[i].size() - 1))] if not all[i].is_empty() else 0
		out.seasons.append({
			target = probe.target_of(i),
			p10 = pct.call(0.1), p25 = pct.call(0.25), p50 = pct.call(0.5),
			reached = float(reached[i]) / runs,
			mean = float(sums[i]) / maxi(1, reached[i]),
		})
	return out
