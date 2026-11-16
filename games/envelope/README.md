# 봉투는 돌고 돈다 (`envelope`)

**봉투는 돌고 돈다 (Pass the Envelope)** — 퇴사 선물 모금봉투를 채우며 돈을 빼 간 범인을 찾는, AI 상대 숨은 정체 카드 게임 (Godot 4).

- 웹 미리보기: https://minthold-envelope.web.app (`develop` 머지 시 자동 배포)

- 기획서: [docs/design.md](docs/design.md)
- 개발 환경·아키텍처: [docs/architecture.md](docs/architecture.md)
- 개발 단계: [docs/plan.md](docs/plan.md)

## 개발

Godot 4.7.2로 이 폴더(`games/envelope`)를 연다.

```bash
# 테스트 (gdUnit4)
godot --headless --import
GODOT_BIN=$(which godot) bash addons/gdUnit4/runtest.sh --headless -a res://tests --ignoreHeadlessMode

# 웹 빌드 (Web export template 필요)
godot --headless --export-release "Web" build/web/index.html
```

CI는 [`.github/workflows/envelope.yml`](../../.github/workflows/envelope.yml)이다. PR마다 테스트·웹 빌드를 하고 3일짜리 미리보기 채널에 올린다. `develop`에 머지되면 https://minthold-envelope.web.app 에 배포한다.
