extends Node
## 화면 전환, 지금 런, 저장(밤 사이 이어 하기)과 해금 장부를 관리한다.
## 런은 seed와 행동 기록만 저장하고, 불러올 때 `Run.replay`로 다시 만든다.

signal screen_changed(scene: PackedScene)

const SCREENS := {
	&"title": preload("res://scenes/screens/title.tscn"),
	&"map": preload("res://scenes/screens/map.tscn"),
	&"counter": preload("res://scenes/screens/counter.tscn"),
	&"shop": preload("res://scenes/screens/shop.tscn"),
	&"run_end": preload("res://scenes/screens/run_end.tscn"),
	&"ledger": preload("res://scenes/screens/ledger.tscn"),
}
const SAVE_VERSION := 1

var run_seed := 0
var rng: RngStreams
var run: Run
var ledger := Ledger.new()
## 방금 끝난 런에서 풀린 꿀팁
var new_unlocks: Array[StringName] = []
var save_path := "user://nightmart_run.json"
var ledger_path := "user://nightmart_ledger.json"


func _ready() -> void:
	load_ledger()


func start_run(seed_value: int) -> void:
	run_seed = seed_value
	rng = RngStreams.new(run_seed)
	_watch(Run.new(run_seed, ledger.locked_tips()))
	new_unlocks = []
	save_run()
	goto(&"map")


func goto(screen: StringName) -> void:
	screen_changed.emit(SCREENS[screen])


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func save_run() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"version": SAVE_VERSION, "seed": str(run_seed), "locked": run.locked, "actions": run.actions}))


## 저장된 런을 다시 만든다. 기록이 맞지 않으면(버전이 바뀜) 저장을 지우고 false.
func continue_run() -> bool:
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path)) if has_save() else null
	var loaded: Run = null
	if data is Dictionary and int(data.get("version", 0)) == SAVE_VERSION:
		run_seed = int(data.seed)
		loaded = Run.replay(run_seed, data.locked, data.actions)
	if loaded == null or loaded.is_over():
		clear_save()
		return false
	_watch(loaded)
	rng = RngStreams.new(run_seed)
	new_unlocks = []
	goto(screen_for(run))
	return true


static func screen_for(r: Run) -> StringName:
	match r.phase:
		Run.Phase.SHOP, Run.Phase.PACK:
			return &"shop"
		Run.Phase.SHIFT:
			return &"map" if r.can_skip() or (r.shift.receipts.is_empty() and r.shift.discard_pile.is_empty()) else &"counter"
	return &"run_end"


func clear_save() -> void:
	if has_save():
		DirAccess.remove_absolute(save_path)


func load_ledger() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(ledger_path)) if FileAccess.file_exists(ledger_path) else null
	ledger = Ledger.from_dict(data) if data is Dictionary else Ledger.new()


func save_ledger() -> void:
	var f := FileAccess.open(ledger_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(ledger.to_dict()))


## 지난 런의 연결을 끊고 새 런을 지켜본다. 연결에 런을 묶지 않아야 지난 런이 풀린다.
func _watch(r: Run) -> void:
	if run and run.acted.is_connected(_on_acted):
		run.acted.disconnect(_on_acted)
	run = r
	run.acted.connect(_on_acted)


func _on_acted() -> void:
	var r := run
	if r.is_over():
		new_unlocks = ledger.record(r)
		save_ledger()
		clear_save()
	else:
		save_run()
