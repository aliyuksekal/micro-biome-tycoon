#!/usr/bin/env python3
"""Oyun ses efektleri ve döngü müziğini prosedürel olarak üretir (lisans sorunu yok).
Kullanım: python3 tools/make_audio.py   -> assets/audio/*.wav
"""
import os, wave, math
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio")


def env(n, a=0.005, r=0.2):
    t = np.arange(n) / SR
    e = np.minimum(1, t / max(a, 1e-4)) * np.exp(-t / max(r, 1e-4))
    return e


def tone(freq, dur, kind="sine", a=0.005, r=0.15, vib=0.0):
    n = int(SR * dur)
    t = np.arange(n) / SR
    f = freq * (1 + vib * np.sin(2 * math.pi * 6 * t))
    ph = 2 * math.pi * np.cumsum(f) / SR
    if kind == "sine":
        w = np.sin(ph)
    elif kind == "tri":
        w = 2 / math.pi * np.arcsin(np.sin(ph))
    elif kind == "marimba":
        w = np.sin(ph) + 0.35 * np.sin(4 * ph) * np.exp(-t * 30)
    else:
        w = np.sign(np.sin(ph)) * 0.5
    return w * env(n, a, r)


def sweep(f0, f1, dur, r=0.2, kind="sine"):
    n = int(SR * dur)
    t = np.arange(n) / SR
    f = f0 * (f1 / f0) ** (t / dur)
    ph = 2 * math.pi * np.cumsum(f) / SR
    w = np.sin(ph) if kind == "sine" else 2 / math.pi * np.arcsin(np.sin(ph))
    return w * env(n, 0.004, r)


def noise(dur, r=0.08, lp=0.3):
    n = int(SR * dur)
    x = np.random.default_rng(1).normal(0, 1, n)
    y = np.zeros(n)
    for i in range(1, n):
        y[i] = y[i - 1] + lp * (x[i] - y[i - 1])
    return y * env(n, 0.002, r)


def mix(*parts):
    n = max(len(p) for p, _ in parts)
    out = np.zeros(n)
    for p, off in parts:
        o = int(off * SR)
        out[o:o + len(p)] += p[: max(0, n - o)]
    return out


def save(name, x, gain=0.6):
    x = x / (np.max(np.abs(x)) + 1e-9) * gain
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def pad_to(x, dur):
    n = int(SR * dur)
    return np.pad(x, (0, max(0, n - len(x))))[:n]


def main():
    os.makedirs(OUT, exist_ok=True)
    save("tap.wav", tone(880, 0.09, "sine", r=0.03), 0.45)
    save("button.wav", mix((tone(660, 0.08, "tri", r=0.04), 0), (tone(990, 0.08, "tri", r=0.04), 0.04)), 0.4)
    save("place.wav", mix((sweep(300, 700, 0.16, r=0.08), 0), (tone(1046, 0.18, "marimba", r=0.09), 0.08)), 0.55)
    save("eat.wav", mix((noise(0.06, 0.03, 0.5), 0), (noise(0.06, 0.03, 0.5), 0.1), (tone(520, 0.1, "sine", r=0.05), 0.02)), 0.5)
    save("hit.wav", mix((noise(0.12, 0.05, 0.6), 0), (sweep(420, 140, 0.15, r=0.07, kind="tri"), 0)), 0.6)
    save("defeat.wav", mix((sweep(700, 200, 0.25, r=0.12, kind="tri"), 0), (noise(0.2, 0.1, 0.3), 0.05)), 0.55)
    save("coin.wav", mix((tone(1318, 0.08, "sine", r=0.05), 0), (tone(1760, 0.2, "sine", r=0.12), 0.06)), 0.45)
    save("levelup.wav", mix(*[(tone(f, 0.22, "marimba", r=0.12), i * 0.07) for i, f in enumerate([523, 659, 784, 1046])]), 0.55)
    save("alert.wav", mix((tone(440, 0.16, "tri", r=0.1, vib=0.02), 0), (tone(370, 0.22, "tri", r=0.14, vib=0.02), 0.16)), 0.5)
    save("gameover.wav", mix(*[(tone(f, 0.45, "tri", r=0.3), i * 0.22) for i, f in enumerate([392, 330, 262, 196])]), 0.55)
    save("gift.wav", mix(*[(tone(f, 0.35, "marimba", r=0.2), i * 0.06) for i, f in enumerate([784, 988, 1175, 1568, 1976])]), 0.5)
    # müzik: 100 bpm, 8 ölçü döngü, sakin marimba + pad
    bpm = 100; beat = 60 / bpm; bars = 8; dur = bars * 4 * beat
    chords = [(261.6, 329.6, 392.0), (220.0, 261.6, 329.6), (174.6, 220.0, 261.6), (196.0, 246.9, 293.7)] * 2
    music = np.zeros(int(SR * dur) + SR)
    for b, ch in enumerate(chords):
        t0 = b * 4 * beat
        for k in range(8):  # sekizlik arpej
            f = ch[[0, 1, 2, 1, 0, 2, 1, 2][k]] * 2
            n = tone(f, beat * 0.9, "marimba", a=0.003, r=0.22) * 0.35
            o = int((t0 + k * beat / 2) * SR); music[o:o + len(n)] += n
        for f in ch:  # pad
            n = tone(f, 4 * beat, "sine", a=0.6, r=3.0) * 0.12
            o = int(t0 * SR); music[o:o + len(n)] += n
        bass = tone(ch[0] / 2, beat * 1.8, "tri", a=0.01, r=0.5) * 0.25
        for k in (0, 2):
            o = int((t0 + k * beat) * SR); music[o:o + len(bass)] += bass
    # döngü sonu kuyruğunu başa ekle (kesintisiz döngü)
    L = int(SR * dur)
    tail = music[L:]; music = music[:L]; music[:len(tail)] += tail
    save("music_loop.wav", music, 0.5)
    print("ok")


if __name__ == "__main__":
    main()
