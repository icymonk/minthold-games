class_name Cards
extends RefCounted
## 카드 13종 표(기획서 3장). 금액은 시뮬레이터로 조정할 초기값.

enum Id { NEWBIE, THIEF, BUDDY, MISER, CHAIR, ACCOUNTANT, HR, SNIFFER, BUSYBODY, BROADCAST, SUPPLIES, BOSS, QUITTER }
enum Win { CONFINED, NOT_CONFINED, THIEF_WINS, FUND_FAILED, FUND_OK, NOBODY_WON }

const DEFS := {
	Id.NEWBIE: { key = &"NEWBIE", count = 1, amount = 1, win = Win.CONFINED, priority = 1 },
	Id.THIEF: { key = &"THIEF", count = 1, amount = 0, win = Win.NOT_CONFINED, priority = 2, playable = false },
	Id.BUDDY: { key = &"BUDDY", count = 2, amount = 1, win = Win.THIEF_WINS, priority = 2 },
	Id.MISER: { key = &"MISER", count = 3, amount = 0, win = Win.FUND_FAILED, priority = 3 },
	Id.CHAIR: { key = &"CHAIR", count = 1, amount = 1, win = Win.FUND_OK, priority = 4 },
	Id.ACCOUNTANT: { key = &"ACCOUNTANT", count = 3, amount = 2, win = Win.FUND_OK, priority = 4 },
	Id.HR: { key = &"HR", count = 2, amount = 1, win = Win.FUND_OK, priority = 4 },
	Id.SNIFFER: { key = &"SNIFFER", count = 2, amount = 1, win = Win.FUND_OK, priority = 4 },
	Id.BUSYBODY: { key = &"BUSYBODY", count = 2, amount = 2, win = Win.FUND_OK, priority = 4 },
	Id.BROADCAST: { key = &"BROADCAST", count = 2, amount = 2, win = Win.FUND_OK, priority = 4 },
	Id.SUPPLIES: { key = &"SUPPLIES", count = 2, amount = 3, win = Win.FUND_OK, priority = 4 },
	Id.BOSS: { key = &"BOSS", count = 2, amount = 3, win = Win.NOT_CONFINED, priority = 4 },
	Id.QUITTER: { key = &"QUITTER", count = 2, amount = 0, win = Win.NOBODY_WON, priority = 5 },
}

## 인원별로 기본 25장에서 빼는 카드(기획서 3.1).
const REMOVED := {
	3: [Id.ACCOUNTANT, Id.HR, Id.BUSYBODY, Id.BROADCAST, Id.SUPPLIES, Id.MISER, Id.QUITTER],
	4: [Id.ACCOUNTANT],
	5: [],
	6: [Id.BUDDY],
}

## 인원별로 더하는 카드. 6인은 30장(1인 5장)으로 늘려 단서를 모을 차례를 5인과 맞춘다.
const ADDED := {
	3: [],
	4: [],
	5: [],
	6: [Id.SNIFFER, Id.SNIFFER, Id.HR, Id.BUSYBODY, Id.BROADCAST, Id.SUPPLIES],
}

## 인원별 목표액(기획서 3.1). 3-2 시뮬레이터로 맞춘 값.
const TARGET := { 3: 6, 4: 8, 5: 7, 6: 8 }

const MAX_PRIORITY := 5

## 시뮬레이터 전용 덮어쓰기: { target = int, add = [id], remove = [id] }.
static var tune := {}


static func amount(id: int) -> int:
	return DEFS[id].amount


static func priority(id: int) -> int:
	return DEFS[id].priority


static func win(id: int) -> Win:
	return DEFS[id].win


static func playable(id: int) -> bool:
	return DEFS[id].get(&"playable", true)


static func name_key(id: int) -> String:
	return "CARD_%s" % DEFS[id].key


static func target(players: int) -> int:
	return tune.get(&"target", TARGET[players])


## 인원수에 맞춘 덱(섞기 전, 카드 종류 id 목록).
static func deck(players: int) -> Array[int]:
	var out: Array[int] = []
	for id in DEFS:
		for i in DEFS[id].count:
			out.append(id)
	for id in REMOVED[players]:
		out.erase(id)
	for id in ADDED[players] + tune.get(&"add", []):
		out.append(id)
	for id in tune.get(&"remove", []):
		out.erase(id)
	return out
