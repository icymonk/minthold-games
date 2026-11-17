class_name Art
extends RefCounted
## 그림 목록. 상품 그림은 tools/art_bake가 Kenney Food Kit(CC0)에서 굽는다.

const CORNERS: Array[StringName] = [&"meal", &"snack", &"drink", &"goods"]
## 코너별 상품 13개, 가격(1~13) 순서. tools/art_bake/bake.gd의 PRODUCTS와 같아야 한다.
const PRODUCTS := {
	&"meal": ["rice-ball", "sandwich", "sub", "hot-dog", "corn-dog", "burger", "burger-cheese", "dim-sum", "maki-salmon", "chinese", "bowl-broth", "styrofoam-dinner", "pizza"],
	&"snack": ["lollypop", "candy-bar", "chocolate", "cookie", "cookie-chocolate", "popsicle", "donut", "donut-sprinkles", "croissant", "muffin", "cupcake", "ice-cream-cup", "ice-cream"],
	&"drink": ["can", "soda-can", "carton-small", "carton", "soda-bottle", "soda", "cup-tea", "cup-coffee", "frappe", "glass", "cocktail", "wine-white", "wine-red"],
	&"goods": ["chopstick", "utensil-spoon", "bag-flat", "bag", "shaker-salt", "soy", "bottle-ketchup", "honey", "peanut-butter", "bottle-oil", "pepper-mill", "pot", "frying-pan"],
}

const HAND := preload("res://assets/art/kenney/hand.svg")
const ICON_HOME := preload("res://assets/art/kenney/icon_home.png")
const ICON_NEXT := preload("res://assets/art/kenney/icon_next.png")
const ICON_RETRY := preload("res://assets/art/kenney/icon_retry.png")
const ICON_CHECKOUT := preload("res://assets/art/kenney/icon_checkout.png")
const ICON_DISCARD := preload("res://assets/art/kenney/icon_discard.png")
const ICON_SETTINGS := preload("res://assets/art/kenney/icon_settings.png")
const ICON_HELP := preload("res://assets/art/kenney/icon_help.png")
const ICON_SOUND_ON := preload("res://assets/art/kenney/icon_sound_on.png")
const ICON_FLYER := preload("res://assets/art/kenney/icon_flyer.png")
const ICON_SOUND_OFF := preload("res://assets/art/kenney/icon_sound_off.png")


static func product(corner: StringName, rank: int) -> Texture2D:
	return load("res://assets/art/products/%s/%s.png" % [corner, PRODUCTS[corner][rank - 1]])
