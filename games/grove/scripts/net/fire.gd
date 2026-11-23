class_name Fire
extends Node
## Firebase REST(익명 로그인 + Realtime Database). 브라우저·맥 모두 HTTPRequest 하나로 돈다.
## req()는 {code, data}를 돌려준다(code 0 = 연결 실패). 토큰은 만료 1분 전에 새로 받는다.

## 웹 앱 설정값: 공개값이다(보안은 database.rules.json이 맡는다)
const API_KEY := "AIzaSyD2CMNx3EbPj5umKlLe_2Sv8vNzggoi_oI"
const DB_URL := "https://minthold-preview-default-rtdb.asia-southeast1.firebasedatabase.app"
const SAVE := "user://net.cfg"
const TIMEOUT := 10.0

var uid := ""
var _token := ""
var _refresh := ""
var _expires := 0.0


## 익명 로그인(전에 받은 계정이 있으면 그대로 쓴다). 실패하면 "".
func sign_in() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		_refresh = cfg.get_value("auth", "refresh", "")
	if _refresh != "" and await _renew():
		return uid
	var r := await _http("https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + API_KEY, HTTPClient.METHOD_POST, JSON.stringify({returnSecureToken = true}))
	if r.code != 200 or not r.data is Dictionary:
		return ""
	_take(r.data.idToken, r.data.refreshToken, r.data.localId, r.data.expiresIn)
	return uid


func req(method: String, path: String, body: Variant = null, query := {}) -> Dictionary:
	if _token == "" or Time.get_unix_time_from_system() > _expires - 60.0:
		if not await _renew():
			return {code = 0, data = null}
	var url := "%s/%s.json?auth=%s" % [DB_URL, path, _token]
	for k: String in query:
		url += "&%s=%s" % [k, JSON.stringify(query[k]).uri_encode()]
	var m: int = {"GET": HTTPClient.METHOD_GET, "PUT": HTTPClient.METHOD_PUT, "PATCH": HTTPClient.METHOD_PATCH, "DELETE": HTTPClient.METHOD_DELETE}[method]
	return await _http(url, m, "" if body == null else JSON.stringify(body))


func _renew() -> bool:
	if _refresh == "":
		return false
	var r := await _http("https://securetoken.googleapis.com/v1/token?key=" + API_KEY, HTTPClient.METHOD_POST,
		"grant_type=refresh_token&refresh_token=" + _refresh.uri_encode(), "application/x-www-form-urlencoded")
	if r.code != 200 or not r.data is Dictionary:
		return false
	_take(r.data.id_token, r.data.refresh_token, r.data.user_id, r.data.expires_in)
	return true


func _take(token: String, refresh: String, id: String, expires: Variant) -> void:
	_token = token
	_refresh = refresh
	uid = id
	_expires = Time.get_unix_time_from_system() + float(expires)
	var cfg := ConfigFile.new()
	cfg.set_value("auth", "refresh", refresh)
	cfg.save(SAVE)


func _http(url: String, method: int, body := "", type := "application/json") -> Dictionary:
	var h := HTTPRequest.new()
	h.timeout = TIMEOUT
	add_child(h)
	if h.request(url, PackedStringArray(["Content-Type: " + type]), method, body) != OK:
		h.queue_free()
		return {code = 0, data = null}
	var res: Array = await h.request_completed
	h.queue_free()
	var text := (res[3] as PackedByteArray).get_string_from_utf8()
	return {code = res[1] if res[0] == HTTPRequest.RESULT_SUCCESS else 0, data = JSON.parse_string(text) if text != "" else null}
