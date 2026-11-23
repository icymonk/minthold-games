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
