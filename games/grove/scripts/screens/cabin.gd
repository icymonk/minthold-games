extends ScreenBase
## 숲지기 오두막 뼈대(보상·상점은 2-2에서).


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(Style.FOREST, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", Style.glass(32))
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", Style.GAP)
	panel.add_child(col)
	_label(col, tr("CABIN_TITLE"), Style.HEADLINE, Style.SUNSET)
	var go := _button(col, Art.ICON_NEXT, tr("CABIN_NEXT") % Game.season_name(Game.season + 1), Game.next_season, 640)
	go.theme_type_variation = &"AccentButton"
	go.grab_focus()
