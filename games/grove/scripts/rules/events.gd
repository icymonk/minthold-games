class_name Events
extends RefCounted
## 계절 사건(규칙 1-3): 계절마다 8종 중 1개가 런 시작 때 정해져 미리 보인다.
## 말: score = [{side?, kind?, x}](이웃 점수 배수), clearing(빈터 쓸림 장수), hand(손패 한도),
##     winds(계절 바람 장수), cut_bare(계절 끝에 이웃 없는 나무를 벤다), acorns(도토리 배수)

const BY_SEASON := [
	{
		&"late_frost": {score = [{side = &"Bottom", x = 0.5}]},
		&"yellow_dust": {score = [{kind = &"bird", x = 0.5}]},
		&"cold_snap": {score = [{kind = &"butterfly", x = 0.0}]},
		&"doves": {clearing = 8},
		&"spring_rain": {score = [{kind = &"amphibian", x = 1.5}]},
		&"cherry_blossom": {score = [{kind = &"flower", x = 2.0}]},
		&"spring_gale": {winds = 4},
		&"sprout_feast": {acorns = 1.5},
	},
	{
		&"drought": {clearing = 7},
		&"monsoon": {score = [{kind = &"amphibian", x = 2.0}, {kind = &"butterfly", x = 0.0}, {kind = &"bat", x = 0.0}]},
		&"cicadas": {score = [{kind = &"insect", x = 2.0}], hand = 8},
		&"hikers": {score = [{kind = &"hoof", x = 0.5}]},
		&"heat_wave": {score = [{side = &"Top", x = 0.5}]},
		&"thunderstorm": {winds = 4},
		&"mosquitoes": {score = [{kind = &"bat", x = 2.0}]},
		&"berry_season": {acorns = 1.5},
	},
	{
		&"fire_watch": {hand = 8},
		&"acorn_famine": {acorns = 0.0},
		&"survey": {cut_bare = true},
		&"typhoon": {winds = 4},
		&"harvest_moon": {score = [{kind = &"paw", x = 1.5}]},
		&"mushroom_rain": {score = [{kind = &"mushroom", x = 2.0}]},
		&"rutting": {score = [{kind = &"deer", x = 2.0}, {kind = &"hoof", x = 2.0}]},
		&"leaf_storm": {clearing = 7},
	},
	{
		&"deep_cold": {score = [{side = &"Top", x = 0.5}]},
		&"blizzard": {hand = 7},
		&"long_night": {score = [{kind = &"bat", x = 2.0}, {kind = &"butterfly", x = 0.0}]},
		&"food_shortage": {score = [{kind = &"paw", x = 0.5}]},
		&"thaw": {score = [{side = &"Bottom", x = 1.5}]},
		&"ice_storm": {winds = 2},
		&"hungry_wolves": {score = [{kind = &"deer", x = 0.5}, {kind = &"hoof", x = 0.5}]},
		&"aurora": {acorns = 2.0},
	},
]


static func def_of(season: int, id: StringName) -> Dictionary:
	return BY_SEASON[season].get(id, {})
