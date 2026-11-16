class_name Knowledge
extends RefCounted
## 한 자리가 아는 것만 모은 보기(기획서 4장). 화면과 Bot은 Match 대신 이것만 읽는다.
## 뒷면 카드는 위치(uid)만 보이고, 종류는 `known`에 있을 때만 안다.

var seat: int
var players: int
var target: int
var turn: int
var out: Array[bool] = []
var hand: Array[int] = []
var hand_counts: Array[int] = []
var face_up: Array = []    # seat → Array[int] uid (종류 공개)
var envelope: Array[int] = []
var notes: Array = []      # seat → Array[int] uid
var placed_by := {}
var known := {}            # uid → Cards.Id
var located := {}          # uid → 마지막으로 그 카드를 쥐고 있던 걸 본 seat (지금도 거기 있다는 보장은 없다)
var thief_hint := Match.NO_HINT
var request := {}


static func of(m: Match, s: int) -> Knowledge:
	var k := Knowledge.new()
	k.seat = s
	k.players = m.players
	k.target = m.target
	k.turn = m.turn
	k.out = m.out.duplicate()
	k.hand = m.hands[s].duplicate()
	for p in m.players:
		k.hand_counts.append(m.hands[p].size())
		k.face_up.append(m.face_up[p].duplicate())
		k.notes.append(m.notes[p].duplicate())
		for uid in m.face_up[p]:
			k.known[uid] = m.kinds[uid]
	k.envelope = m.envelope.duplicate()
	k.placed_by = m.placed_by.duplicate()
	for uid in m.seen[s]:
		k.known[uid] = m.kinds[uid]
	k.located = m.located[s].duplicate()
	k.thief_hint = m.sniffs[s]
	k.request = m.request_for(s)
	return k


func kind_of(uid: int) -> int:
	return known.get(uid, -1)
