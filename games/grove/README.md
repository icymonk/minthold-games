# 작은 숲 (`grove`)

**작은 숲 (Little Grove)** — 나무를 심고 카드를 낼 때마다 그 나무에 새·곤충·짐승이 실제로 날아와 붙는 2.5D 숲 가꾸기 카드 로그라이트 (Godot 4 3D, Steam). 원작 보드게임: Forest Shuffle.

- 웹 미리보기: https://minthold-grove.web.app (`develop` 머지 시 자동 배포)
- 맥용 앱: `develop` 머지 때 [grove 워크플로](../../.github/workflows/grove.yml)가 `grove-macos` 아티팩트(.app zip)를 만든다. 서명하지 않은 앱이라 처음 한 번은 우클릭 → 열기
- 그림·소리 출처: [CREDITS.md](CREDITS.md)
- 기획서: [docs/design.md](docs/design.md)
- 개발 단계: [docs/plan.md](docs/plan.md)

공통 기준은 [`docs/game-guide.md`](../../docs/game-guide.md), 구조와 개발 환경은 [`games/rooster/docs/architecture.md`](../rooster/docs/architecture.md)를 따른다(Godot 4.7.x, gdUnit4, 규칙 로직과 화면 분리).

## 실행

Godot 4.7.x로 이 폴더를 열고 실행(F5). PC·맥(Steam용)은 Forward+, 웹은 Compatibility 렌더러로 같은 프로젝트를 내보낸다.

```bash
godot --headless --import
GODOT_BIN=$(which godot) bash addons/gdUnit4/runtest.sh --headless -a res://tests --ignoreHeadlessMode
godot --headless --export-release "Web" build/web/index.html
godot --headless --export-release "macOS" build/macos/grove-macos.zip
xvfb-run -a godot --path . --resolution 1920x1080 -s res://tools/shot.gd -- /tmp/shots  # 1080p 스크린샷
```

게임 안에서 F3을 누르면 프레임·그리기 호출 수가 보인다. 숲 모델은 `tools/art_bake/fetch.sh`로 다시 받을 수 있다(결과는 `assets/models/nature/`에 커밋돼 있다).

## 구조

- `scripts/autoload/game.gd` — 화면 전환·계절 상태(규칙 엔진은 1단계에서 `scripts/rules/`로)
- `scripts/world/forest_view.gd` — 3D 숲 섬·하늘·빛·카메라(비스듬한 고정, 90° 돌리기)·계절 색·풀 흩뿌리기
- `scripts/world/forest_tree.gd` — 나무 8종, 생물이 붙는 자리 `Socket` 4개(Top·Bottom·Left·Right)
- `scripts/world/nature.gd`, `shaders/nature.gdshader` — 팩 모델에 씌우는 공통 재질(계절 색 다시 칠하기·바람·부드러운 2단계 빛)
- `scripts/screens/` — 제목·계절·오두막·런 끝 화면(숲 위에 뜨는 2D UI)
- `scripts/ui/style.gd` — 색·글자 크기·테마(색은 여기서만 꺼내 쓴다)
