extends SceneTree
## 실제 Firebase에 두 기기를 붙여 방 만들기 → 들어가기 → 시작 → 행동 2번이 서로 보이는지 본다.
## godot --headless -s tools/online_smoke.gd

func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var a := Online.new(Fire.new())
	var b := Online.new(Fire.new())
	root.add_child(a)
	root.add_child(b)
	a.set_process(false)
	b.set_process(false)
	# 같은 기기라 저장된 익명 계정이 겹치지 않게 b는 새로 받는다
	print("signin a ", await a.sign_in())
	DirAccess.remove_absolute(Fire.SAVE)
	(b.db as Fire)._refresh = ""
	print("signin b ", await b.sign_in(), " ", a.me != b.me)
	print("create ", await a.create("A"), " ", a.code)
	print("join ", await b.join(a.code, "B"))
	await a.poll()
	print("members ", a.members().size())
	print("start ", await a.start())
	await b.poll()
	print("seats ", a.seat, b.seat)
	print("act a ", a.act({k = "draw"}), a.act({k = "draw"}))
	await create_timer(2.0).timeout
	await b.poll()
	print("b sees turn ", b.game.turn, " a hand ", b.game.hand_of(0).size())
	print("act b ", b.act({k = "draw"}), b.act({k = "draw"}))
	await create_timer(2.0).timeout
	await a.poll()
	print("a sees turn ", a.game.turn, " same deck ", a.game.season.deck.size() == b.game.season.deck.size())
	print("done")
	quit()
