# 개발 환경과 아키텍처

툴체인은 `docs/reference/2d_steam_game_toolchain_and_architecture.md`를 그대로 따른다(Godot 4 + GDScript + Krita + Audacity + Git + Steamworks). 그 문서의 디렉터리 구조와 시스템 구성(서랍·시계 같은 상호작용 오브젝트, 인벤토리, 대화, 스테이지 Scene)은 방탈출·포인트앤클릭용이다. 그래서 이 문서에서 오토배틀러 로그라이크에 맞게 다시 정한다.

## 1. 원본 문서와 달라진 점

| 원본 | 이 프로젝트 | 이유 |
|---|---|---|
| Godot 4.x | **Godot 4.7.x** 고정 (`project.godot`, CI 동일 버전) | 에디터·CI 버전 불일치로 씬 파일이 깨지는 것 방지 |
| 스테이지 Scene + Area2D 상호작용 | 화면 Scene(장터·진영·전투·결과) + **순수 GDScript 전투 엔진** | 전투가 자동이라 클릭 오브젝트가 필요 없음. 대신 규칙 계산과 연출을 분리해야 함 |
| Inventory / Dialogue System | 제외 | 장르에 필요 없음 |
| 스테이지 Resource | 요괴·특성·부적·행렬 Resource | 콘텐츠 단위가 다름 |
| (없음) | 시드 RNG, 헤드리스 시뮬레이터, 자동 테스트, 웹 빌드 | 밸런스·재현·확인용 |
| (없음) | 번역 테이블, 컨트롤러 입력, 16:10 대응 | 영어 출시, Steam Deck |

## 2. 핵심 원칙: 규칙과 연출 분리

```
 RunState ──▶ BattleSim (순수 로직, Node 아님)
                 │  입력: 아군 진영, 적 진영, 부적, 시드
                 │  출력: BattleLog (이벤트 목록) + 결과
                 ▼
            BattleView (Node2D 씬)
                 └─ BattleLog를 순서대로 재생 (트윈, 말풍선, 숫자 팝업)
```

- `BattleSim`은 `RefCounted` 기반 GDScript 클래스다. 씬 트리, 시간, 애니메이션에 의존하지 않는다. 전투 한 판을 즉시 끝까지 계산한다.
- 화면은 계산 결과로 나온 `BattleLog`를 재생만 한다. 배속, 일시정지, 다시 보기, 전투 기록 패널이 모두 같은 로그를 쓴다.
- 같은 입력과 같은 시드면 항상 같은 결과가 나와야 한다(결정론). 버그를 재현하고, 저장된 판을 다시 보고, 시뮬레이터를 돌리는 기반이다.
- 연쇄는 이벤트 큐로 처리한다(기획서 5.4). 깊이 3 제한, 같은 행동 안에서 같은 특성 1회 발동.

## 3. 데이터 설계 (Resource)

| Resource | 주요 필드 |
|---|---|
| `YokaiDef` | id, 이름 키, 계열, 계급, 공/체/속, 고유 특성 id, 일러스트 경로 |
| `TraitDef` | id, 발동 시점(trigger), 조건, 효과 목록, 수치 |
| `CharmDef` | id, 이득 효과, 대가 효과, 비용 |
| `ProcessionDef` | id, 밤 범위, 진영 구성, 고유 규칙 효과 |
| `EventDef` | id, 선택지, 결과 효과 |

- 특성과 부적은 **트리거 + 조건 + 효과** 조합으로 적는다. 새 콘텐츠는 대부분 코드 없이 `.tres` 데이터만으로 추가한다.
- 데이터로 표현할 수 없는 특수 효과만 `effects/` 아래 스크립트로 만든다.
- 화면에 보이는 모든 문구는 번역 키로 적는다. 실제 문구는 `i18n/*.csv`(Godot 번역 CSV, ko/en)에 둔다.

## 4. 디렉터리 구조

