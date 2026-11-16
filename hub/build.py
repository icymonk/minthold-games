#!/usr/bin/env python3
"""games/*/game.json + docs/plan.md + git 기록으로 미리보기 모음 페이지(build/index.html)를 만든다."""
import html
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAMES = ROOT / "games"
HUB = Path(__file__).resolve().parent
OUT = HUB / "build"
SHOTS = HUB / "shots"
FONTS = ROOT / "games" / "rooster" / "assets" / "fonts"
WEIGHTS = {400: "Pretendard-Regular.otf", 700: "Pretendard-Bold.otf"}
REPO = "https://github.com/icymonk/minthold-games"
REQUIRED = ("title", "title_en", "genre", "summary", "how_to_play", "preview")
ITEM = re.compile(r"^\s*- \[([ xX])\] (\d+)-(\w+)\s+(.*)$")


def plan_items(code):
    plan = GAMES / code / "docs" / "plan.md"
    if not plan.exists():
        return []
    items = []
    for line in plan.read_text(encoding="utf-8").splitlines():
        m = ITEM.match(line)
        if m:
            items.append({"done": m[1] != " ", "id": f"{m[2]}-{m[3]}", "text": m[4].replace("`", "")})
    return items


def version(items):
    done = [i for i in items if i["done"]]
    if not done:
        return "0.0.0"
    stage, step = done[-1]["id"].split("-", 1)
    return f"0.{stage}.{step}"


def git_last(code):
    out = subprocess.run(
        ["git", "log", "-1", "--format=%ct %cs %h", "--", f"games/{code}"],
        cwd=ROOT, capture_output=True, text=True, check=True,
    ).stdout.split()
    return (int(out[0]), out[1], out[2]) if out else (0, "-", "")


def load():
    games = []
    for d in sorted(p for p in GAMES.iterdir() if p.is_dir()):
        meta_path = d / "game.json"
        if not meta_path.exists():
            raise SystemExit(f"games/{d.name}/game.json 없음")
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
        missing = [k for k in REQUIRED if k not in meta]
        if missing:
            raise SystemExit(f"games/{d.name}/game.json 빠진 항목: {missing}")
        items = plan_items(d.name)
        ts, date, sha = git_last(d.name)
        games.append({
            **meta,
            "code": d.name,
            "url": f"https://minthold-{d.name}.web.app",
            "version": version(items),
            "done": sum(i["done"] for i in items),
            "total": len(items),
            "recent": [i for i in items if i["done"]][-3:][::-1],
            "next": next((i for i in items if not i["done"]), None),
            "ts": ts, "date": date, "sha": sha,
            "shot": (SHOTS / f"{d.name}.png").exists(),
        })
    games.sort(key=lambda g: (not g["preview"], -g["ts"], g["code"]))
    return games


def card(g):
    e = html.escape
    pct = round(100 * g["done"] / g["total"]) if g["total"] else 0
    shot = f'<img class="shot" src="shots/{g["code"]}.png" alt="{e(g["title"])} 화면" loading="lazy">' if g["shot"] else '<div class="shot none">미리보기 준비 중</div>'
    play = (f'<a class="btn play" href="{g["url"]}" target="_blank" rel="noopener">플레이</a>'
            if g["preview"] else '<span class="btn off">준비 중</span>')
    steps = "".join(f"<li>{e(s)}</li>" for s in g["how_to_play"])
    recent = "".join(f'<li><b>{e(i["id"])}</b> {e(i["text"])}</li>' for i in g["recent"]) or "<li>기획 문서만 있습니다</li>"
    nxt = f'<p class="next">다음: <b>{e(g["next"]["id"])}</b> {e(g["next"]["text"])}</p>' if g["next"] else '<p class="next">계획한 단계를 모두 끝냈습니다</p>'
    commit = f'<a href="{REPO}/commit/{g["sha"]}" target="_blank" rel="noopener">{g["sha"]}</a>' if g["sha"] else ""
    return f"""<article class="card">
  {shot}
  <div class="body">
    <h2>{e(g["title"])} <small>{e(g["title_en"])}</small></h2>
    <p class="meta"><span class="tag">{e(g["genre"])}</span><span class="ver">v{e(g["version"])}</span><span>수정 {e(g["date"])} {commit}</span></p>
    <p>{e(g["summary"])}</p>
    <div class="bar" title="계획 {g["done"]}/{g["total"]}"><i style="width:{pct}%"></i></div>
    <p class="prog">개발 단계 {g["done"]}/{g["total"]}</p>
    <details><summary>하는 방법</summary><ol>{steps}</ol></details>
    <details><summary>최근 업데이트</summary><ul>{recent}</ul>{nxt}</details>
    <div class="links">{play}<a class="btn" href="{REPO}/blob/develop/games/{g["code"]}/docs/design.md" target="_blank" rel="noopener">기획서</a></div>
  </div>
</article>"""


