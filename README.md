# minthold-games

Minthold 인디 게임 모노레포 (Godot 4 + GDScript).

## 게임

**미리보기 모음:** https://minthold-games.web.app — 게임마다 소개·하는 방법·버전·최근 수정일과 플레이 링크를 모아 둔 페이지([`hub/`](hub)).

| 코드명 | 제목 | 웹 미리보기 |
|---|---|---|
| [rooster](games/rooster) | 닭이 울기 전에 (Before the Rooster Crows) | https://minthold-rooster.web.app |
| [haul](games/haul) | 막차 택배 (Haul Order) | https://minthold-haul.web.app |
| [looseend](games/looseend) | 끝이 어디야? (Loose End) | (준비 중) |
| [envelope](games/envelope) | 봉투는 돌고 돈다 (Pass the Envelope) | https://minthold-envelope.web.app |
| [postage](games/postage) | 우표 붙이는 우체국 (Postage Paid) | (준비 중) |
| [hive](games/hive) | 꿀 따는 계절 (Honey Season) | (준비 중) |
| [desk](games/desk) | 땡땡이 (Away From Desk) | https://minthold-desk.web.app |
| [cleanpull](games/cleanpull) | 식탁보 빼기 (Clean Pull) | https://minthold-cleanpull.web.app |
| [nightmart](games/nightmart) | 심야 편의점 (Night Mart) | https://minthold-nightmart.web.app |
| [hearth](games/hearth) | 장작이 꺼지기 전에 (Keep the Fire) | (준비 중) |
| [jianghu](games/jianghu) | 강호 객잔 (Jianghu Inn) | (준비 중) |

## 규칙

- 게임 만들기 기준(로그라이트 구조, 크고 그림 위주인 콘솔식 화면, 처음 할 때 단계별 안내): [`docs/game-guide.md`](docs/game-guide.md).
- 게임마다 `games/<코드명>/`에 독립된 Godot 프로젝트를 둔다(`project.godot`가 그 폴더에 있다).
- 브랜치: `main` ← `develop` ← 작업 브랜치. PR은 `develop`으로 보낸다.
- 웹 미리보기: Firebase 프로젝트 `minthold-preview`. Hosting 사이트는 게임마다 따로 둔다 — `minthold-<코드명>` → `https://minthold-<코드명>.web.app`. 사이트가 없으면 CI가 첫 배포 때 만든다.
- 새 게임 추가: `games/<코드명>/`(`.firebaserc`의 사이트를 `minthold-<코드명>`으로), `.github/workflows/rooster.yml`을 복사해 코드명만 바꾼다.
- 미리보기 모음: 게임마다 `games/<코드명>/game.json`(제목·장르·소개·하는 방법·`preview`)을 둔다. 없으면 `hub` CI가 실패한다. 웹 미리보기가 생기면 `preview: true`로 바꾸고 제목 화면을 `hub/shots/<코드명>.png`(640×360)로 넣는다. 버전은 `docs/plan.md`에서 마지막으로 끝낸 단계(3-5 → v0.3.5), 수정일은 게임 폴더의 마지막 커밋 날짜로 자동으로 정해진다.
- 배포 키: repo secret `FIREBASE_SERVICE_ACCOUNT` 하나를 모든 게임이 같이 쓴다.
- CI: 바뀐 게임 폴더만 테스트·빌드·배포한다.