```text
project.godot
assets/            # 게임용으로 내보낸 이미지·소리·폰트 (원본 .kra는 레포 밖에 보관)
data/
  yokai/  traits/  charms/  processions/  events/
i18n/              # ko.csv, en.csv
scenes/
  main.tscn        # 화면 전환
  market/          # 장터 (고용·먹기·부적)
  formation/       # 진영 배치
  battle/          # 전투 재생
  result/          # 밤 결과, 원정 결과
  ui/              # 공용 UI 컴포넌트
scripts/
  autoload/        # Game(원정 진행), Save, Audio, Settings
  core/            # 순수 로직: run_state, market, absorb, battle_sim, event_queue, rng
  effects/         # 데이터로 표현 못 하는 특수 효과
tests/             # gdUnit4 테스트 (core 위주)
tools/
  sim.gd           # 헤드리스 밸런스 시뮬레이터
docs/
```

## 5. 시드와 RNG

- 원정 시작 시 시드 1개를 정한다. 그 시드에서 **장터 / 전투 / 사건** 용 RNG를 따로 만든다.
- 그러면 전투에서 확률이 바뀌어도(예: 홀림 확률 조정) 장터 진열은 그대로 유지된다.
- 저장 파일에는 시드와 RNG 상태를 함께 저장한다. 이어하기를 해도 같은 결과가 나온다.

## 6. 저장

- `user://run.json`: 진행 중인 원정. 밤이 끝날 때와 장터를 나갈 때 자동 저장한다.
- `user://profile.json`: 도감, 해금, 설정.
- 형식은 JSON이고 버전 필드를 둔다. 정식 출시 때 Steam 클라우드 저장에 같은 파일을 연결한다.

## 7. 테스트와 시뮬레이터

- **gdUnit4**로 `scripts/core/`를 테스트한다. 대상은 먹기 규칙, 대상 선택, 연쇄 깊이 제한, 결정론(같은 시드 → 같은 로그) 등이다.
- **헤드리스 시뮬레이터**: `godot --headless --script tools/sim.gd -- --runs 1000`. 무작위 진영끼리 수천 판을 돌린다. 계열별 승률, 특성 조합별 승률, 평균 전투 시간, 닭 울음으로 끝난 비율을 CSV로 뽑는다.
- CI에서 테스트와 짧은 시뮬레이션(100판)을 PR마다 돌린다.

## 8. 빌드와 미리보기

| 대상 | 방법 |
|---|---|
| 웹 미리보기 | CI가 `develop`에 머지될 때마다 웹(HTML5, 싱글 스레드) 빌드를 만들어 Firebase Hosting에 배포. 브라우저로 바로 해 볼 수 있음 |
| Windows | CI에서 export, 아티팩트로 내려받기 |
| Steam | 출시 단계에서 GodotSteam 애드온 + steamcmd 업로드. 계정 정보는 GitHub repo secret |

### 8.1 웹 미리보기 호스팅

- Firebase 프로젝트 `minthold-preview`는 **여러 게임의 미리보기를 함께 올리는 곳**이다.
- Hosting은 배포할 때 사이트 전체를 덮어쓴다. 그래서 게임마다 **사이트를 따로** 만든다. 이 게임은 `minthold-baekgwi` → https://minthold-baekgwi.web.app
- 다른 게임도 같은 규칙으로 `minthold-<코드명>` 사이트를 쓴다.
- 배포 키: GitHub repo secret `FIREBASE_SERVICE_ACCOUNT`(모노레포 전체가 같이 쓴다). 서비스 계정 역할은 Firebase Hosting Admin.
- PR마다 3일짜리 미리보기 채널(`minthold-baekgwi--pr-…web.app`)에 올리고, PR 댓글로 주소를 남긴다.
- Godot 웹 빌드는 스레드를 끈 싱글 스레드 export다. 그래서 COOP/COEP 헤더가 필요 없다.

- 기준 해상도는 **1920×1080**이다. Steam Deck(1280×800, 16:10)에서는 위아래 여백만 늘어나도록 `canvas_items` + `expand`로 맞춘다.
- 입력은 마우스 드래그 기준이다. 모든 조작에 컨트롤러 대응(포커스 이동 + 집기/놓기 버튼)을 함께 만든다.

## 9. 브랜치

`main` ← `develop` ← 기능 브랜치. PR은 `develop`으로 올린다. `main`은 출시·데모 빌드용이다.
