class_name Deduce
extends RefCounted
## Knowledge → 가운데 줄 기록마다 번호별 확률(아키텍처 2장).
## 오름차순·거리·제외·틀린 단일 짚기·구역 장수(아는 카드 기준)는 DP로 정확히 센다.
## 틀린 묶음 짚기와 뒷면끼리 같은 구역 카드를 나눠 쓰는 조건은 DP 표본을 걸러 `probs`에만 반영한다.
## 표본은 드문 경우를 놓칠 수 있으므로 `range_of`·`sure`·`possible`은 걸러지기 전 DP로 판단한다
## (정답 번호를 지우거나 틀린 번호를 확실하다고 하지 않는다).

const SAMPLES := 1000
## 받아들인 표본이 samples개가 될 때까지 뽑되, samples × 이 값번 넘게는 뽑지 않는다.
const MAX_TRIES_PER_SAMPLE := 20
const SIZE := Cards.LAST + 1

var know: Knowledge
var steps: Array[int] = []    # i → 앞 기록에서 갈 수 있는 최대 거리
var allowed: Array = []       # i → PackedByteArray(SIZE)
var fwd: Array = []           # i → PackedFloat64Array(SIZE)
var bwd: Array = []
var total := 0.0
var sampled := false
var probs: Array = []         # i → PackedFloat64Array(SIZE). 불가능한 판이면 모두 0
var dp_probs: Array = []      # 표본 거르기 전 확률
var _avail: Array = []        # zone → Array[int]: j번 기록을 낼 때까지 사원이 받은 그 구역 장수
var _known_sprints: Array = []  # zone → Array[int]: j번까지 아는 뛰기 카드 중 그 구역 장수(누적)
var _known_cards: Array = []    # zone → Array[int]: 위 + 아는 기록 카드(누적)


static func run(k: Knowledge, rng: RandomNumberGenerator = null, samples := SAMPLES) -> Deduce:
	var d := Deduce.new()
	d.know = k
	d._tables()
	d._build()
	d._dp()
	if d.total > 0.0 and d._needs_sampling():
		if rng == null:
			rng = RandomNumberGenerator.new()
			rng.seed = 0
		d._sample(rng, samples)
	return d


## DP 기준으로 i번 기록이 c일 수 있는가(표본 거르기 전).
func possible(i: int, c: int) -> bool:
	return fwd[i][c] * bwd[i][c] > 0.0


## 될 수 있는 가장 작은·큰 번호. 없으면 (-1, -1).
func range_of(i: int) -> Vector2i:
	var r := Vector2i(-1, -1)
	for c in SIZE:
		if possible(i, c):
			if r.x < 0:
				r.x = c
			r.y = c
	return r


## 번호마다 어느 뒷면 기록이든 그 번호일 확률.
func odds() -> PackedFloat64Array:
	return _odds(probs)


## 뒷면 기록 중 확실히 있는 번호.
func sure() -> Array[int]:
	var out: Array[int] = []
	var o := _odds(dp_probs)
	for c in SIZE:
		if o[c] > 1.0 - 1e-9:
			out.append(c)
	return out


func _odds(table: Array) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	out.resize(SIZE)
	for i in know.hideouts.size():
		if not know.is_known(i):
			for c in SIZE:
				out[c] += table[i][c]
	return out


func _tables() -> void:
	var n := know.hideouts.size()
	for z in Cards.ZONE_RANGES.size():
		var avail: Array[int] = []
		var spr: Array[int] = []
		var cards: Array[int] = []
		var s := 0
		var c := 0
		for j in n:
			var a: int = know.start_counts[z] if z < know.start_counts.size() else 0
			for dr in know.staff_draws:
				if dr.zone == z and dr.before <= j:
					a += 1
			avail.append(a)
			var h: Dictionary = know.hideouts[j]
			for x in h.sprints:
				if Cards.zone_of(x) == z:
					s += 1
			if h.card != Knowledge.HIDDEN and Cards.zone_of(h.card) == z:
				c += 1
			spr.append(s)
			cards.append(s + c)
		_avail.append(avail)
		_known_sprints.append(spr)
		_known_cards.append(cards)


func _build() -> void:
	var excl := know.excluded()
	for i in know.hideouts.size():
		var h: Dictionary = know.hideouts[i]
		var a := PackedByteArray()
		a.resize(SIZE)
		if know.is_known(i):
			a[h.card] = 1
		else:
			for c in range(1, Cards.LAST):
				if not excl.has(c) and not _missed_single(c, i) and _zone_room(Cards.zone_of(c), i):
					a[c] = 1
		allowed.append(a)
		var bonus: int = 2 * h.sprint_count
		if h.sprints.size() == h.sprint_count:
			bonus = 0
			for x in h.sprints:
				bonus += Cards.sprint_of(x)
		steps.append(Cards.BASE_STEP + bonus)


