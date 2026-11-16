extends Node
## 효과음(기획서 7장)을 코드로 만들어 튼다. 외부 소리 파일 없음.

const RATE := 22050
const VOICES := 6

var streams := {}
var _players: Array[AudioStreamPlayer] = []
var _noise := RandomNumberGenerator.new()


func _ready() -> void:
	_noise.seed = 7
	streams = {
		&"card": _wav(_click()),
		&"rustle": _wav(_rustle()),
		&"peel": _wav(_peel()),
		&"stamp": _wav(_stamp()),
		&"turn": _wav(_ding()),
		&"win": _wav(_tune([523.25, 659.25, 783.99, 1046.5], 0.12)),
		&"lose": _wav(_tune([392.0, 311.13], 0.24)),
	}
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


## 소리를 끄면(Game.sound) 아무것도 틀지 않는다. 틀었으면 true.
func play(id: StringName) -> bool:
	if not Game.sound or not streams.has(id):
		return false
	var p := _players[0]
	for q in _players:
		if not q.playing:
			p = q
			break
	p.stream = streams[id]
	p.play()
	return true


static func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w


func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(RATE * seconds))
	return b


## 카드 내려놓기: 짧은 딸깍.
func _click() -> PackedFloat32Array:
	var b := _buf(0.05)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (_noise.randf_range(-0.5, 0.5) + sin(TAU * 1800.0 * t)) * exp(-t * 110.0) * 0.45
	return b


## 봉투 바스락: 고역 잡음을 알갱이처럼 끊는다.
func _rustle() -> PackedFloat32Array:
	var b := _buf(0.34)
	var prev := 0.0
	var grain := 0.0
	for i in b.size():
		var t := float(i) / RATE
		if i % int(RATE * 0.012) == 0:
			grain = _noise.randf_range(0.2, 1.0)
		var n := _noise.randf_range(-1.0, 1.0)
		b[i] = (n - prev) * 0.5 * grain * sin(PI * t / 0.34) * 0.5
		prev = n
	return b


## 포스트잇 떼기: 점점 밝아지다 뚝 끊기는 잡음.
func _peel() -> PackedFloat32Array:
	var b := _buf(0.22)
	var y := 0.0
	for i in b.size():
		var k := float(i) / b.size()
		y += lerpf(0.04, 0.7, k) * (_noise.randf_range(-1.0, 1.0) - y)
		b[i] = y * pow(k, 1.2) * (1.0 if k < 0.94 else (1.0 - k) / 0.06) * 0.8
	return b


## 도장 쾅: 낮게 떨어지는 울림 + 처음 딱.
func _stamp() -> PackedFloat32Array:
	var b := _buf(0.32)
	var phase := 0.0
	for i in b.size():
		var t := float(i) / RATE
		phase += TAU * lerpf(150.0, 55.0, minf(1.0, t * 6.0)) / RATE
		b[i] = sin(phase) * exp(-t * 16.0) * 0.85 + _noise.randf_range(-1.0, 1.0) * exp(-t * 220.0) * 0.5
	return b


## 내 차례: 맑은 딩.
func _ding() -> PackedFloat32Array:
	var b := _buf(0.6)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (sin(TAU * 880.0 * t) + 0.3 * sin(TAU * 1320.0 * t)) * exp(-t * 7.0) * 0.3
	return b


func _tune(notes: Array, step: float) -> PackedFloat32Array:
	var b := _buf(step * notes.size() + 0.3)
	for n in notes.size():
		var start := int(n * step * RATE)
		for i in range(start, b.size()):
			var t := float(i - start) / RATE
			var f: float = notes[n]
			b[i] += (sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.0 * t)) * exp(-t * 6.0) * 0.22
	return b
