# 땡땡이 (`desk`)

**땡땡이 (Away From Desk)** — 퇴근까지 42분, 몰래 자리를 비운 시각을 숨기는 사원과 그 시각을 짚어 내는 팀장의 1대1 추리 카드 게임 (Godot 4).

- 웹 미리보기: https://minthold-desk.web.app (`develop` 머지 시 자동 배포)

- 기획서: [docs/design.md](docs/design.md)
- 개발 환경·아키텍처: [docs/architecture.md](docs/architecture.md)
- 개발 단계: [docs/plan.md](docs/plan.md)

## 개발

Godot 4.7.2로 이 폴더(`games/desk`)를 연다.

```bash
# 테스트 (gdUnit4)
godot --headless --import
GODOT_BIN=$(which godot) bash addons/gdUnit4/runtest.sh --headless -a res://tests --ignoreHeadlessMode

# 웹 빌드 (Web export template 필요)
godot --headless --export-release "Web" build/web/index.html
```

CI는 [`.github/workflows/desk.yml`](../../.github/workflows/desk.yml)이다. PR마다 테스트·웹 빌드를 하고 3일짜리 미리보기 채널에 올린다. `develop`에 머지되면 https://minthold-desk.web.app 에 배포한다.
