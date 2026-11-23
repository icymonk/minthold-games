class_name Art
extends RefCounted
## 아이콘(Kenney Game Icons, CC0).

const ICON_HOME := preload("res://assets/art/kenney/icon_home.png")
const ICON_NEXT := preload("res://assets/art/kenney/icon_next.png")
const ICON_RETRY := preload("res://assets/art/kenney/icon_retry.png")
const ICON_SETTINGS := preload("res://assets/art/kenney/icon_settings.png")
const ICON_HELP := preload("res://assets/art/kenney/icon_help.png")
const ICON_SOUND_ON := preload("res://assets/art/kenney/icon_sound_on.png")
const ICON_SOUND_OFF := preload("res://assets/art/kenney/icon_sound_off.png")

static var _acorn: Texture2D


## 점수 표시용 도토리(코드로 그린다)
static func acorn() -> Texture2D:
	if _acorn:
		return _acorn
	const N := 64
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	var body := Color("#C98A45")
	var shade := Color("#9A6230")
	var cap := Color("#6B4526")
	var line := Color("#4A2E18")
	for y in N:
		for x in N:
			var u := (x + 0.5) / N - 0.5
			var v := (y + 0.5) / N
			var c := Color.TRANSPARENT
			# 몸통: 아래로 뾰족한 타원
			var by := (v - 0.62) / 0.36
			var bx := u / (0.3 * (1.0 - maxf(by, 0.0) * 0.35))
			if bx * bx + by * by <= 1.0:
				c = body.lerp(shade, clampf(u * 2.0 + 0.3, 0.0, 1.0) * 0.7)
				if u < -0.1 and by < 0.0 and by > -0.6:
					c = c.lightened(0.18)
			# 깍정이: 위쪽 반달
			var cy := (v - 0.36) / 0.17
			var cx := u / 0.36
			if cx * cx + cy * cy <= 1.0 and v < 0.46:
				c = cap
				if (int(x / 6.0) + int(y / 6.0)) % 2 == 0:
					c = cap.darkened(0.15)
			# 꼭지
			if absf(u - 0.03) < 0.045 and v > 0.08 and v < 0.22:
				c = line
			img.set_pixel(x, y, c)
	_acorn = ImageTexture.create_from_image(img)
	return _acorn


