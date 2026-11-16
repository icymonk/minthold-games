class_name Cards
extends RefCounted
## 기록 카드 0~42(기획서 2.1). 번호 n은 시각 17:18 + n분. 뛰기 값은 시뮬레이터로 조정할 초기값.

enum Zone { FLOOR, BUILDING, OUTSIDE }

const LAST := 42
const START_MINUTE := 17 * 60 + 18
const BASE_STEP := 3
## 사원이 42를 냈을 때 앞면 기록의 가장 큰 번호가 이 값 이하면 마지막 추궁(기획서 3.3).
## 3-2: 29 → 31로 꼼꼼 vs 꼼꼼 사원 승률 57% → 49%.
const MANHUNT_MAX := 31
const ZONE_RANGES := {
	Zone.FLOOR: Vector2i(4, 14),
	Zone.BUILDING: Vector2i(15, 28),
	Zone.OUTSIDE: Vector2i(29, 41),
}
const START_HAND: Array[int] = [1, 2, 3, LAST]
## 3-2 시뮬레이터(꼼꼼 vs 꼼꼼 1500판)로 3·2장에서 사원 승률 26% → 4·3장에서 55%.
const START_DRAWS := { Zone.FLOOR: 4, Zone.BUILDING: 3 }


static func time_text(n: int) -> String:
	var minute := START_MINUTE + n
	return "%d:%02d" % [minute / 60, minute % 60]


## 구역 더미에 들어가는 카드면 그 구역, 아니면(0~3, 42) -1.
static func zone_of(n: int) -> int:
	for z in ZONE_RANGES:
		var r: Vector2i = ZONE_RANGES[z]
		if n >= r.x and n <= r.y:
			return z
	return -1


static func zone_cards(z: int) -> Array[int]:
	var r: Vector2i = ZONE_RANGES[z]
	var out: Array[int] = []
	for n in range(r.x, r.y + 1):
		out.append(n)
	return out


## 발자국 수. 0과 42는 뛰기로 쓸 수 없다.
static func sprint_of(n: int) -> int:
	if n <= 0 or n >= LAST:
		return 0
	return 2 if n % 3 == 0 else 1
