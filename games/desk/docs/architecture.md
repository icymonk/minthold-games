# 개발 환경과 아키텍처

모노레포 규칙과 `games/rooster/docs/architecture.md`를 그대로 따른다(Godot 4.7.x 고정, GDScript, gdUnit4, 웹 미리보기). 이 문서는 이 게임에서 달라지는 점만 적는다.

## 1. 핵심 원칙: 규칙·AI·화면 분리

```
 Match (순수 로직, RefCounted)
   │  legal_moves(side) / apply(move) / winner()
   │  모든 행동은 Move로 기록 → 기록 줄, AI 추리, 시뮬레이터가 같은 코드를 씀
   ├─ Knowledge (쪽마다 아는 것: 손패, 앞면 카드, 뽑은 더미, 뛰기 장수, 짚기 결과)
   ├─ Deduce (Knowledge → 뒷면 기록별 가능한 번호 분포)  ← AI 팀장, 쉬움 범위 표시가 같이 씀
   ├─ Bot (Knowledge만 읽고 Move를 고른다)
   ▼
 TableView (Control 씬) — 사람 쪽 Knowledge만 그린다
```

- `Match`는 씬 트리에 의존하지 않는다. 준비, 뽑기, 기록 내기(뛰기 포함), 쉬기, 하나·여러 개 짚기, 마지막 추궁, 사건 카드를 계산한다.
- 같은 시드 + 같은 Move 목록이면 같은 결과(결정론). 섞기는 `RngStreams.deal`, AI 고민은 `RngStreams.bots`에서만 뽑는다.

## 2. Deduce (추리기)

- 입력: 뒷면 기록 수와 각 기록의 뛰기 장수, 앞면 기록 위치, 후보에서 뺄 번호(팀장 손패·앞면·틀린 단일 짚기), 뽑은 더미 기록, 틀린 묶음 짚기.
- 방법: 가운데 줄 왼쪽부터 DP. 상태 = (기록 순서, 번호). 다음 기록은 `이전 < 다음 ≤ 이전 + 3 + 최대 뛰기(2k)`. 앞면 기록은 고정점. 경우의 수를 세어 기록별·번호별 확률을 낸다.
- 뛰기 카드 번호와 "틀린 묶음" 같은 전역 조건은 DP 뒤에 표본 뽑기(수천 개)로 거른다.
- 성능 목표: 웹에서 한 번 계산 50ms 이하.

## 3. 데이터

| 종류 | 주요 필드 |
|---|---|
| `CardDef` | 번호, 시각 문자열, 구역, 장소 키, 뛰기 값 |
| `EventDef` | id, 이름 키, 돕는 쪽, 효과 종류 |
| `BotPersona` | 이름 키, 얼굴, 역할, 성격 가중치 |

카드 데이터는 `scripts/core/cards.gd` 상수 표로 둔다. 뛰기 값은 한곳(`sprint_of(n)`)에서만 정한다.

## 4. 디렉터리 구조

```text
project.godot
assets/     fonts/  cards/  sfx/
i18n/
scenes/     main.tscn  screens/(title, table, result)  ui/
scripts/
  autoload/ Game
  core/     cards, match, move, knowledge, deduce, events, rng_streams
  ai/       chief_bot, staff_bot, persona
  screens/  ui/
tests/
tools/
  sim.gd    # 헤드리스 시뮬레이터
docs/
```

## 5. 시뮬레이터

- `godot --headless -s tools/sim.gd -- --games 2000 --chief careful --staff careful`: AI끼리 돌려 역할별 승률, 평균 차례 수, 마지막 추궁 발생·성공률, 뛰기 카드 사용량을 출력한다.
- 목표(꼼꼼 vs 꼼꼼): 사원 승률 45~55%, 평균 12~18차례.
- 뛰기 값·처음 손패를 바꾸면 다시 돌린다.

## 6. 빌드와 미리보기

- CI: `.github/workflows/desk.yml`이 공용 `godot.yml`을 부른다(`game: desk`).
- 웹 미리보기: Firebase `minthold-preview`의 사이트 `minthold-desk` → https://minthold-desk.web.app
- 기준 해상도 1920×1080, `canvas_items` + `expand`.
