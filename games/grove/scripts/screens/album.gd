extends ScreenBase
## 내 숲 앨범(4-1): 런이 끝날 때 찍어 둔 숲 사진들. 최근 것이 먼저.

const COLUMNS := 4
const THUMB := Vector2(400, 225)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := _frame()
	_label(col, tr("ALBUM_TITLE"), Style.HEADLINE)
	var album := Game.records.album
	if album.is_empty():
		_label(col, tr("ALBUM_EMPTY"), Style.BODY, Color(Style.CREAM, 0.8))
	else:
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(THUMB.x * COLUMNS + 80, 640)
		scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		col.add_child(scroll)
		var center := CenterContainer.new()
		center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(center)
		var grid := GridContainer.new()
		grid.columns = COLUMNS
		grid.add_theme_constant_override(&"h_separation", 16)
		grid.add_theme_constant_override(&"v_separation", 10)
		center.add_child(grid)
		for i in range(album.size() - 1, -1, -1):
			grid.add_child(_photo(album[i]))
	_spacer(col)
	var back := _button(col, Art.ICON_HOME, tr("BACK_TO_TITLE"), Game.goto.bind(&"title"), 360)
	back.grab_focus()


func _photo(e: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 2)
	var pic := TextureRect.new()
	pic.custom_minimum_size = THUMB
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var img := Image.load_from_file(e.file) if FileAccess.file_exists(e.file) else null
	if img:
		pic.texture = ImageTexture.create_from_image(img)
	box.add_child(pic)
	var mark := "★ " if e.get("finished", false) else ""
	_label(box, "%s%s" % [mark, tr("ALBUM_ENTRY") % [e.year, tr("KEEPER_%s" % String(e.keeper).to_upper()), e.grade]], 24)
	_label(box, e.get("date", ""), 20, Color(Style.CREAM, 0.6))
	return box
