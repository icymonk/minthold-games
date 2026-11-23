class_name Online
extends Node
## 온라인 방: 방 코드로 모여 한 판(Match)을 같이 한다. 방에는 seed·자리 순서·행동 목록만 있고,
## 모든 기기가 같은 행동을 같은 순서로 Match에 넣어 같은 판을 만든다(규칙에 안 맞는 행동은 모두가 무시).
## 내 행동은 먼저 내 판에 넣고(바로 보이게) actions/aNNNNN에 쓴다. 그 칸이 이미 차 있으면 처음부터 다시 맞춘다.
## 방 구조: rooms/{code} = {host, status = lobby|play|done, seed, created, players/{uid} = {name, at}, order = [uid], actions/{aNNNNN} = {by, a}}

signal changed
## 행동 하나가 판에 들어갔다(who = 자리 번호)
signal applied(who: int)
## 판을 처음부터 다시 맞췄다(화면은 숲·손패를 다시 그린다)
signal resynced
signal failed(msg: String)

const POLL := 1.0
const CODE_CHARS := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const CODE_LEN := 5

## req(method, path, body, query) -> {code, data}, sign_in() -> uid 를 가진 것(Fire 또는 MemDb)
var db: Variant
var me := ""
var code := ""
var room := {}
var order: Array[String] = []
var seat := -1
var game: Match
var _seen := 0
var _queue: Array[Dictionary] = []
var _writing := false
var _polling := false
var _clock := 0.0


func _init(database: Variant) -> void:
	db = database
	if db is Node:
		add_child(db)


func sign_in() -> bool:
	if me == "":
		me = await db.sign_in()
	return me != ""


func is_host() -> bool:
	return room.get("host", "") == me


func status() -> String:
	return room.get("status", "")


## 방 사람들: [{uid, name}] 들어온 순서(판이 시작했으면 자리 순서)
func members() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var players: Dictionary = room.get("players", {}) if room.get("players") is Dictionary else {}
	if not order.is_empty():
		for u in order:
			out.append({uid = u, name = players.get(u, {}).get("name", "?")})
		return out
	for u: String in players:
		out.append({uid = u, name = players[u].get("name", "?"), at = players[u].get("at", 0)})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.at < b.at or (a.at == b.at and a.uid < b.uid))
	return out


func name_of(p: int) -> String:
	var m := members()
	return m[p].name if p >= 0 and p < m.size() else "?"


func create(nick: String) -> bool:
	if not await sign_in():
		return _fail("NET_ERR_SIGNIN")
	var now := int(Time.get_unix_time_from_system() * 1000.0)
	for attempt in 6:
		var c := ""
		for i in CODE_LEN:
			c += CODE_CHARS[randi() % CODE_CHARS.length()]
		var body := {host = me, status = "lobby", seed = randi() % 2147483647, created = now, players = {me: {name = nick, at = now}}}
		var r: Dictionary = await db.req("PUT", "rooms/" + c, body)
		if r.code == 200:
			code = c
			room = body
			order.clear()
			changed.emit()
			return true
		if r.code == 0:
			return _fail("NET_ERR_OFFLINE")
	return _fail("NET_ERR_CREATE")


func join(c: String, nick: String) -> bool:
	if not await sign_in():
		return _fail("NET_ERR_SIGNIN")
	c = c.strip_edges().to_upper()
	var r: Dictionary = await db.req("GET", "rooms/" + c)
	if r.code == 0:
		return _fail("NET_ERR_OFFLINE")
	if not r.data is Dictionary:
		return _fail("NET_ERR_NO_ROOM")
	var players: Dictionary = r.data.get("players", {})
	if r.data.get("status") != "lobby" and not players.has(me):
		return _fail("NET_ERR_STARTED")
	if not players.has(me) and players.size() >= Match.MAX_PLAYERS:
		return _fail("NET_ERR_FULL")
	if not players.has(me):
		var w: Dictionary = await db.req("PUT", "rooms/%s/players/%s" % [c, me], {name = nick, at = int(Time.get_unix_time_from_system() * 1000.0)})
		if w.code != 200:
			return _fail("NET_ERR_STARTED")
	code = c
	await poll()
	return true


