extends SceneTree
## 헤드리스 시뮬레이터: 탐욕 봇으로 런을 돌려 밤별 통과율, 조합별 사용 비율, 꿀팁별 승률을 본다.
## godot --headless -s tools/sim.gd -- --runs 200 --seed 1


func _init() -> void:
	var args := {}
	var argv := OS.get_cmdline_user_args()
	for i in range(0, argv.size() - 1, 2):
		args[argv[i].trim_prefix("--")] = argv[i + 1]
	var runs := int(args.get("runs", "100"))
	var base_seed := int(args.get("seed", "1"))
	var reached := {}
	var wins := 0
	var combos := {}
	var tip_runs := {}
	var tip_wins := {}
	for k in runs:
		var run := Run.new(base_seed + k)
		Bot.play_out(run)
		var won := run.phase == Run.Phase.WON
		wins += int(won)
		reached[run.night] = reached.get(run.night, 0) + 1
		for kind in run.combo_counts:
			combos[kind] = combos.get(kind, 0) + run.combo_counts[kind]
		for h in run.tips:
			tip_runs[h.id] = tip_runs.get(h.id, 0) + 1
			tip_wins[h.id] = tip_wins.get(h.id, 0) + int(won)
	print("런 %d판, 완주 %.1f%%" % [runs, 100.0 * wins / runs])
	print("밤별 도달률")
	var alive := runs
	for n in range(1, Run.NIGHTS + 1):
		print("  %d일째 %5.1f%%" % [n, 100.0 * alive / runs])
		alive -= reached.get(n, 0)
	var total := 0
	for kind in combos:
		total += combos[kind]
	print("조합별 사용 비율")
	for kind in combos:
		print("  %-15s %5.1f%%" % [Combo.Kind.keys()[kind], 100.0 * combos[kind] / maxi(total, 1)])
	print("꿀팁별 승률(런 끝에 들고 있던 꿀팁)")
	for t in tip_runs:
		print("  %-13s %4d판 %5.1f%%" % [t, tip_runs[t], 100.0 * tip_wins[t] / tip_runs[t]])
	quit()