static var _icons := {}
const _O := ' stroke="#2B3A2A" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"'
## 카드 기호 아이콘(SVG로 그린다). 글 속 {이름} 토큰이 이 그림이 된다(Glyph).
const ICONS := {
	&"g_tree": '<path d="M32 6 L52 34 H40 L54 50 H10 L24 34 H12 Z" fill="#5E9B4A"%s/><rect x="28" y="50" width="8" height="10" fill="#7A5132"%s/>',
	&"g_bird": '<path d="M8 30 L20 34 L14 46 L26 40 C30 50 44 52 50 42 C54 36 54 30 50 24 L58 20 L50 18 C46 10 34 10 30 18 C28 22 28 28 30 32 L22 26 Z" fill="#6FA8DC"%s/><path d="M32 34 C38 40 46 38 48 32" fill="none"%s/><circle cx="44" cy="20" r="2.5" fill="#2B3A2A"/>',
	&"g_bat": '<path d="M32 22 L36 16 L37 24 C46 18 56 20 60 26 C54 28 52 34 54 40 C48 36 42 38 38 44 L32 40 L26 44 C22 38 16 36 10 40 C12 34 10 28 4 26 C8 20 18 18 27 24 L28 16 Z" fill="#6B5A7A"%s/>',
	&"g_butterfly": '<ellipse cx="20" cy="22" rx="13" ry="11" fill="#F2A65A"%s/><ellipse cx="44" cy="22" rx="13" ry="11" fill="#F2A65A"%s/><ellipse cx="22" cy="44" rx="10" ry="9" fill="#E07B5A"%s/><ellipse cx="42" cy="44" rx="10" ry="9" fill="#E07B5A"%s/><rect x="29" y="14" width="6" height="40" rx="3" fill="#2B3A2A"/>',
	&"g_insect": '<circle cx="32" cy="16" r="7" fill="#3E5F3A"%s/><ellipse cx="32" cy="38" rx="14" ry="18" fill="#7FB04F"%s/><path d="M32 22 V56 M18 30 L8 24 M18 40 L6 40 M18 50 L8 56 M46 30 L56 24 M46 40 L58 40 M46 50 L56 56" fill="none"%s/>',
	&"g_mushroom": '<path d="M6 34 C6 14 58 14 58 34 Z" fill="#D9534F"%s/><circle cx="22" cy="26" r="4" fill="#FFF4E0"/><circle cx="40" cy="22" r="3.5" fill="#FFF4E0"/><path d="M24 34 H40 L42 58 H22 Z" fill="#FFF4E0"%s/>',
	&"g_paw": '<ellipse cx="32" cy="42" rx="14" ry="12" fill="#A0703F"%s/><circle cx="14" cy="26" r="6" fill="#A0703F"%s/><circle cx="25" cy="15" r="6" fill="#A0703F"%s/><circle cx="39" cy="15" r="6" fill="#A0703F"%s/><circle cx="50" cy="26" r="6" fill="#A0703F"%s/>',
	&"g_amphibian": '<path d="M8 44 C8 28 18 22 32 22 C46 22 56 28 56 44 C56 54 44 58 32 58 C20 58 8 54 8 44 Z" fill="#7DBE5A"%s/><circle cx="20" cy="22" r="8" fill="#7DBE5A"%s/><circle cx="44" cy="22" r="8" fill="#7DBE5A"%s/><circle cx="20" cy="22" r="3" fill="#2B3A2A"/><circle cx="44" cy="22" r="3" fill="#2B3A2A"/><path d="M22 44 C28 48 36 48 42 44" fill="none"%s/>',
	&"g_deer": '<path d="M22 30 C22 24 42 24 42 30 L40 48 C38 56 26 56 24 48 Z" fill="#C08552"%s/><path d="M24 26 L16 8 M18 14 L8 12 M20 18 L12 22 M40 26 L48 8 M46 14 L56 12 M44 18 L52 22" fill="none"%s/><circle cx="32" cy="50" r="3" fill="#2B3A2A"/>',
	&"g_hoof": '<path d="M30 8 C20 8 14 26 16 44 C17 54 30 56 30 46 Z" fill="#8A6A4A"%s/><path d="M34 8 C44 8 50 26 48 44 C47 54 34 56 34 46 Z" fill="#8A6A4A"%s/>',
	&"g_flower": '<circle cx="32" cy="16" r="10" fill="#F5C6E0"%s/><circle cx="48" cy="28" r="10" fill="#F5C6E0"%s/><circle cx="42" cy="46" r="10" fill="#F5C6E0"%s/><circle cx="22" cy="46" r="10" fill="#F5C6E0"%s/><circle cx="16" cy="28" r="10" fill="#F5C6E0"%s/><circle cx="32" cy="32" r="8" fill="#F2C14E"%s/>',
	&"deck": '<rect x="18" y="6" width="32" height="44" rx="5" fill="#3E5F3A"%s/><rect x="14" y="12" width="32" height="44" rx="5" fill="#4F7A47"%s/><rect x="20" y="18" width="20" height="32" rx="3" fill="none" stroke="#FFF4E0" stroke-width="2"/>',
	&"hand": '<rect x="6" y="14" width="24" height="36" rx="4" fill="#FFF4E0" transform="rotate(-18 18 50)"%s/><rect x="20" y="10" width="24" height="36" rx="4" fill="#FFF4E0"%s/><rect x="34" y="14" width="24" height="36" rx="4" fill="#FFF4E0" transform="rotate(18 46 50)"%s/>',
	&"clearing": '<ellipse cx="32" cy="48" rx="28" ry="10" fill="#8CC66A"%s/><rect x="20" y="8" width="24" height="34" rx="4" fill="#FFF4E0"%s/><path d="M14 46 L12 38 M20 50 L20 42 M46 50 L46 42 M52 46 L54 38" fill="none"%s/>',
	&"cave": '<path d="M4 58 C6 26 18 10 32 10 C46 10 58 26 60 58 Z" fill="#9C8B76"%s/><path d="M20 58 C20 40 26 32 32 32 C38 32 44 40 44 58 Z" fill="#2B2420"%s/>',
	&"again": '<path d="M48 22 A18 18 0 1 0 50 38" fill="none" stroke="#2B3A2A" stroke-width="9" stroke-linecap="round"/><path d="M48 22 A18 18 0 1 0 50 38" fill="none" stroke="#F2C14E" stroke-width="4" stroke-linecap="round"/><path d="M40 10 L54 20 L40 28 Z" fill="#F2C14E"%s/>',
	&"free": '<circle cx="32" cy="32" r="24" fill="#F2C14E"%s/><ellipse cx="32" cy="32" rx="9" ry="13" fill="none" stroke="#2B3A2A" stroke-width="5"/>',
	&"more": '<rect x="8" y="10" width="28" height="40" rx="5" fill="#FFF4E0"%s/><circle cx="44" cy="42" r="14" fill="#7FB04F"%s/><path d="M44 34 V50 M36 42 H52" fill="none" stroke="#FFF4E0" stroke-width="4" stroke-linecap="round"/>',
	&"side_top": '%TRUNK%<circle cx="32" cy="10" r="9" fill="#F28C38"%s/>',
	&"side_bottom": '%TRUNK%<circle cx="32" cy="54" r="9" fill="#F28C38"%s/>',
	&"side_left": '%TRUNK%<circle cx="10" cy="32" r="9" fill="#F28C38"%s/>',
	&"side_right": '%TRUNK%<circle cx="54" cy="32" r="9" fill="#F28C38"%s/>',
	&"side_side": '%TRUNK%<circle cx="10" cy="32" r="9" fill="#F28C38"%s/><circle cx="54" cy="32" r="9" fill="#F28C38"%s/>',
	&"t_linden": '<circle cx="32" cy="32" r="29" fill="#A8C84A" stroke="#FFF6E0" stroke-width="3"/><path d="M32 52 V58" stroke="#FFF6E0" stroke-width="4" stroke-linecap="round"/><path d="M32 50 C12 38 10 20 21 16 C28 14 32 20 32 25 C32 20 36 14 43 16 C54 20 52 38 32 50 Z" fill="#FFF6E0" stroke="#2B3A2A" stroke-width="2.5" stroke-linejoin="round"/><path d="M32 26 V48" stroke="#2B3A2A" stroke-width="2"/>',
	&"t_oak": '<circle cx="32" cy="32" r="29" fill="#8A6A2A" stroke="#FFF6E0" stroke-width="3"/><path d="M32 56 C29 51 22 51 23 46 C16 46 15 40 20 38 C13 36 14 29 20 28 C16 23 20 17 26 20 C25 13 30 8 32 8 C34 8 39 13 38 20 C44 17 48 23 44 28 C50 29 51 36 44 38 C49 40 48 46 41 46 C42 51 35 51 32 56 Z" fill="#FFF6E0" stroke="#2B3A2A" stroke-width="2.5" stroke-linejoin="round"/><path d="M32 16 V56" stroke="#2B3A2A" stroke-width="2"/>',
	&"t_fir": '<circle cx="32" cy="32" r="29" fill="#2F6A50" stroke="#FFF6E0" stroke-width="3"/><rect x="29" y="48" width="6" height="9" fill="#7A5132"/><path d="M32 7 L45 24 H39 L49 37 H42 L52 50 H12 L22 37 H15 L25 24 H19 Z" fill="#FFF6E0" stroke="#2B3A2A" stroke-width="2.5" stroke-linejoin="round"/>',
	&"t_birch": '<circle cx="32" cy="32" r="29" fill="#E8E2CC" stroke="#FFF6E0" stroke-width="3"/><rect x="24" y="7" width="16" height="50" rx="4" fill="#FFFFFF" stroke="#2B3A2A" stroke-width="2.5" stroke-linejoin="round"/><path d="M24 17 H31 M33 25 H40 M24 34 H30 M34 42 H40 M24 50 H32" stroke="#2B3A2A" stroke-width="3.5" stroke-linecap="round"/>',
	&"t_beech": '<circle cx="32" cy="32" r="29" fill="#C9853E" stroke="#FFF6E0" stroke-width="3"/><path d="M32 7 C47 18 49 40 32 55 C15 40 17 18 32 7 Z" fill="#FFF6E0" stroke="#2B3A2A" stroke-width="2.5" stroke-linejoin="round"/><path d="M32 12 V56 M32 22 L22 18 M32 22 L42 18 M32 32 L20 27 M32 32 L44 27 M32 42 L22 38 M32 42 L42 38" stroke="#2B3A2A" stroke-width="2" stroke-linecap="round"/>',
	&"t_maple": '<circle cx="32" cy="32" r="29" fill="#D85A3A" stroke="#FFF6E0" stroke-width="3"/><path d="M32 50 V58" stroke="#FFF6E0" stroke-width="4" stroke-linecap="round"/><path d="M32 6 L36 18 L46 12 L44 24 L56 24 L48 32 L54 40 L40 38 L36 50 H28 L24 38 L10 40 L16 32 L8 24 L20 24 L18 12 L28 18 Z" fill="#FFF6E0" stroke="#2B3A2A" stroke-width="2.5" stroke-linejoin="round"/>',
	&"t_pine": '<circle cx="32" cy="32" r="29" fill="#4F7FB0" stroke="#FFF6E0" stroke-width="3"/><path d="M32 6 V12" stroke="#FFF6E0" stroke-width="4" stroke-linecap="round"/><ellipse cx="32" cy="34" rx="14" ry="21" fill="#FFF6E0" stroke="#2B3A2A" stroke-width="2.5" stroke-linejoin="round"/><path d="M20 24 Q32 31 44 24 M18 33 Q32 41 46 33 M19 42 Q32 50 45 42 M32 14 V54" fill="none" stroke="#2B3A2A" stroke-width="2"/>',
	&"t_chestnut": '<circle cx="32" cy="32" r="29" fill="#7A3A2A" stroke="#FFF6E0" stroke-width="3"/><path d="M32 42 V58" stroke="#FFF6E0" stroke-width="4" stroke-linecap="round"/><ellipse cx="32" cy="25" rx="5.5" ry="12" transform="rotate(-80 32 42)" fill="#FFF6E0" stroke="#2B3A2A" stroke-width="2.5" stroke-linejoin="round"/><ellipse cx="32" cy="25" rx="5.5" ry="15" transform="rotate(-52 32 42)" fill="#FFF6E0" stroke="#2B3A2A" stroke-width="2.5" stroke-linejoin="round"/><ellipse cx="32" cy="25" rx="5.5" ry="15" transform="rotate(-26 32 42)" fill="#FFF6E0" stroke="#2B3A2A" stroke-width="2.5" stroke-linejoin="round"/><ellipse cx="32" cy="24" rx="5.5" ry="15" transform="rotate(0 32 42)" fill="#FFF6E0" stroke="#2B3A2A" stroke-width="2.5" stroke-linejoin="round"/><ellipse cx="32" cy="25" rx="5.5" ry="15" transform="rotate(26 32 42)" fill="#FFF6E0" stroke="#2B3A2A" stroke-width="2.5" stroke-linejoin="round"/><ellipse cx="32" cy="25" rx="5.5" ry="15" transform="rotate(52 32 42)" fill="#FFF6E0" stroke="#2B3A2A" stroke-width="2.5" stroke-linejoin="round"/><ellipse cx="32" cy="25" rx="5.5" ry="12" transform="rotate(80 32 42)" fill="#FFF6E0" stroke="#2B3A2A" stroke-width="2.5" stroke-linejoin="round"/>',
}
const _TRUNK := '<rect x="25" y="18" width="14" height="28" rx="4" fill="#7A5132"%s/><circle cx="32" cy="10" r="5" fill="#CFC4AE"/><circle cx="32" cy="54" r="5" fill="#CFC4AE"/><circle cx="10" cy="32" r="5" fill="#CFC4AE"/><circle cx="54" cy="32" r="5" fill="#CFC4AE"/>'


## 잠긴 것 표시(자물쇠). 아이콘 범례에는 넣지 않는다.
const LOCK := '<rect x="12" y="28" width="40" height="30" rx="6" fill="#CFC4AE"%s/><path d="M21 28 V20 A11 11 0 0 1 43 20 V28" fill="none" stroke="#CFC4AE" stroke-width="7"/><path d="M21 28 V20 A11 11 0 0 1 43 20 V28" fill="none" stroke="#2B3A2A" stroke-width="2"/><circle cx="32" cy="41" r="4" fill="#2B3A2A"/><rect x="30" y="42" width="4" height="9" fill="#2B3A2A"/>'


static func lock() -> Texture2D:
	return _svg(&"_lock", LOCK)


static func icon(name: StringName) -> Texture2D:
	if name == &"acorn":
		return acorn()
	if _icons.has(name):
		return _icons[name]
	return _svg(name, ICONS.get(name, ""))


static func _svg(name: StringName, body: String) -> Texture2D:
	if _icons.has(name):
		return _icons[name]
	if body == "":
		return null
	body = body.replace("%TRUNK%", _TRUNK).replace("%s", _O)
	var img := Image.new()
	img.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">%s</svg>' % body, 1.0)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_icons[name] = tex
	return tex
