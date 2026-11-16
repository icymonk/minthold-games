class_name Events
extends RefCounted
## 사건 카드(기획서 2.2, 선택 규칙). 구역 더미 번호와 겹치지 않게 BASE 이상 번호로 더미에 섞는다.
## 뽑은 사람이 바로 처리하고, 뽑기 횟수는 줄지 않는다(1장 더 뽑음).

enum Id { BADGE, CCTV, TIP_OFF, MEETING, BUSY, ON_CALL, ELEVATOR, EXCUSE, DINNER, CORRIDOR }

const BASE := 100
const PER_ZONE := 2
const ELEVATOR_BONUS := 2
## 사건마다 돕는 쪽. NONE은 둘 다.
const HELPS := {
	Id.BADGE: Match.Side.CHIEF, Id.CCTV: Match.Side.CHIEF, Id.TIP_OFF: Match.Side.CHIEF,
	Id.MEETING: Match.Side.CHIEF, Id.BUSY: Match.Side.STAFF, Id.ON_CALL: Match.Side.STAFF,
	Id.ELEVATOR: Match.Side.STAFF, Id.EXCUSE: Match.Side.STAFF, Id.DINNER: Match.NONE,
	Id.CORRIDOR: Match.NONE,
}


static func is_event(c: int) -> bool:
	return c >= BASE


static func id_of(c: int) -> int:
	return c - BASE


static func card_of(id: int) -> int:
	return BASE + id
