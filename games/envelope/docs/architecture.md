# 개발 환경과 아키텍처

모노레포 규칙과 `games/rooster/docs/architecture.md`를 그대로 따른다(Godot 4.7.x 고정, GDScript, gdUnit4, 웹 미리보기). 이 문서는 이 게임에서 달라지는 점만 적는다.

## 1. 핵심 원칙: 규칙·AI·화면 분리

```
 Match (순수 로직, RefCounted)
   │  legal_moves(seat) / apply(move) / resolve() → Result
   │  모든 행동은 Move로 기록 → 기록 줄, AI 추리, 시뮬레이터가 같은 코드를 씀
   ├─ Knowledge (자리별로 아는 것: 손패, 공개 카드, 엿본 카드)
   ├─ Bot (Knowledge만 읽고 Move를 고른다)
   ▼
 TableView (Control 씬) — 사람 자리의 Knowledge만 그린다
```

- `Match`는 씬 트리에 의존하지 않는다. 덱 구성, 분배, 세 가지 행동, 능력 13종, 손 떼기, 결산을 계산한다.
- 능력 중 고르기가 필요한 것(대상, 줄 카드)은 `Match`가 "결정 요청"을 내고, 사람은 화면에서, AI는 `Bot`이 답한다. 여러 사람이 동시에 고르는 사내 방송도 같은 방식.
  - `Match.pending`: `{ seat, ask, options, by, kind }` 목록. 비어 있지 않으면 `legal_moves()`는 비고, `answer(seat, choice)`로 하나씩 답한다. 모두 답하면 효과를 적용하고 다음 요청을 내거나 차례를 넘긴다.
  - `ask` 종류: `NOTE_MOVE`(단짝 동기) · `MISER_TAKE`(구두쇠, 다음 차례 시작) · `PEEK_HAND`(인사팀) · `CLAIM`(눈치왕에 끼어드는 관종 신입) · `SWAP_TARGET`→`SWAP_GIVE`(오지랖) · `PASS`(사내 방송) · `TAKE_FACE_UP`(비품 담당) · `DRAW_FROM`→`GIVE_BACK`(부장님) · `ENVELOPE_SWAP`(퇴사 예정자)
- `Knowledge.of(match, seat)`: 그 자리가 아는 것만 복사한다. 뒷면 카드는 위치(uid)만, 종류는 본 적 있는 카드(`Match.seen`)와 앞면 카드만 `known`에 들어간다.
- 같은 시드 + 같은 Move 목록이면 같은 결과(결정론). 무작위(부장님 뽑기 등)는 `RngStreams.play`에서만 뽑는다.

## 2. 데이터

| 종류 | 주요 필드 |
|---|---|
| `CardDef` | id, 이름 키, 금액, 능력 종류, 승리 조건, 우선순위, 낼 수 있는지 |
| `DeckDef` | 인원수 → 장수별 카드 목록, 목표액 |
| `BotPersona` | 이름 키, 얼굴, 성격 가중치 |

카드 데이터는 처음에는 `scripts/core/cards.gd` 상수 표로 두고, 밸런스 조정이 잦아지면 `.tres`로 옮긴다.

## 3. 디렉터리 구조

```text
project.godot
assets/     fonts/  cards/  sfx/
i18n/
scenes/     main.tscn  screens/(title, table, result)  ui/
scripts/
  autoload/ Game
  core/     cards, match, move, knowledge, resolve, rng_streams
  ai/       bot, persona
  screens/  ui/
tests/
tools/
  sim.gd    # 헤드리스 시뮬레이터
docs/
```

## 4. 시뮬레이터

- `godot --headless -s tools/sim.gd -- --games 2000 --players 5`: AI끼리 돌려 정체별 승률, 모금 성공률, 범인 검거율, 평균 봉투 금액을 출력한다.
- 목표: 직원 진영이 이기는 판 40~55%, 범인 진영 20~35%, 나머지(구두쇠·관종·퇴사 예정자·전원 패배) 15~25%.
- 카드 금액·장수를 바꾸면 다시 돌린다.

## 5. 빌드와 미리보기

- CI: `.github/workflows/envelope.yml`이 공용 `godot.yml`을 부른다(`game: envelope`).
- 웹 미리보기: Firebase `minthold-preview`의 사이트 `minthold-envelope` → https://minthold-envelope.web.app
- 기준 해상도 1920×1080, `canvas_items` + `expand`.

### 4.1 1-3 Bot 1차 기준선 (400판, 시드 1)

| 인원 | 직원 | 범인 진영 | 그 외 | 전원 패배 | 모금 성공 | 범인 검거 |
|---|---|---|---|---|---|---|
| 3 | 10.5% | 45.0% | 37.8% | 6.8% | 31.3% | 43.5% |
| 4 | 37.5% | 34.8% | 22.8% | 5.0% | 60.0% | 62.4% |
| 5 | 30.8% | 40.8% | 24.6% | 4.0% | 55.8% | 52.2% |
| 6 | 14.8% | 61.5% | 19.6% | 4.3% | 49.5% | 31.8% |

3인·6인은 범인 진영이 너무 세다. 3-2에서 금액·장수와 Bot 성격을 함께 조정한다.
