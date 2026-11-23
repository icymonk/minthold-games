class_name MemDb
extends RefCounted
## 테스트용 가짜 데이터베이스: Fire와 같은 req()를 메모리 사전으로 흉내 낸다.
## 여러 MemDb가 같은 store를 나눠 쓰면 여러 기기처럼 움직인다. 방 만들기·행동은 이미 있으면 거절(규칙과 같다).

var store: Dictionary
var uid: String


func _init(shared: Dictionary, id: String) -> void:
	store = shared
	uid = id


func sign_in() -> String:
	return uid


func req(method: String, path: String, body: Variant = null, query := {}) -> Dictionary:
	await Engine.get_main_loop().process_frame
	var keys := path.split("/")
	var node: Variant = store
	for i in keys.size() - 1:
		if not (node as Dictionary).has(keys[i]):
			if method == "GET" or method == "DELETE":
				return {code = 200, data = null}
			node[keys[i]] = {}
		node = node[keys[i]]
	var last := keys[-1]
	match method:
		"GET":
			var v: Variant = (node as Dictionary).get(last)
			if v is Dictionary and query.has("startAt"):
				var out := {}
				for k: String in v:
					if k >= query.startAt:
						out[k] = v[k]
				v = out if not out.is_empty() else null
			return {code = 200, data = JSON.parse_string(JSON.stringify(v)) if v != null else null}
		"PUT":
			var strict := keys.size() == 2 or (keys.size() == 4 and keys[2] == "actions")
			if strict and (node as Dictionary).has(last):
				return {code = 401, data = null}
			node[last] = JSON.parse_string(JSON.stringify(body))
		"DELETE":
			(node as Dictionary).erase(last)
	return {code = 200, data = body}
