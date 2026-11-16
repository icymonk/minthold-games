class_name PullSim
extends RefCounted
## 식탁보 한 번 당기기 판정(기획서 3.2). 같은 입력이면 같은 결과가 나온다.
## 식탁보는 식탁 왼쪽 끝(x=0)부터 깔려 있고 오른쪽으로 빠진다.

enum Outcome { STAYED, TIPPED, FELL }

const GRAVITY := 981.0
const TABLE_GRIP := 0.5
## 이 시간보다 짧게 천이 지나가면 넘어지려는 힘이 그만큼 덜 쌓인다(초).
const TIP_BUILD_TIME := 0.15
const PERFECT_SLIDE := 0.5
const NEAR_EDGE := 2.0
const MIRACLE_TIP := 0.9
const BUMP_TIP := 0.35
const MAX_LIFT := 0.9


class Pull:
	## 당기는 속도(cm/s).
	var speed: float
	## 위로 당긴 각도(도). 0 이하는 수평 또는 아래.
	var angle: float
	## 중간에 멈칫한 정도 0~1. 그만큼 천 마찰이 커진다.
	var wobble: float

	func _init(speed_: float, angle_ := 0.0, wobble_ := 0.0) -> void:
		speed = speed_
		angle = angle_
		wobble = clampf(wobble_, 0.0, 1.0)


class Result:
	var dish: Dish
	var outcome: Outcome
	## 오른쪽으로 끌려간 거리(cm).
	var slide: float
	var final_x: float
	## 넘어짐 기준 대비 비율. 1 이상이면 넘어진다.
	var tip: float
	var bumped := false

	func perfect() -> bool:
		return outcome == Outcome.STAYED and slide < PERFECT_SLIDE

	func miracle() -> bool:
		return outcome == Outcome.STAYED and tip >= MIRACLE_TIP


var table_length: float


func _init(table_length_ := 160.0) -> void:
	table_length = table_length_


func run(dishes: Array[Dish], pull: Pull) -> Array[Result]:
	var lift := minf(maxf(sin(deg_to_rad(pull.angle)), 0.0) * 1.5, MAX_LIFT)
	var results: Array[Result] = []
	for dish in dishes:
		results.append(_slide(dish, pull, lift))
	_bump(results)
	for r in results:
		if r.final_x > table_length:
			r.outcome = Outcome.FELL
		elif r.tip >= 1.0:
			r.outcome = Outcome.TIPPED
		else:
			r.outcome = Outcome.STAYED
	return results


func near_edge(r: Result) -> bool:
	return r.outcome == Outcome.STAYED and table_length - (r.final_x + r.dish.width / 2.0) < NEAR_EDGE


func _slide(dish: Dish, pull: Pull, lift: float) -> Result:
	var grip := dish.grip * (1.0 + pull.wobble)
	var accel := grip * GRAVITY
	var contact := dish.right() / maxf(pull.speed, 1.0)
	var dragged := 0.5 * accel * contact * contact
	var carried := accel * contact
	var skid := carried * carried / (2.0 * TABLE_GRIP * GRAVITY)
	var r := Result.new()
	r.dish = dish
	r.slide = dragged + skid
	r.final_x = dish.x + r.slide
	var build := minf(contact / TIP_BUILD_TIME, 1.0)
	r.tip = grip * dish.height / dish.width * build / (1.0 - lift)
	return r


## 끝 위치가 겹치거나 서로 지나쳤으면 부딪힌 것이다.
func _bump(results: Array[Result]) -> void:
	for i in results.size():
		for j in range(i + 1, results.size()):
			var a := results[i]
			var b := results[j]
			var crossed := signf(a.final_x - b.final_x) != signf(a.dish.x - b.dish.x)
			var overlap := absf(a.final_x - b.final_x) < (a.dish.width + b.dish.width) / 2.0
			if crossed or overlap:
				for r: Result in [a, b]:
					if not r.bumped:
						r.bumped = true
						r.tip += BUMP_TIP
