# minthold-games

Minthold 인디 게임 모노레포 (Godot 4 + GDScript).

## 게임

| 코드명 | 제목 | 웹 미리보기 |
|---|---|---|
| [rooster](games/rooster) | 닭이 울기 전에 (Before the Rooster Crows) | https://minthold-rooster.web.app |
| [haul](games/haul) | 막차 택배 (Haul Order) | https://minthold-haul.web.app |
| [looseend](games/looseend) | 끝이 어디야? (Loose End) | (준비 중) |
| [envelope](games/envelope) | 봉투는 돌고 돈다 (Pass the Envelope) | https://minthold-envelope.web.app |
| [postage](games/postage) | 우표 붙이는 우체국 (Postage Paid) | (준비 중) |
| [hive](games/hive) | 꿀 따는 계절 (Honey Season) | (준비 중) |
| [desk](games/desk) | 땡땡이 (Away From Desk) | (준비 중) |

## 규칙

- 게임마다 `games/<코드명>/`에 독립된 Godot 프로젝트를 둔다(`project.godot`가 그 폴더에 있다).
- 브랜치: `main` ← `develop` ← 작업 브랜치. PR은 `develop`으로 보낸다.
- 웹 미리보기: Firebase 프로젝트 `minthold-preview`. Hosting 사이트는 게임마다 따로 둔다 — `minthold-<코드명>` → `https://minthold-<코드명>.web.app`. 사이트가 없으면 CI가 첫 배포 때 만든다.
- 새 게임 추가: `games/<코드명>/`(`.firebaserc`의 사이트를 `minthold-<코드명>`으로), `.github/workflows/rooster.yml`을 복사해 코드명만 바꾼다.
- 배포 키: repo secret `FIREBASE_SERVICE_ACCOUNT` 하나를 모든 게임이 같이 쓴다.
- CI: 바뀐 게임 폴더만 테스트·빌드·배포한다.
