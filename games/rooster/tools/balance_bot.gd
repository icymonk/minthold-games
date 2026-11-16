extends SceneTree
## 단순 봇으로 원정을 돌려 밤별 승률을 본다: godot --headless -s tools/balance_bot.gd
## 환경 변수 BOT_FEED=1이면 보따리가 차서 남는 요괴가 생길 때 먹여서 자리를 만든다.

var feed := OS.get_environment("BOT_FEED") == "1"


func _init() -> void:
	var wins_by_night := {}
	var reached := {}
	var runs := 200
	for s in runs:
		var run := RunState.new(s)
		while not run.is_over():
			_shop(run)
			var night := run.night
			var sim := run.fight()
			wins_by_night[night] = wins_by_night.get(night, 0) + (1 if sim.won else 0)
			reached[night] = reached.get(night, 0) + 1
			run.finish_battle(sim)
		reached["victory"] = reached.get("victory", 0) + (1 if run.is_victory() else 0)
	for n in range(1, 8):
		print("night %d: %d/%d won" % [n, wins_by_night.get(n, 0), reached.get(n, 0)])
	print("victories: %d/%d" % [reached.get("victory", 0), runs])
	quit()


func _shop(run: RunState) -> void:
	for i in run.shelf.size():
		run.hire(i)
	for p in run.bench.duplicate():
		if _fit(run.bag, p):
			run.bench.erase(p)
	while feed and not run.bench.is_empty() and _feed_once(run):
		for p in run.bench.duplicate():
			if _fit(run.bag, p):
				run.bench.erase(p)
	# 자리가 없으면 내보낸다.
	for p in run.bench.duplicate():
		run.sell(p)


func _fit(bag: Bag, p: Piece) -> bool:
	for r in 4:
		for x in range(bag.width - 1, -1, -1):
			for y in bag.height:
				if bag.place(p, Vector2i(x, y)):
					return true
		p.rotate_cw()
	return false


## 자리가 없어 남은 요괴를 보따리 요괴에게 먹인다. 같은 종류, 그다음 변신에 가까운 요괴를 고른다.
func _feed_once(run: RunState) -> bool:
	for f in run.bench.duplicate():
		var eaters := run.bag.pieces.filter(func(p: Piece) -> bool: return p.hungry())
		eaters.sort_custom(func(a: Piece, b: Piece) -> bool:
			var sa := 0 if a.base_kind() == f.base_kind() else 1
			var sb := 0 if b.base_kind() == f.base_kind() else 1
			return sa < sb or (sa == sb and a.belly - a.eaten < b.belly - b.eaten))
		for e in eaters:
			var r := run.feed(e, f)
			if r == Bag.Feed.OK or r == Bag.Feed.EVOLVED:
				return true
	return false