func _missed_single(c: int, i: int) -> bool:
	for ms in know.misses:
		if ms.numbers.size() == 1 and ms.numbers[0] == c and i < ms.before:
			return true
	return false


## 뒷면 i번이 구역 z 카드여도 그 뒤 어느 시점에서든 받은 장수를 넘지 않는가.
func _zone_room(z: int, i: int) -> bool:
	if z < 0:
		return true
	for j in range(i, know.hideouts.size()):
		if _known_cards[z][j] + 1 > _avail[z][j]:
			return false
	return true


func _dp() -> void:
	var n := know.hideouts.size()
	for i in n:
		var f := PackedFloat64Array()
		f.resize(SIZE)
		for c in SIZE:
			if not allowed[i][c]:
				continue
			if i == 0:
				f[c] = 1.0
			else:
				for p in range(maxi(0, c - steps[i]), c):
					f[c] += fwd[i - 1][p]
		fwd.append(f)
	bwd.resize(n)
	for i in range(n - 1, -1, -1):
		var b := PackedFloat64Array()
		b.resize(SIZE)
		for c in SIZE:
			if not allowed[i][c]:
				continue
			if i == n - 1:
				b[c] = 1.0
			else:
				for x in range(c + 1, mini(SIZE, c + steps[i + 1] + 1)):
					b[c] += bwd[i + 1][x]
		bwd[i] = b
	for c in SIZE:
		total += fwd[n - 1][c]
	for i in n:
		var pr := PackedFloat64Array()
		pr.resize(SIZE)
		if total > 0.0:
			for c in SIZE:
				pr[c] = fwd[i][c] * bwd[i][c] / total
		probs.append(pr)
	dp_probs = probs.duplicate()


func _needs_sampling() -> bool:
	for ms in know.misses:
		if ms.numbers.size() > 1:
			return true
	for z in _avail.size():
		var r: Vector2i = Cards.ZONE_RANGES[z]
		var hidden_in_zone := 0
		for j in know.hideouts.size():
			if not know.is_known(j):
				for c in range(r.x, r.y + 1):
					if possible(j, c):
						hidden_in_zone += 1
						break
			if _known_cards[z][j] + hidden_in_zone > _avail[z][j]:
				return true
	return false


func _sample(rng: RandomNumberGenerator, samples: int) -> void:
	var n := know.hideouts.size()
	var counts: Array = []
	for i in n:
		var row := PackedFloat64Array()
		row.resize(SIZE)
		counts.append(row)
	var path := PackedInt32Array()
	path.resize(n)
	var accepted := 0
	var tries := 0
	while accepted < samples and tries < samples * MAX_TRIES_PER_SAMPLE:
		tries += 1
		path[n - 1] = _pick(fwd[n - 1], 0, SIZE - 1, rng)
		for i in range(n - 1, 0, -1):
			path[i - 1] = _pick(fwd[i - 1], maxi(0, path[i] - steps[i]), path[i] - 1, rng)
		if _path_ok(path):
			accepted += 1
			for i in n:
				counts[i][path[i]] += 1.0
	if accepted == 0:
		return # 받아들인 표본이 없으면 DP 확률(조건을 덜 건 쪽)을 그대로 둔다.
	sampled = true
	for i in n:
		for c in SIZE:
			counts[i][c] /= accepted
	probs = counts


func _pick(w: PackedFloat64Array, lo: int, hi: int, rng: RandomNumberGenerator) -> int:
	var sum := 0.0
	for c in range(lo, hi + 1):
		sum += w[c]
	var r := rng.randf() * sum
	for c in range(lo, hi + 1):
		r -= w[c]
		if r < 0.0 and w[c] > 0.0:
			return c
	for c in range(hi, lo - 1, -1):
		if w[c] > 0.0:
			return c
	return lo


func _path_ok(path: PackedInt32Array) -> bool:
	for ms in know.misses:
		if ms.numbers.size() < 2:
			continue
		var all_in := true
		for x in ms.numbers:
			var found := false
			for i in mini(ms.before, path.size()):
				if path[i] == x:
					found = true
					break
			if not found:
				all_in = false
				break
		if all_in:
			return false
	for z in _avail.size():
		var used := 0
		for j in path.size():
			if Cards.zone_of(path[j]) == z:
				used += 1
			if used + _known_sprints[z][j] > _avail[z][j]:
				return false
	return true
