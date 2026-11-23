class_name Forest
extends RefCounted
## 숲(규칙 1-1): 땅 자리마다 나무 또는 묘목, 나무마다 4방향 자리, 그리고 굴.
## 자리 하나에 이웃 하나. 겹치는 종(산토끼)만 같은 종끼리 STACK마리까지.

const SIDES: Array[StringName] = [&"Top", &"Bottom", &"Left", &"Right"]
const SAPLING := &"sapling"
const STACK := 5
const MAX_PLOTS := 25

var plots := 9
## 땅 자리 → {card, kind(나무 종 또는 sapling), sides = {side: [{card, species}]}}
var trees := {}
var cave: Array[Dictionary] = []


func is_free(plot: int) -> bool:
	return plot >= 0 and plot < plots and not trees.has(plot)


func free_plots() -> Array[int]:
	var out: Array[int] = []
	for p in plots:
		if is_free(p):
			out.append(p)
	return out


func plant(plot: int, card: Dictionary, kind: StringName) -> bool:
	if not is_free(plot):
		return false
	var sides := {}
	for s in SIDES:
		sides[s] = []
	trees[plot] = {card = card, kind = kind, sides = sides}
	return true


func kind_at(plot: int) -> StringName:
	return trees[plot].kind if trees.has(plot) else &""


func occupants(plot: int, side: StringName) -> Array:
	return trees[plot].sides[side] if trees.has(plot) else []


func can_attach(plot: int, side: StringName, species: StringName) -> bool:
	if not trees.has(plot) or not Cards.fits(species, side):
		return false
	var here := occupants(plot, side)
	if here.is_empty():
		return true
	var stacks: bool = Cards.SPECIES[species].get("stack", false)
	return stacks and here.size() < STACK and here.all(func(o: Dictionary) -> bool: return o.species == species)


func attach(plot: int, side: StringName, card: Dictionary, species: StringName) -> bool:
	if not can_attach(plot, side, species):
		return false
	occupants(plot, side).append({card = card, species = species})
	return true


func is_complete(plot: int) -> bool:
	return trees.has(plot) and SIDES.all(func(s: StringName) -> bool: return not occupants(plot, s).is_empty())


## 숲의 모든 이웃: [{plot, side, card, species}]
func neighbors() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in trees:
		for s in SIDES:
			for o in occupants(p, s):
				out.append({plot = p, side = s, card = o.card, species = o.species})
	return out


## 그 자리에 붙일 수 있는 곳들: [{plot, side}]
func targets(species: StringName, side: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in plots:
		if can_attach(p, side, species):
			out.append({plot = p, side = side})
	return out


## 이웃이 하나도 없는 나무를 벤다(벌목꾼 측량). 벤 땅 자리들을 돌려준다.
func cut_bare() -> Array[int]:
	var cut: Array[int] = []
	for p in trees.keys():
		if SIDES.all(func(s: StringName) -> bool: return occupants(p, s).is_empty()):
			trees.erase(p)
			cut.append(p)
	return cut


## 땅 넓히기(오두막): 땅 자리 n칸을 더 연다.
func expand(n := 2) -> bool:
	if plots >= MAX_PLOTS:
		return false
	plots = mini(plots + n, MAX_PLOTS)
	return true


## 봇이 미리 계산할 때 쓰는 깊은 복사
func clone() -> Forest:
	var f := Forest.new()
	f.plots = plots
	f.trees = trees.duplicate(true)
	f.cave = cave.duplicate()
	return f