def page(games):
    playable = sum(g["preview"] for g in games)
    latest = max((g["date"] for g in games), default="-")
    cards = "\n".join(card(g) for g in games)
    return f"""<!doctype html>
<html lang="ko"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Minthold Games 미리보기</title>
<style>
@font-face{{font-family:Pretendard;font-weight:400;font-display:swap;src:url(fonts/pretendard-400.woff2) format("woff2")}}
@font-face{{font-family:Pretendard;font-weight:700;font-display:swap;src:url(fonts/pretendard-700.woff2) format("woff2")}}
:root{{--bg:#f6efe2;--ink:#2b2a28;--sub:#6d675e;--card:#fff;--line:#e4d9c6;--accent:#d9534f;--mint:#3aa58a}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--ink);font:16px/1.55 Pretendard,system-ui,-apple-system,"Apple SD Gothic Neo","Noto Sans KR",sans-serif}}
header{{max-width:1200px;margin:0 auto;padding:40px 20px 8px}}h1{{margin:0;font-size:32px}}header p{{margin:6px 0 0;color:var(--sub)}}
main{{max-width:1200px;margin:0 auto;padding:20px;display:grid;gap:20px;grid-template-columns:repeat(auto-fill,minmax(340px,1fr))}}
.card{{background:var(--card);border:1px solid var(--line);border-radius:14px;overflow:hidden;display:flex;flex-direction:column}}
.shot{{width:100%;aspect-ratio:16/9;object-fit:cover;display:block;background:#ece3d3}}.shot.none{{display:grid;place-items:center;color:var(--sub);font-size:14px}}
.body{{padding:16px 18px 18px;display:flex;flex-direction:column;gap:6px;flex:1}}h2{{margin:0;font-size:21px}}h2 small{{font-size:14px;color:var(--sub);font-weight:500}}
.body>p{{margin:0}}.meta{{display:flex;flex-wrap:wrap;gap:8px;font-size:13px;color:var(--sub)}}.meta a{{color:var(--sub)}}
.tag{{background:#f1e8d8;border-radius:6px;padding:1px 8px}}.ver{{background:var(--mint);color:#fff;border-radius:6px;padding:1px 8px;font-weight:600}}
.bar{{height:6px;background:#efe6d6;border-radius:3px;overflow:hidden;margin-top:6px}}.bar i{{display:block;height:100%;background:var(--mint)}}.prog{{font-size:12px;color:var(--sub)}}
details{{border-top:1px solid var(--line);padding-top:6px}}summary{{cursor:pointer;font-weight:600}}details ol,details ul{{margin:6px 0;padding-left:20px;font-size:14px}}.next{{font-size:13px;color:var(--sub);margin:0}}
.links{{margin-top:auto;padding-top:10px;display:flex;gap:8px}}.btn{{flex:1;text-align:center;padding:9px;border:1px solid var(--line);border-radius:8px;color:var(--ink);text-decoration:none;font-weight:600}}
.btn.play{{background:var(--accent);border-color:var(--accent);color:#fff}}.btn.off{{color:var(--sub);background:#f4efe6}}
footer{{max-width:1200px;margin:0 auto;padding:10px 20px 40px;color:var(--sub);font-size:13px}}footer a{{color:var(--sub)}}
</style></head><body>
<header><h1>Minthold Games 미리보기</h1>
<p>개발 중인 게임 {len(games)}개 · 바로 해 볼 수 있는 게임 {playable}개 · 최근 수정 {latest}</p></header>
<main>
{cards}
</main>
<footer>버전은 각 게임의 개발 단계 계획(<code>docs/plan.md</code>)에서 마지막으로 끝낸 단계입니다(3-5 → v0.3.5). 수정일은 그 게임 폴더의 마지막 커밋 날짜입니다. 미리보기는 <code>develop</code>에 머지될 때 자동으로 갱신됩니다. · <a href="{REPO}">GitHub</a></footer>
</body></html>
"""


def subset_fonts(text):
    """페이지에 쓴 글자만 남긴 Pretendard woff2를 만든다(원본 1.5MB → 수십 KB)."""
    try:
        from fontTools import subset
    except ImportError:
        print("fonttools 없음 — 시스템 글꼴을 씁니다", file=sys.stderr)
        return False
    (OUT / "fonts").mkdir()
    opts = subset.Options()
    opts.flavor = "woff2"
    for weight, name in WEIGHTS.items():
        font = subset.load_font(str(FONTS / name), opts)
        sub = subset.Subsetter(opts)
        sub.populate(text=text)
        sub.subset(font)
        subset.save_font(font, str(OUT / "fonts" / f"pretendard-{weight}.woff2"), opts)
    shutil.copy(FONTS / "LICENSE-Pretendard.txt", OUT / "fonts")
    return True


def main():
    games = load()
    if OUT.exists():
        shutil.rmtree(OUT)
    shutil.copytree(SHOTS, OUT / "shots")
    html_text = page(games)
    subset_fonts(re.sub(r"<[^>]+>", "", html_text))
    (OUT / "index.html").write_text(html_text, encoding="utf-8")
    print(f"{len(games)} games -> {OUT / 'index.html'}")


if __name__ == "__main__":
    sys.exit(main())
