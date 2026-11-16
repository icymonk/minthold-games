class_name Dish
extends RefCounted
## 식탁 위 그릇 하나. 길이 단위는 cm, x는 식탁 왼쪽 끝에서 그릇 가운데까지.

const CATALOG := {
	&"plate": {"chips": 10, "width": 24.0, "height": 3.0, "grip": 0.35},
	&"soup_bowl": {"chips": 15, "width": 16.0, "height": 7.0, "grip": 0.35},
	&"mug": {"chips": 15, "width": 9.0, "height": 10.0, "grip": 0.4},
	&"wine_glass": {"chips": 40, "width": 7.0, "height": 20.0, "grip": 0.3},
	&"wine_bottle": {"chips": 30, "width": 8.0, "height": 30.0, "grip": 0.35},
	&"vase": {"chips": 35, "width": 12.0, "height": 28.0, "grip": 0.4},
	&"cake": {"chips": 50, "width": 26.0, "height": 14.0, "grip": 0.25},
	&"jelly": {"chips": 25, "width": 12.0, "height": 9.0, "grip": 0.5},
}

var kind: StringName
var x: float
var chips: int
var width: float
var height: float
## 천과 그릇 사이 마찰 계수.
var grip: float


func _init(kind_: StringName, x_: float) -> void:
	var spec: Dictionary = CATALOG[kind_]
	kind = kind_
	x = x_
	chips = spec.chips
	width = spec.width
	height = spec.height
	grip = spec.grip


func left() -> float:
	return x - width / 2.0


func right() -> float:
	return x + width / 2.0
