extends ScreenBase
## 테이블 화면 자리. 1-1 규칙 엔진, 2-1 화면에서 채운다.


func _ready() -> void:
	_make_list()
	var role_name := tr("ROLE_CHIEF" if Game.role == Game.Role.CHIEF else "ROLE_STAFF")
	_label(tr("TABLE_PLACEHOLDER") % [role_name, Game.run_seed], 32)
	_button(tr("BACK_TO_TITLE"), func() -> void: Game.goto(&"title"))
