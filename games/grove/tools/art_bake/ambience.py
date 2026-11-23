"""계절 숲 소리(3-2)를 코드로 합성한다: 바람 + 계절마다 새·풀벌레·낙엽·눈바람.
python3 tools/art_bake/ambience.py → assets/sfx/amb_<계절>.ogg (12초, 끊김 없이 반복)."""
import subprocess, wave, numpy as np, os

SR = 22050
N = SR * 12
rng = np.random.default_rng(7)
t = np.arange(N) / SR


def lowpass(x, a):
    y = np.empty_like(x); acc = 0.0
    for i in range(len(x)):
        acc += a * (x[i] - acc); y[i] = acc
    return y


def loop_fade(x, n=SR):
    # 끝을 앞으로 겹쳐 반복 이음새를 없앤다
    head, tail = x[:n].copy(), x[-n:]
    w = np.linspace(0, 1, n)
    x = x[:-n].copy(); x[:n] = head * w + tail * (1 - w)
    return x


def wind(strength):
    n = lowpass(rng.standard_normal(N + SR), 0.02)
    swell = 0.6 + 0.4 * np.sin(2 * np.pi * (np.arange(N + SR) / SR) / 6.0)
    return n * swell * strength


def chirps(count, f0, f1, dur, gain):
    out = np.zeros(N + SR)
    for _ in range(count):
        s = rng.integers(0, N); L = int(dur * SR); k = np.arange(L) / SR
        f = np.linspace(f0, f1, L) * rng.uniform(0.85, 1.15)
        env = np.sin(np.pi * k / dur) ** 2
        for r in range(rng.integers(2, 5)):
            a = s + r * int(L * 1.3)
            if a + L < len(out):
                out[a:a + L] += np.sin(2 * np.pi * np.cumsum(f) / SR) * env * gain
    return out


def crickets(gain):
    k = np.arange(N + SR) / SR
    pulse = (np.sin(2 * np.pi * 28 * k) > 0.3) * (np.sin(2 * np.pi * 0.7 * k) > -0.2)
    return np.sin(2 * np.pi * 4300 * k) * pulse * gain


def rustle(count, gain):
    out = np.zeros(N + SR)
    for _ in range(count):
        s = rng.integers(0, N); L = int(rng.uniform(0.1, 0.35) * SR)
        burst = rng.standard_normal(L) * np.hanning(L)
        out[s:s + L] += burst * gain
    return out


SEASONS = {
    "spring": lambda: wind(0.5) + chirps(14, 3200, 4200, 0.09, 0.12),
    "summer": lambda: wind(0.35) + crickets(0.035) + chirps(5, 2600, 2000, 0.14, 0.08),
    "autumn": lambda: wind(0.7) + rustle(40, 0.05) + chirps(4, 1800, 1500, 0.2, 0.06),
    "winter": lambda: wind(1.1) + lowpass(rng.standard_normal(N + SR), 0.3) * 0.03,
}

out_dir = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sfx")
for name, make in SEASONS.items():
    x = loop_fade(make())
    x = x / np.max(np.abs(x)) * 0.5
    tmp = f"/tmp/amb_{name}.wav"
    with wave.open(tmp, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "2",
                    os.path.join(out_dir, f"amb_{name}.ogg")], check=True)
    print(name, "ok")
