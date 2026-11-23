class_name Bot
extends RefCounted
## 탐욕 봇(규칙 1-3, tools/sim.gd용): 낼 수 있는 모든 수 중 숲 점수가 가장 많이 오르는 수를 둔다.
## 오르는 수가 없으면 2장 가져오고, 손패가 가득 차면 묘목을 심는다.


## 한 차례를 두고 end_turn까지 한다. 둘 수 없으면 false.
static func turn(s: Season, season_index: int, mods := {}) -> bool:
	var best := _best_play(s, season_index, mods)
	var acted := false
	if not best.is_empty() and (best.gain > 0 or s.hand.size() >= s.hand_limit):
		acted = s.play(best.id, best.half, best.plot, best.pay)
	# 공짜·두더지로 더 낼 수 있으면 오르는 수가 있는 동안 더 낸다. 라쿤(손패 굴에 넣기)은 넘긴다.
	while acted and (s.can_play_more() or s.wants_stash()):
		if s.wants_stash():
			s.stash([])
			continue
		var more := _best_play(s, season_index, mods)
		if more.is_empty() or more.gain <= 0 or not s.play(more.id, more.half, more.plot, more.pay):
			s.skip()
	if not acted and s.hand.size() < s.hand_limit:
		acted = s.draw()
		s.draw()
	if not acted and not s.hand.is_empty() and not s.forest.free_plots().is_empty():
		acted = s.sapling(_cheapest(s.hand, -1, 1, &"")[0], s.forest.free_plots()[0])
	s.end_turn()
	return acted or s.over


static func _best_play(s: Season, season_index: int, mods: Dictionary) -> Dictionary:
	var now := Score.count(s.forest, season_index, mods).total
	var best := {}
	for card in s.hand:
		for half in (1 if Cards.is_tree(card) else 2):
			var cost := s.cost_now(card, half)
			if cost > s.hand.size() - 1:
				continue
			var pay := _cheapest(s.hand, card.id, cost, Cards.sym_of(card, half))
			for plot in _plots(s.forest, card, half):
				if not s.can_play(card.id, half, plot, pay):
					continue
				var f := s.forest.clone()
				if Cards.is_tree(card):
					f.plant(plot, card, card.tree)
				else:
					f.attach(plot, Cards.side_of(card, half), card, card.halves[half])
				# 나무 심기는 앞으로 붙일 자리 4개의 값도 있다
				var gain := Score.count(f, season_index, mods).total - now - cost + (3 if Cards.is_tree(card) else 0)
				if best.is_empty() or gain > best.gain:
					best = {id = card.id, half = half, plot = plot, pay = pay, gain = gain}
	return best


static func _plots(f: Forest, card: Dictionary, half: int) -> Array[int]:
	if Cards.is_tree(card):
		return f.free_plots()
	var out: Array[int] = []
	for t in f.targets(card.halves[half], Cards.side_of(card, half)):
		out.append(t.plot)
	return out


## 비용으로 낼 카드: 같은 나무 색(보너스) 먼저, 그다음 아무거나
static func _cheapest(hand: Array[Dictionary], except: int, n: int, sym: StringName) -> Array[int]:
	var same: Array[int] = []
	var other: Array[int] = []
	for c in hand:
		if c.id == except:
			continue
		(same if Cards.has_sym(c, sym) else other).append(c.id)
	var out := same + other
	out.resize(mini(n, out.size()))
	return out


## 보상 고르기: 정령 > 새 카드 > 빼기
static func pick_reward(run: Run) -> int:
	for want: StringName in [&"spirit", &"pair"]:
		for i in run.offers.size():
			if run.offers[i].t == want:
				return i
	return 0


## 한 해를 끝까지 둔다. 둔 차례 수를 돌려준다.
static func play_run(run: Run, max_turns := 400) -> int:
	var total := 0
	while not run.lost and not run.done:
		var s := run.begin()
		var turns := 0
		while not s.over and turns < max_turns:
			if not turn(s, run.season_index, run.score_mods()):
				break
			turns += 1
		total += turns
		run.finish()
		if not run.offers.is_empty():
			run.take(pick_reward(run))
		while run.acorns >= Reward.PRICES.land and run.forest.plots < Forest.MAX_PLOTS:
			run.buy({t = &"land"})
	return total
