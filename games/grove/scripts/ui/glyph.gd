class_name Glyph
extends RefCounted
## 글 속 {이름} 토큰을 아이콘으로 바꿔 그린다: "{deck}+1" → [덱 그림]+1.
## links: 아이콘과 [[용어]] 표시를 눌러 볼 수 있는 링크(meta = "ICON_DECK" / "TERM_DECK")로 만든다.

static var _re: RegEx


static func _regex() -> RegEx:
	if _re == null:
		_re = RegEx.create_from_string("\\{([a-z_]+)\\}|\\[\\[([A-Z_]+)\\|([^\\]]+)\\]\\]")
	return _re


## RichTextLabel 끝에 text를 붙인다(아이콘 크기 = size)
static func fill(rt: RichTextLabel, text: String, size: int, links := false, link_color := Color("#FFD27A")) -> void:
	var at := 0
	for m in _regex().search_all(text):
		if m.get_start() > at:
			rt.add_text(text.substr(at, m.get_start() - at))
		if m.get_string(1) != "":
			var name := StringName(m.get_string(1))
			var tex := Art.icon(name)
			if tex == null:
				rt.add_text(m.get_string())
			elif links:
				rt.push_meta("ICON_" + String(name).to_upper())
				rt.add_image(tex, size, size)
				rt.pop()
			else:
				rt.add_image(tex, size, size)
		elif links:
			rt.push_meta(m.get_string(2))
			rt.push_color(link_color)
			rt.push_underline()
			rt.add_text(m.get_string(3))
			rt.pop()
			rt.pop()
			rt.pop()
		else:
			rt.add_text(m.get_string(3))
		at = m.get_end()
	if at < text.length():
		rt.add_text(text.substr(at))


## 크기 재기용: 아이콘 하나를 글자 두 개 폭으로 친다
static func measure(text: String) -> String:
	return _regex().sub(text, "MM", true).replace("[[", "")


## 글에 나온 아이콘 이름들(나온 순서, 중복 없이)
static func icons_in(text: String) -> Array[StringName]:
	var out: Array[StringName] = []
	for m in _regex().search_all(text):
		var n := StringName(m.get_string(1))
		if n != &"" and Art.icon(n) != null and not n in out:
			out.append(n)
	return out


## 토큰 없는 글(테스트·툴팁)
static func plain(text: String) -> String:
	var out := text
	for m in _regex().search_all(text):
		out = out.replace(m.get_string(), m.get_string(3) if m.get_string(1) == "" else "")
	return out
