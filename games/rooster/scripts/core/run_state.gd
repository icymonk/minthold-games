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
const BAG_WIDTH := 5
const BAG_WIDE_NIGHT := 4

var seed: int
var night: int = 1
var lanterns: int = START_LANTERNS
var rng: RngStreams
var coins := 0
var bag := Bag.new(BAG_WIDTH, BAG_HEIGHT)
var bench: Array[Piece] = []
var shelf: Array[StringName] = []
var procession: Procession


func _init(run_seed: int) -> void:
	seed = run_seed
	rng = RngStreams.new(run_seed)
	start_night()


## 밤 시작: 엽전 지급(이월 상한), 보따리 확장, 진열대 갱신, 이번 행렬 결정.
func start_night() -> void:
	coins = mini(coins, CARRY_MAX) + INCOME
	if night >= BAG_WIDE_NIGHT:
		bag.width = BAG_WIDTH + 1
	_roll_shelf()
	procession = Procession.for_night(night, BAG_HEIGHT, rng.events)


func _roll_shelf() -> void:
	var kinds := YokaiDb.ally_kinds()
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
