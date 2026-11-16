class_name RunState
extends RefCounted
## 원정 한 판의 진행 상태. 씬 트리에 의존하지 않는 순수 로직.

const NIGHTS := 7
const BOSS_NIGHTS: Array[int] = [3, 7]
const START_LANTERNS := 3
const BOSS_LANTERN_LOSS := 2
const INCOME := 10
const CARRY_MAX := 5
const SHELF_SIZE := 5
const REFRESH_COST := 1
const SELL_REFUND := 1
const BENCH_MAX := 6
const BAG_HEIGHT := 4
## 보따리가 넓어질 수 있는 최대 가로 칸.
const BAG_WIDTH := 8
## 시작 보따리: 앞(오른쪽) 3줄을 채우고, 무작위로 4칸을 더 붙인다. 판마다 모양이 다르다.
const BAG_START_COLS := 3
const BAG_START_GROW := 4
const SKIP_PLOT_COINS := 1

var seed: int
var night: int = 1
var lanterns: int = START_LANTERNS
var rng: RngStreams
var coins := 0
var bag := Bag.new(BAG_WIDTH, BAG_HEIGHT, false)
## 이번 밤에 고를 수 있는 보따리 조각. 고르거나 건너뛰면 비운다.
var plots: Array[Plot] = []
var bench: Array[Piece] = []
var shelf: Array[StringName] = []
var procession: Procession


func _init(run_seed: int) -> void:
	seed = run_seed
	rng = RngStreams.new(run_seed)
	_start_bag()
	start_night()


func _start_bag() -> void:
	for y in BAG_HEIGHT:
		for x in range(BAG_WIDTH - BAG_START_COLS, BAG_WIDTH):
			bag.open[Vector2i(x, y)] = true
	for i in BAG_START_GROW:
		var edge: Array[Vector2i] = []
		for c in bag.open:
			for d in Bag.DIRS:
				var n: Vector2i = c + d
				if bag.in_canvas(n) and not bag.open.has(n) and n not in edge:
					edge.append(n)
		edge.sort()
		bag.open[edge[rng.bag.randi_range(0, edge.size() - 1)]] = true


## 밤 시작: 엽전 지급(이월 상한), 보따리 조각 제안(둘째 밤부터), 진열대 갱신, 이번 행렬 결정.
func start_night() -> void:
	coins = mini(coins, CARRY_MAX) + INCOME
	plots.clear()
	if night > 1:
		plots = Plot.offers(rng.bag)
	_roll_shelf()
	procession = Procession.for_night(night, BAG_HEIGHT, rng.events)


func _roll_shelf() -> void:
	var kinds := YokaiDb.market_pool(night)
	shelf.clear()
	for i in SHELF_SIZE:
		shelf.append(kinds[rng.market.randi_range(0, kinds.size() - 1)])


func refresh_shelf() -> bool:
	if coins < REFRESH_COST:
		return false
	coins -= REFRESH_COST
	_roll_shelf()
	return true


func hire(slot: int) -> Piece:
	var kind := shelf[slot]
	if kind == &"" or coins < YokaiDb.cost(kind) or bench.size() >= BENCH_MAX:
		return null
	coins -= YokaiDb.cost(kind)
	shelf[slot] = &""
	var p := Piece.create(kind)
	bench.append(p)
	return p


## 장터에서 끌어다 보따리에 바로 놓는다. 자리나 엽전이 모자라면 아무것도 바꾸지 않는다.
func hire_to_bag(slot: int, cells: Array[Vector2i], at: Vector2i) -> Piece:
	var kind := shelf[slot]
	if kind == &"" or coins < YokaiDb.cost(kind):
		return null
	var p := Piece.create(kind)
	p.cells.assign(cells)
	if not bag.can_place(p, at):
		return null
	coins -= YokaiDb.cost(kind)
	shelf[slot] = &""
	bag.place(p, at)
	return p


## 제안된 조각 i를 (돌린 모양 plot으로) at에 붙인다. 붙이면 남은 제안은 사라진다.
func expand_bag(i: int, plot: Plot, at: Vector2i) -> bool:
	if i < 0 or i >= plots.size() or plot.cells.size() != plots[i].cells.size():
		return false
	if not bag.expand(plot, at):
		return false
	plots.clear()
	return true


## 조각을 고르지 않으면 엽전을 조금 받는다.
func skip_plots() -> void:
	if plots.is_empty():
		return
	plots.clear()
	coins += SKIP_PLOT_COINS


## 보따리나 대기 줄에 있는 요괴끼리 먹인다. 대기 줄에서 먹힌 요괴는 줄에서 빠진다.
func feed(eater: Piece, food: Piece) -> Bag.Feed:
	var r := bag.feed(eater, food)
	if r == Bag.Feed.OK or r == Bag.Feed.EVOLVED:
		bench.erase(food)
	return r


## 장터 요괴를 고용하자마자 eater에게 먹인다. 먹이지 못하면 엽전을 쓰지 않는다.
func hire_feed(slot: int, eater: Piece) -> Bag.Feed:
	var kind: StringName = shelf[slot]
	if kind == &"" or coins < YokaiDb.cost(kind):
		return Bag.Feed.SELF
	var food := Piece.create(kind)
	var r := bag.feed(eater, food)
	if r == Bag.Feed.OK or r == Bag.Feed.EVOLVED:
		coins -= YokaiDb.cost(kind)
		shelf[slot] = &""
	return r


func sell(p: Piece) -> void:
	bag.remove(p)
	bench.erase(p)
	coins += SELL_REFUND


func fight() -> BattleSim:
	return BattleSim.new(bag, procession, rng.battle).run()


## 전투 결과 반영. 원정이 끝나지 않았으면 다음 밤을 연다.
func finish_battle(sim: BattleSim) -> void:
	coins += sim.coins
	if sim.won:
		win_night()
	else:
		lose_night()
	if not is_over():
		start_night()


func is_boss_night() -> bool:
	return night in BOSS_NIGHTS


func win_night() -> void:
	assert(not is_over())
	night += 1


func lose_night() -> void:
	assert(not is_over())
	var loss := BOSS_LANTERN_LOSS if is_boss_night() else 1
	lanterns = maxi(lanterns - loss, 0)
	if lanterns > 0:
		night += 1


func is_victory() -> bool:
	return night > NIGHTS and lanterns > 0


func is_defeat() -> bool:
	return lanterns <= 0


func is_over() -> bool:
	return is_victory() or is_defeat()
