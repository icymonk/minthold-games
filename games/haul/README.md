# 막차 택배 (`haul`)

**막차 택배 (Haul Order)** — 내릴 순서를 거꾸로 계산하며 트럭 짐칸을 채우는 적재 퍼즐 로그라이트 (Godot 4, Steam).

- 웹 미리보기: https://minthold-haul.web.app (`develop` 머지 시 자동 배포)

- 기획서: [docs/design.md](docs/design.md)
- 개발 환경·아키텍처: [docs/architecture.md](docs/architecture.md)
- 개발 단계: [docs/plan.md](docs/plan.md)

## 개발

Godot 4.7.2로 이 폴더(`games/haul`)를 연다.

```bash
# 테스트 (gdUnit4)
godot --headless --import
GODOT_BIN=$(which godot) bash addons/gdUnit4/runtest.sh --headless -a res://tests --ignoreHeadlessMode

# 웹 빌드 (Web export template 필요)
godot --headless --export-release "Web" build/web/index.html
```

CI는 [`.github/workflows/haul.yml`](../../.github/workflows/haul.yml)이다. PR마다 테스트·웹 빌드를 하고 3일짜리 미리보기 채널에 올린다. `develop`에 머지되면 https://minthold-haul.web.app 에 배포한다.
