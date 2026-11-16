# 개발 환경과 아키텍처

모노레포 규칙과 `games/rooster/docs/architecture.md`를 그대로 따른다(Godot 4.7.x 고정, GDScript, gdUnit4, 웹 미리보기). 이 문서는 이 게임에서 달라지는 점만 적는다.

## 1. 핵심 원칙: 규칙과 화면 분리

```
 ShiftState ──▶ Bay (순수 로직, RefCounted)
                  │  place(box, cell) / can_unload(box) / unload(box) / settle()
                  │  모든 행동은 Action으로 기록 → 되돌리기, 시간 계산, 풀이기가 같은 코드를 씀
                  ▼
            BayView (Node2D 씬) — Bay 상태를 그리기만 함
```

- `Bay`는 씬 트리에 의존하지 않는다. 격자, 상자 배치, 중력, 꺼내기 규칙을 계산한다.
- 화면은 `Bay`에 행동을 요청하고 결과(움직인 상자, 파손, 걸린 시간)를 받아 연출한다.
- 같은 시드면 같은 경로·상자가 나온다(결정론).

## 2. 데이터 (Resource)

| Resource | 주요 필드 |
|---|---|
| `BoxShapeDef` | id, 칸 목록(Vector2i), 회전 가능 여부 |
| `BoxTraitDef` | id, 아이콘, 규칙 종류(깨짐·무거움·냉동·이쪽이 위로) |
| `UpgradeDef` | id, 이름 키, 가격, 효과 |
| `ContractDef` | id, 이득, 대가 |
| `EventDef` | id, 선택지, 결과 |

## 3. 디렉터리 구조

```text
project.godot
assets/
data/       shapes/  traits/  upgrades/  contracts/  events/
i18n/
scenes/     main.tscn  loading/  delivery/  payday/  result/  ui/
scripts/
  autoload/ Game, Save, Settings
  core/     bay, box, route_gen, shift_state, rng_streams
tests/
tools/
  solver.gd # 헤드리스 풀이기
docs/
```

## 4. 풀이기

- `godot --headless -s tools/solver.gd -- --days 200`: 생성된 날마다 탐색으로 "최선이면 몇 시에 끝나는지"를 구한다.
- 생성기는 여유 시간이 기준(예: 30분)보다 적은 날을 버리고 다시 만든다.
- CI에서 짧게(20일) 돌려 생성기가 풀 수 없는 날을 만들지 않는지 확인한다.

## 5. 빌드와 미리보기

- CI: `.github/workflows/haul.yml`이 공용 `godot.yml`을 부른다(`game: haul`).
- 웹 미리보기: Firebase `minthold-preview`의 사이트 `minthold-haul` → https://minthold-haul.web.app
- 기준 해상도 1920×1080, `canvas_items` + `expand`.