func leave() -> void:
	if code != "" and status() == "lobby":
		db.req("DELETE", "rooms/%s/players/%s" % [code, me])
	code = ""
	room = {}
	order.clear()
	game = null
	seat = -1


## 방장: 지금 모인 사람(2~5명)으로 시작한다.
func start() -> bool:
	var m := members()
	if not is_host() or m.size() < Match.MIN_PLAYERS:
		return false
	var ids: Array = m.slice(0, Match.MAX_PLAYERS).map(func(x: Dictionary) -> String: return x.uid)
	if (await db.req("PUT", "rooms/%s/order" % code, ids)).code != 200:
		return _fail("NET_ERR_OFFLINE")
	if (await db.req("PUT", "rooms/%s/status" % code, "play")).code != 200:
		return _fail("NET_ERR_OFFLINE")
	await poll()
	return true


func my_turn() -> bool:
	return game != null and not game.over() and game.turn == seat


## 내 차례 행동. 규칙에 맞으면 바로 내 판에 넣고 방에 쓴다.
func act(a: Dictionary) -> bool:
	if not my_turn() or not game.act(seat, a):
		return false
	_queue.append({i = _seen, a = a})
	_seen += 1
	applied.emit(seat)
	_flush()
	return true


func _process(delta: float) -> void:
	if code == "":
		return
	_clock += delta
	if _clock >= POLL:
		_clock = 0.0
		poll()


## 방 상태(대기실) 또는 새 행동(판 중)을 받아 온다.
func poll() -> void:
	if _polling or code == "":
		return
	_polling = true
	if game == null:
		var r: Dictionary = await db.req("GET", "rooms/" + code)
		if r.code == 200 and r.data is Dictionary:
			room = r.data
			if room.get("status") == "play" and room.get("order") is Array:
				_begin()
			changed.emit()
		elif r.code == 200:
			_fail("NET_ERR_NO_ROOM")
			code = ""
	elif _queue.is_empty() and not _writing:
		var r: Dictionary = await db.req("GET", "rooms/%s/actions" % code, null, {orderBy = "$key", startAt = _key(_seen)})
		if r.code == 200 and r.data is Dictionary and game != null:
			_apply_all(r.data)
	_polling = false


func _begin() -> void:
	order.clear()
	for u in room.order:
		order.append(String(u))
	seat = order.find(me)
	game = Match.new(order.size(), int(room.seed))
	_seen = 0


func _apply_all(actions: Dictionary) -> void:
	var keys := actions.keys()
	keys.sort()
	for k: String in keys:
		var i := int(k.substr(1))
		if i < _seen:
			continue
		if i > _seen:
			break
		var x: Dictionary = actions[k]
		var who := order.find(String(x.get("by", "")))
		_seen = i + 1
		if who >= 0 and x.get("a") is Dictionary and game.act(who, x.a):
			applied.emit(who)


func _flush() -> void:
	if _writing:
		return
	_writing = true
	while not _queue.is_empty():
		var q: Dictionary = _queue[0]
		var r: Dictionary = await db.req("PUT", "rooms/%s/actions/%s" % [code, _key(q.i)], {by = me, a = q.a})
		if r.code == 0:
			await get_tree().create_timer(1.0).timeout
			continue
		_queue.pop_front()
		if r.code != 200:
			_queue.clear()
			await _reload()
	_writing = false


## 방의 행동 목록 전체로 판을 처음부터 다시 만든다(내가 쓴 칸을 누가 먼저 썼을 때).
func _reload() -> void:
	var r: Dictionary = await db.req("GET", "rooms/%s/actions" % code)
	_begin()
	if r.code == 200 and r.data is Dictionary:
		_apply_all(r.data)
	resynced.emit()


static func _key(i: int) -> String:
	return "a%05d" % i


func _fail(msg: String) -> bool:
	failed.emit(msg)
	return false
