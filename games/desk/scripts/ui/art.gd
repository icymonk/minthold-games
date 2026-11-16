class_name Art
extends RefCounted
## 구운 그림(Kenney CC0)과 인물 자세. 다시 구우려면 tools/art_bake/bake.sh.

const ZONES: Array[Texture2D] = [
	preload("res://assets/art/zone_floor.png"),
	preload("res://assets/art/zone_building.png"),
	preload("res://assets/art/zone_outside.png"),
]
const EMPTY_CHAIR := preload("res://assets/art/empty_chair.png")
const PEOPLE := {
	&"staff_idle": preload("res://assets/art/people/staff_idle.png"),
	&"staff_run0": preload("res://assets/art/people/staff_run0.png"),
	&"staff_run1": preload("res://assets/art/people/staff_run1.png"),
	&"staff_cheer0": preload("res://assets/art/people/staff_cheer0.png"),
	&"staff_hurt": preload("res://assets/art/people/staff_hurt.png"),
	&"staff_interact": preload("res://assets/art/people/staff_interact.png"),
	&"chief_idle": preload("res://assets/art/people/chief_idle.png"),
	&"chief_think": preload("res://assets/art/people/chief_think.png"),
	&"chief_talk": preload("res://assets/art/people/chief_talk.png"),
	&"chief_cheer0": preload("res://assets/art/people/chief_cheer0.png"),
	&"chief_hurt": preload("res://assets/art/people/chief_hurt.png"),
}


## 처음 손패(0~3)는 자리, 18:00은 건물 밖으로 그린다.
static func zone(card: int) -> Texture2D:
	if card == Cards.LAST:
		return ZONES[Cards.Zone.OUTSIDE]
	return ZONES[maxi(Cards.zone_of(card), Cards.Zone.FLOOR)]


static func person(key: StringName) -> Texture2D:
	return PEOPLE[key]


static func picture(tex: Texture2D, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.custom_minimum_size = size
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
