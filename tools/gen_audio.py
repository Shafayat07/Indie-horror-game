#!/usr/bin/env python3
"""Synthesises every sound effect and ambience loop for THE TIDE REMEMBERS.

All audio is original and generated procedurally with numpy (no samples, no
third-party recordings). Loops are built from circular FFT-filtered noise so
they repeat without seams.
Run:  python3 tools/gen_audio.py
"""
import os
import wave
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rng = np.random.default_rng(7)

# Relay tone frequencies (A, B, C) and the authored solution order.
# The same motif is hidden in the lighthouse signal, the calibration tape and the finale.
RELAY_FREQS = [196.0, 277.2, 415.3]
SEQUENCE = [1, 0, 2, 0]


def t_axis(dur):
    return np.arange(int(dur * SR)) / SR


def write(name, x, peak=0.9):
    os.makedirs(OUT, exist_ok=True)
    x = np.asarray(x, dtype=float)
    m = np.max(np.abs(x)) + 1e-9
    x = x / m * peak
    data = (x * 32767).astype(np.int16)
    with wave.open(f"{OUT}/{name}.wav", "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("wrote", name, f"{len(x)/SR:.2f}s")


def noise(dur):
    return rng.standard_normal(int(dur * SR))


def fft_filter(x, gain_fn):
    """Circular (loop-safe) frequency-domain filter."""
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    return np.fft.irfft(X * gain_fn(f), len(x))


def bandpass(x, lo, hi, soft=1.0):
    def g(f):
        a = 1 / (1 + (lo / np.maximum(f, 1)) ** (2 * soft))
        b = 1 / (1 + (f / hi) ** (2 * soft))
        return a * b
    return fft_filter(x, g)


def lowpass(x, hi, order=2):
    return fft_filter(x, lambda f: 1 / (1 + (f / hi) ** (2 * order)))


def highpass(x, lo, order=2):
    return fft_filter(x, lambda f: 1 / (1 + (lo / np.maximum(f, 1)) ** (2 * order)))


def env_ad(n, attack, decay_tau):
    t = np.arange(n) / SR
    e = np.minimum(t / max(attack, 1e-4), 1.0) * np.exp(-np.maximum(t - attack, 0) / decay_tau)
    return e


def modes(freqs, taus, amps, dur, detune=0.0):
    t = t_axis(dur)
    out = np.zeros_like(t)
    for f, tau, a in zip(freqs, taus, amps):
        f2 = f * (1 + rng.uniform(-detune, detune))
        out += a * np.sin(2 * np.pi * f2 * t + rng.uniform(0, 6.28)) * np.exp(-t / tau)
    return out


def convolve(x, ir):
    n = len(x) + len(ir) - 1
    N = 1 << (n - 1).bit_length()
    y = np.fft.irfft(np.fft.rfft(x, N) * np.fft.rfft(ir, N), N)[:n]
    return y


def reverb(x, size=1.2, mix=0.35, damp=3000):
    ir = noise(size) * np.exp(-t_axis(size) / (size / 5))
    ir = lowpass(ir, damp)
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    wet = convolve(x, ir)
    dry = np.concatenate([x, np.zeros(len(wet) - len(x))])
    return dry * (1 - mix) + wet * mix * 0.6


def pad(x, dur):
    n = int(dur * SR)
    out = np.zeros(max(n, len(x)))
    out[:len(x)] = x
    return out


def place(buf, x, at):
    i = int(at * SR)
    j = min(len(buf), i + len(x))
    if i < len(buf):
        buf[i:j] += x[:j - i]


def fade(x, fin=0.005, fout=0.02):
    x = x.copy()
    a, b = int(fin * SR), int(fout * SR)
    if a:
        x[:a] *= np.linspace(0, 1, a)
    if b:
        x[-b:] *= np.linspace(1, 0, b)
    return x


def slow_lfo(n, rate, seed_phase=None):
    t = np.arange(n) / SR
    return np.sin(2 * np.pi * rate * t + (seed_phase if seed_phase is not None else rng.uniform(0, 6.28)))


def loop_rate(dur, approx):
    """Round an LFO rate so that it completes whole cycles within the loop."""
    return max(1, round(approx * dur)) / dur


# --------------------------------------------------------------------------- ambience
def amb_sea(dur=32.0):
    n = int(dur * SR)
    base = lowpass(noise(dur), 500, 1) * 0.6 + bandpass(noise(dur), 300, 2500) * 0.25
    swell = np.zeros(n)
    for r, a in [(loop_rate(dur, 0.09), 0.5), (loop_rate(dur, 0.14), 0.3), (loop_rate(dur, 0.23), 0.2)]:
        swell += a * (slow_lfo(n, r) * 0.5 + 0.5)
    swell = swell ** 2.2
    crash = bandpass(noise(dur), 800, 6000) * np.clip(slow_lfo(n, loop_rate(dur, 0.11)) * 2 - 1.2, 0, 1) ** 2 * 0.5
    rumble = lowpass(noise(dur), 70, 2) * 2.0
    return base * (0.25 + swell) + crash + rumble


def amb_wind(dur=30.0):
    n = int(dur * SR)
    gust = (slow_lfo(n, loop_rate(dur, 0.07)) * 0.5 + 0.5) * 0.6 + (slow_lfo(n, loop_rate(dur, 0.19)) * 0.5 + 0.5) * 0.4
    body = bandpass(noise(dur), 150, 900) * (0.3 + gust)
    # whistle through cables: narrow resonances
    whistle = np.zeros(n)
    for fc in [612, 845, 1190]:
        whistle += bandpass(noise(dur), fc * 0.985, fc * 1.015, 3) * np.clip(gust - 0.55, 0, 1) * 3
    return body + whistle * 0.6


def amb_interior(dur=24.0):
    n = int(dur * SR)
    tone = lowpass(noise(dur), 120, 2) * 1.5 + bandpass(noise(dur), 200, 600) * 0.08
    out = tone
    # sparse creaks of wood settling (positioned so the loop stays seamless)
    for at in [3.1, 9.7, 15.2, 21.0]:
        f = rng.uniform(300, 700)
        t = t_axis(rng.uniform(0.25, 0.5))
        sweep = np.sin(2 * np.pi * np.cumsum(f * (1 + 0.15 * np.sin(t * 9))) / SR)
        grit = (rng.random(len(t)) < 0.02) * 1.0
        c = bandpass(sweep * (0.5 + grit) * np.hanning(len(t)), 200, 2000) * 0.25
        buf = np.zeros(n)
        place(buf, c, at)
        out = out + buf
    return out


def drip(freq):
    d = 0.25
    t = t_axis(d)
    f = freq * (1 + 1.5 * np.exp(-t * 60))
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 25)


def amb_cave(dur=30.0):
    n = int(dur * SR)
    rumble = lowpass(noise(dur), 60, 2) * 2.0 + bandpass(noise(dur), 80, 300) * 0.2
    lap = bandpass(noise(dur), 200, 1200) * (slow_lfo(n, loop_rate(dur, 0.3)) * 0.5 + 0.5) ** 3 * 0.25
    drips = np.zeros(n)
    for at in np.sort(rng.uniform(0.5, dur - 1, 22)):
        place(drips, drip(rng.uniform(900, 2200)) * rng.uniform(0.2, 0.6), at)
    drips = reverb(drips, 2.5, 0.6)[:n]
    return rumble + lap + drips * 0.6


def amb_drone(dur=24.0):
    t = t_axis(dur)
    n = len(t)
    f1, f2 = loop_rate(dur, 41.0), loop_rate(dur, 41.0) + 2 / dur * 3
    x = np.sin(2 * np.pi * f1 * t) + 0.8 * np.sin(2 * np.pi * f2 * t) + 0.3 * np.sin(2 * np.pi * loop_rate(dur, 61.5) * t)
    x *= 0.6 + 0.4 * (slow_lfo(n, loop_rate(dur, 0.05)) * 0.5 + 0.5)
    air = bandpass(noise(dur), 1000, 3000) * 0.02 * (slow_lfo(n, loop_rate(dur, 0.08)) * 0.5 + 0.5)
    return x + air


def tone(freq, dur, buzz=0.25):
    t = t_axis(dur)
    x = np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(2 * np.pi * freq * 2 * t) + 0.15 * np.sin(2 * np.pi * freq * 3.01 * t)
    hum = np.sign(np.sin(2 * np.pi * 60 * t)) * buzz * 0.2
    e = np.minimum(t / 0.03, 1) * np.exp(-t / (dur * 0.6))
    return (x + hum) * e


def amb_signal(dur=8.0):
    """The repeating pattern the lighthouse transmits all game: the relay motif."""
    n = int(dur * SR)
    out = np.zeros(n)
    for i, idx in enumerate(SEQUENCE):
        place(out, tone(RELAY_FREQS[idx], 0.7, 0.1) * 0.6, 0.5 + i * 0.9)
    carrier = np.sin(2 * np.pi * loop_rate(dur, 1200) * t_axis(dur)) * 0.03 * (slow_lfo(n, loop_rate(dur, 2)) > 0.6)
    out = reverb(out, 1.5, 0.5)[:n] + carrier + bandpass(noise(dur), 2000, 5000) * 0.02
    return out


def amb_generator(dur=4.0):
    t = t_axis(dur)
    f = loop_rate(dur, 30)
    x = np.sign(np.sin(2 * np.pi * f * t)) * 0.3 + np.sin(2 * np.pi * f * 2 * t) * 0.5
    x = lowpass(x, 400) + bandpass(noise(dur), 100, 800) * 0.3 * (np.sin(2 * np.pi * f * t) > 0.5)
    return x


def amb_static(dur=4.0):
    n = int(dur * SR)
    x = bandpass(noise(dur), 400, 5000)
    crackle = (rng.random(n) < 0.002) * rng.standard_normal(n) * 6
    whine = np.sin(2 * np.pi * loop_rate(dur, 2400) * t_axis(dur)) * 0.08 * (slow_lfo(n, loop_rate(dur, 0.5)) * 0.5 + 0.5)
    return x + highpass(crackle, 1000) + whine


def listener_strings(dur=4.0):
    """Wet strings vibrating - the Listener's close-range presence."""
    t = t_axis(dur)
    n = len(t)
    out = np.zeros(n)
    for f in [55.0, 82.4, 98.0, 123.5, 146.8]:
        fr = loop_rate(dur, f)
        vib = 1 + 0.01 * slow_lfo(n, loop_rate(dur, rng.uniform(4, 7)))
        ph = 2 * np.pi * np.cumsum(fr * vib) / SR
        saw = (ph / (2 * np.pi)) % 1.0 * 2 - 1
        out += saw * (0.5 + 0.5 * slow_lfo(n, loop_rate(dur, rng.uniform(0.5, 1.5))))
    out = bandpass(out, 60, 1800)
    wet = bandpass(noise(dur), 1500, 4000) * (slow_lfo(n, loop_rate(dur, 3)) > 0.7) * 0.4
    return out + wet


def amb_tape(dur=3.0):
    n = int(dur * SR)
    hiss = highpass(noise(dur), 3000) * 0.4
    wow = lowpass(noise(dur), 200) * 0.5 * (slow_lfo(n, loop_rate(dur, 1.33)) * 0.5 + 0.5)
    return hiss + wow


# --------------------------------------------------------------------------- one-shots
def step(surface, seed):
    global rng
    rng = np.random.default_rng(seed)
    d = 0.35
    n = int(d * SR)
    t = t_axis(d)
    if surface == "wood":
        x = modes([95, 180, 420, 660], [0.05, 0.04, 0.03, 0.02], [1, 0.5, 0.25, 0.15], d, 0.1)
        x += lowpass(noise(d), 1500) * env_ad(n, 0.002, 0.02) * 0.6
        if rng.random() < 0.5:  # creak
            c = np.sin(2 * np.pi * np.cumsum(np.full(n, rng.uniform(500, 800)) * (1 + 0.1 * t)) / SR)
            x += bandpass(c * env_ad(n, 0.04, 0.06) * (rng.random(n) < 0.15), 300, 2000) * 0.4
    elif surface == "stone":
        x = highpass(noise(d), 1500) * env_ad(n, 0.001, 0.012) + lowpass(noise(d), 300) * env_ad(n, 0.002, 0.03) * 0.8
        x += bandpass(noise(d), 2000, 6000) * env_ad(n, 0.03, 0.03) * 0.15
    elif surface == "gravel":
        x = np.zeros(n)
        for _ in range(40):
            at = abs(rng.normal(0.04, 0.035))
            g = highpass(noise(0.01), 2000) * np.exp(-t_axis(0.01) * 400) * rng.uniform(0.2, 1)
            place(x, g, at)
        x += lowpass(noise(d), 250) * env_ad(n, 0.003, 0.03) * 0.8
    elif surface == "water":
        x = bandpass(noise(d), 600, 4000) * env_ad(n, 0.01, 0.08)
        for _ in range(6):
            place(x, drip(rng.uniform(600, 1500)) * 0.3, rng.uniform(0.02, 0.2))
        x += lowpass(noise(d), 200) * env_ad(n, 0.005, 0.05)
    elif surface == "metal":
        x = modes([210, 480, 870, 1430, 2210], [0.25, 0.18, 0.12, 0.08, 0.05], [1, 0.6, 0.4, 0.3, 0.2], d, 0.05)
        x = x * 0.4 + highpass(noise(d), 1000) * env_ad(n, 0.001, 0.01) * 0.6
    else:  # grass
        x = bandpass(noise(d), 800, 5000) * env_ad(n, 0.02, 0.05) * 0.5 + lowpass(noise(d), 250) * env_ad(n, 0.003, 0.03) * 0.6
    return fade(x)


def listener_step(seed):
    global rng
    rng = np.random.default_rng(seed)
    d = 1.6
    n = int(d * SR)
    x = modes([48, 71, 103, 155, 233], [0.6, 0.5, 0.4, 0.3, 0.2], [1, 0.8, 0.6, 0.4, 0.2], d, 0.06)
    x *= env_ad(n, 0.005, 0.5)
    x += lowpass(noise(d), 150) * env_ad(n, 0.002, 0.05) * 1.5
    return fade(reverb(x, 1.4, 0.55), 0.002, 0.2)


def creak(dur, base, seed):
    global rng
    rng = np.random.default_rng(seed)
    n = int(dur * SR)
    t = t_axis(dur)
    f = base * (1 + 0.35 * np.sin(t * 2.3) + 0.05 * lowpass(noise(dur), 10) * 20)
    ph = np.cumsum(f) / SR
    stick = (np.sin(2 * np.pi * ph) > 0.92) * 1.0
    stick = bandpass(stick, 200, 3000) * 3
    body = bandpass(np.sin(2 * np.pi * ph * 2) * 0.3, 150, 2000)
    e = np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 0.5
    return fade(reverb((stick + body) * e, 0.6, 0.3))


def door_slam():
    d = 1.2
    n = int(d * SR)
    x = modes([70, 110, 190, 320], [0.2, 0.15, 0.1, 0.06], [1, 0.7, 0.4, 0.2], d) + lowpass(noise(d), 800) * env_ad(n, 0.001, 0.03) * 2
    return fade(reverb(x, 1.0, 0.4))


def door_locked():
    out = np.zeros(int(0.7 * SR))
    for at in [0.0, 0.12, 0.22, 0.38]:
        r = modes([380, 910, 1600], [0.05, 0.03, 0.02], [1, 0.5, 0.3], 0.15) + highpass(noise(0.15), 2000) * env_ad(int(0.15 * SR), 0.001, 0.01)
        place(out, r * rng.uniform(0.6, 1), at)
    return fade(out)


def bell(base=220.0, dur=7.0):
    ratios = [0.5, 1.0, 1.183, 1.506, 2.0, 2.514, 2.662, 3.011, 4.166]
    amps = [0.5, 1.0, 0.8, 0.6, 0.5, 0.3, 0.25, 0.2, 0.1]
    taus = [3.5, 2.5, 2.0, 1.6, 1.2, 0.9, 0.8, 0.6, 0.4]
    x = modes([base * r for r in ratios], taus, amps, dur, 0.002)
    x += highpass(noise(dur), 2000) * env_ad(int(dur * SR), 0.001, 0.01) * 0.5
    return fade(reverb(x, 3.0, 0.4), 0.001, 0.5)


def drowned_bell():
    x = bell(310, 6.0)
    return fade(lowpass(x, 900) + bandpass(noise(len(x) / SR), 300, 1500) * 0.02, 0.001, 0.5)


def knock3():
    out = np.zeros(int(2.4 * SR))
    for at in [0.0, 0.42, 0.84]:
        k = modes([85, 150, 260], [0.08, 0.05, 0.03], [1, 0.6, 0.3], 0.3) + lowpass(noise(0.3), 600) * env_ad(int(0.3 * SR), 0.001, 0.015) * 1.5
        place(out, k, at)
    return fade(reverb(out, 1.2, 0.45), 0.001, 0.3)


def metal_knock():
    x = modes([310, 742, 1188, 1730, 2650], [0.9, 0.6, 0.4, 0.3, 0.15], [1, 0.7, 0.5, 0.35, 0.2], 2.5, 0.01)
    x += highpass(noise(2.5), 1500) * env_ad(int(2.5 * SR), 0.001, 0.005) * 0.8
    out = np.zeros(int(3.2 * SR))
    place(out, x, 0)
    place(out, x * 0.7, 0.55)
    return fade(reverb(out, 1.5, 0.4), 0.001, 0.3)


def relay(idx):
    x = tone(RELAY_FREQS[idx], 1.1, 0.3)
    clack = modes([900, 1700], [0.02, 0.01], [1, 0.5], 0.1) + highpass(noise(0.1), 1500) * env_ad(int(0.1 * SR), 0.001, 0.005)
    out = pad(clack, 1.3)
    place(out, x * 0.8, 0.05)
    return fade(reverb(out, 0.8, 0.25))


def relay_wrong():
    d = 1.5
    t = t_axis(d)
    f = 300 * np.exp(-t * 1.2)
    x = np.sign(np.sin(2 * np.pi * np.cumsum(f) / SR)) * np.exp(-t * 1.5)
    return fade(lowpass(x, 1500) * 0.7 + bandpass(noise(d), 500, 3000) * np.exp(-t * 3) * 0.4)


def power_down():
    d = 2.5
    t = t_axis(d)
    f = 120 * np.exp(-t * 1.0) + 20
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 0.8)
    pop = lowpass(noise(d), 1000) * env_ad(len(t), 0.001, 0.02) * 2
    return fade(x + pop)


def generator_start():
    d = 4.0
    n = int(d * SR)
    out = np.zeros(n)
    for at in [0.0, 0.7]:  # cord pulls
        c = bandpass(noise(0.5), 300, 3000) * env_ad(int(0.5 * SR), 0.05, 0.15) * 0.6
        place(out, c, at)
    for at in np.arange(1.3, 2.3, 0.12):
        place(out, lowpass(noise(0.1), 400) * env_ad(int(0.1 * SR), 0.002, 0.02) * rng.uniform(0.5, 1.2), at)
    run = amb_generator(1.7)
    run *= np.minimum(t_axis(1.7) / 0.5, 1)
    place(out, run, 2.3)
    return fade(out)


def click(freq=3000, dur=0.06):
    x = modes([freq, freq * 1.7], [0.006, 0.004], [1, 0.4], dur) + highpass(noise(dur), 2000) * env_ad(int(dur * SR), 0.0005, 0.003) * 0.6
    return fade(x, 0.0005, 0.01)


def tape_start():
    d = 0.6
    t = t_axis(d)
    clunk = modes([600, 1300], [0.02, 0.01], [1, 0.4], d) * 0.8
    motor = np.sin(2 * np.pi * np.cumsum(80 + 200 * np.minimum(t / 0.3, 1)) / SR) * 0.15 * np.minimum(t / 0.1, 1)
    return fade(clunk + motor + highpass(noise(d), 3000) * 0.05)


def tape_stop():
    d = 0.4
    t = t_axis(d)
    clunk = modes([500, 1100], [0.02, 0.01], [1, 0.4], d)
    slow = np.sin(2 * np.pi * np.cumsum(280 * np.exp(-t * 8)) / SR) * 0.15
    return fade(clunk + slow)


def radio_burst():
    d = 1.2
    n = int(d * SR)
    t = t_axis(d)
    squelch = np.sin(2 * np.pi * 1800 * t) * env_ad(n, 0.002, 0.05) * 0.4
    st = bandpass(noise(d), 500, 4000) * np.exp(-t * 2) + highpass((rng.random(n) < 0.004) * rng.standard_normal(n) * 5, 800) * np.exp(-t * 1.5)
    return fade(squelch + st)


def splash():
    d = 0.9
    n = int(d * SR)
    x = bandpass(noise(d), 400, 5000) * env_ad(n, 0.005, 0.15)
    for _ in range(14):
        place(x, drip(rng.uniform(500, 1800)) * 0.35, rng.uniform(0.02, 0.6))
    x += lowpass(noise(d), 200) * env_ad(n, 0.003, 0.08) * 1.5
    return fade(reverb(x, 1.0, 0.3))


def paper():
    d = 0.6
    n = int(d * SR)
    x = highpass(noise(d), 1500) * (lowpass(np.abs(noise(d)), 30) * 6) * np.hanning(n)
    return fade(x)


def pickup():
    return fade(modes([700, 1050, 1400], [0.06, 0.05, 0.03], [1, 0.5, 0.3], 0.3) * 0.6 + paper()[:int(0.3 * SR)] * 0.5)


def listener_cry():
    """Detection sting: strings bending downward under huge tension."""
    d = 3.0
    t = t_axis(d)
    n = len(t)
    out = np.zeros(n)
    for f in [110, 147, 196, 233]:
        fr = f * (1 - 0.25 * np.minimum(t / 2, 1)) * (1 + 0.02 * np.sin(2 * np.pi * 6 * t))
        ph = np.cumsum(fr) / SR
        out += ((ph % 1.0) * 2 - 1)
    out = bandpass(out, 80, 2500) * env_ad(n, 0.08, 1.2)
    out += lowpass(noise(d), 80) * env_ad(n, 0.01, 0.8) * 3
    return fade(reverb(out, 2.0, 0.5), 0.01, 0.4)


def death_sting():
    d = 4.0
    t = t_axis(d)
    n = len(t)
    x = listener_cry()[:n] * 0.8
    roar = bandpass(noise(d), 60, 1200) * np.minimum(t / 0.3, 1) * np.exp(-t * 0.6) * 1.5
    sub = np.sin(2 * np.pi * 35 * t) * np.exp(-t * 0.5)
    return fade(x + roar + sub, 0.005, 0.8)


def hatch_open():
    d = 3.0
    t = t_axis(d)
    n = len(t)
    grind = bandpass(noise(d), 100, 1500) * (0.5 + 0.5 * np.sin(2 * np.pi * 7 * t)) * np.minimum(t / 0.2, 1) * (t < 2.2)
    clang = np.zeros(n)
    place(clang, modes([90, 160, 310, 520], [0.6, 0.4, 0.3, 0.2], [1, 0.7, 0.5, 0.3], 0.8), 2.2)
    return fade(reverb(grind * 0.6 + clang, 1.8, 0.45))


def coupling():
    d = 2.0
    x = modes([60, 130, 260, 400], [0.4, 0.3, 0.2, 0.1], [1, 0.6, 0.4, 0.2], d) + lowpass(noise(d), 1000) * env_ad(int(d * SR), 0.001, 0.02) * 2
    hum = np.zeros(int(d * SR))
    place(hum, tone(RELAY_FREQS[0] / 2, 1.5, 0.6) * 0.4, 0.2)
    return fade(reverb(x + hum, 1.8, 0.5))


def transmit_surge():
    d = 6.0
    t = t_axis(d)
    f = 80 * (1 + 6 * (t / d) ** 2)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * (t / d)
    x += sum(np.sin(2 * np.pi * RELAY_FREQS[i] * 2 * t) * 0.3 * (t > 1 + j * 1.0) for j, i in enumerate(SEQUENCE))
    x += bandpass(noise(d), 1000, 6000) * (t / d) ** 2 * 0.6
    return fade(x, 0.05, 0.3)


def overload():
    d = 5.0
    t = t_axis(d)
    n = len(t)
    boom = lowpass(noise(d), 300) * env_ad(n, 0.005, 0.6) * 3 + np.sin(2 * np.pi * 40 * t) * np.exp(-t * 1.2) * 2
    shatter = highpass(noise(d), 2500) * env_ad(n, 0.002, 0.25)
    whine = np.sin(2 * np.pi * np.cumsum(3000 * np.exp(-t * 1.5) + 50) / SR) * np.exp(-t * 0.9) * 0.3
    return fade(reverb(boom + shatter + whine, 3.0, 0.5), 0.002, 1.0)


def heartbeat():
    out = np.zeros(int(1.0 * SR))
    for at, a in [(0.0, 1.0), (0.22, 0.7)]:
        place(out, lowpass(np.sin(2 * np.pi * 50 * t_axis(0.15)) * np.exp(-t_axis(0.15) * 30), 150) * a, at)
    return fade(out)


def flashlight_click():
    return click(2200, 0.05)


# ---- formant "voice" (deliberately unintelligible; subtitles carry the words)
VOWELS = {"a": (730, 1090, 2440), "e": (530, 1840, 2480), "i": (390, 1990, 2550),
          "o": (570, 840, 2410), "u": (440, 1020, 2240), "@": (500, 1500, 2500)}


def voice(dur, f0=112, seed=0, breathy=0.3):
    global rng
    rng = np.random.default_rng(seed)
    n = int(dur * SR)
    t = t_axis(dur)
    pitch = f0 * (1 + 0.08 * np.sin(2 * np.pi * 0.7 * t) + 0.02 * lowpass(noise(dur), 8) * 10)
    ph = np.cumsum(pitch) / SR
    src = ((ph % 1.0) < 0.12) * 1.0 - 0.12
    src += noise(dur) * breathy * 0.3
    # syllable envelope: voiced bursts with gaps
    env = np.zeros(n)
    pos = 0.05
    while pos < dur - 0.2:
        L = rng.uniform(0.12, 0.3)
        seg = int(L * SR)
        i = int(pos * SR)
        env[i:i + seg] = np.hanning(seg)[:len(env[i:i + seg])]
        pos += L + (rng.uniform(0.25, 0.5) if rng.random() < 0.18 else rng.uniform(0.0, 0.05))
    hop = int(0.04 * SR)
    win = np.hanning(hop * 2)
    out = np.zeros(n + hop * 2)
    keys = list(VOWELS)
    cur = VOWELS[rng.choice(keys)]
    f = np.fft.rfftfreq(hop * 2, 1 / SR)
    for k in range(0, n - hop * 2, hop):
        if rng.random() < 0.25:
            cur = VOWELS[rng.choice(keys)]
        frame = src[k:k + hop * 2] * win
        g = sum(np.exp(-((f - fc) / (60 + i * 40)) ** 2) * (1.0 / (i + 1)) for i, fc in enumerate(cur))
        out[k:k + hop * 2] += np.fft.irfft(np.fft.rfft(frame) * g, hop * 2)
    out = out[:n] * env
    return out


def radio_voice(dur, f0, seed):
    v = bandpass(voice(dur, f0, seed), 300, 3000, 2)
    v = np.tanh(v / (np.max(np.abs(v)) + 1e-9) * 3)
    return v + bandpass(noise(dur), 500, 4000) * 0.12


def whisper(dur, seed):
    global rng
    rng = np.random.default_rng(seed)
    v = voice(dur, 100, seed, breathy=3.0)
    return highpass(v, 900) + highpass(noise(dur), 3000) * 0.02


def footsteps_echo(count=5, surface="wood", spacing=0.55, voice_under=False, seed=50):
    out = np.zeros(int((count * spacing + 1.5) * SR))
    for i in range(count):
        place(out, step(surface, seed + i), 0.2 + i * spacing)
    out = reverb(out, 1.6, 0.45)
    if voice_under:
        v = whisper(len(out) / SR - 0.3, seed + 99) * 0.35
        place(out, v, 0.15)
    return fade(out, 0.002, 0.3)


def calibration_tape():
    """What Listen mode reveals inside the station tape: the player's own future
    footsteps walking between the relays, and the relay tones in the right order."""
    dur = 10.0
    out = np.zeros(int(dur * SR))
    tpos = 0.4
    for idx in SEQUENCE:
        for k in range(3):
            place(out, step("metal", 300 + int(tpos * 10) + k) * 0.45, tpos + k * 0.5)
        tpos += 1.6
        place(out, relay(idx) * 0.9, tpos)
        tpos += 0.7
    out = reverb(out, 1.2, 0.4)[:len(out)]
    return fade(lowpass(out, 3500) + highpass(noise(dur), 3000) * 0.03)


def flashlight_echo():
    out = np.zeros(int(1.5 * SR))
    place(out, flashlight_click(), 0.1)
    return fade(reverb(out, 1.4, 0.7))


if __name__ == "__main__":
    write("amb_sea", amb_sea(), 0.8)
    write("amb_wind", amb_wind(), 0.7)
    write("amb_interior", amb_interior(), 0.6)
    write("amb_cave", amb_cave(), 0.7)
    write("amb_drone", amb_drone(), 0.6)
    write("amb_signal", amb_signal(), 0.7)
    write("amb_generator", amb_generator(), 0.6)
    write("amb_static", amb_static(), 0.5)
    write("amb_tape", amb_tape(), 0.4)
    write("listener_strings", listener_strings(), 0.7)
    for s in ["wood", "stone", "gravel", "water", "metal", "grass"]:
        for i in range(4):
            write(f"step_{s}_{i}", step(s, 1000 + 37 * ["wood", "stone", "gravel", "water", "metal", "grass"].index(s) + i), 0.8)
    for i in range(3):
        write(f"listener_step_{i}", listener_step(900 + i), 0.9)
    write("door_creak_0", creak(1.4, 6.0, 1), 0.7)
    write("door_creak_1", creak(1.0, 9.0, 2), 0.7)
    write("door_slam", door_slam(), 0.9)
    write("door_locked", door_locked(), 0.7)
    write("bell", bell(), 0.9)
    write("bell_drowned", drowned_bell(), 0.9)
    write("knock3", knock3(), 0.9)
    write("metal_knock", metal_knock(), 0.9)
    for i in range(3):
        write(f"relay_{i}", relay(i), 0.8)
    write("relay_wrong", relay_wrong(), 0.8)
    write("power_down", power_down(), 0.8)
    write("generator_start", generator_start(), 0.8)
    write("ui_click", click(1800, 0.05), 0.4)
    write("rec_button", click(3200, 0.05), 0.5)
    write("tape_start", tape_start(), 0.6)
    write("tape_stop", tape_stop(), 0.6)
    write("flashlight", flashlight_click(), 0.6)
    write("flashlight_echo", flashlight_echo(), 0.7)
    write("radio_burst", radio_burst(), 0.7)
    write("splash", splash(), 0.8)
    write("paper", paper(), 0.5)
    write("pickup", pickup(), 0.6)
    write("listener_cry", listener_cry(), 0.9)
    write("death_sting", death_sting(), 1.0)
    write("hatch_open", hatch_open(), 0.9)
    write("coupling", coupling(), 0.9)
    write("transmit_surge", transmit_surge(), 0.9)
    write("overload", overload(), 1.0)
    write("heartbeat", heartbeat(), 0.8)
    write("calibration_tape", calibration_tape(), 0.8)
    write("echo_footsteps_dock", footsteps_echo(4, "wood", 0.6, False, 60), 0.8)
    write("echo_footsteps_voice", footsteps_echo(5, "wood", 0.6, True, 60), 0.8)
    write("echo_footsteps_stone", footsteps_echo(6, "stone", 0.5, False, 70), 0.8)
    write("echo_running", footsteps_echo(9, "gravel", 0.28, False, 80), 0.8)
    write("radio_voice_a", radio_voice(4.0, 118, 11), 0.6)
    write("radio_voice_b", radio_voice(4.0, 170, 12), 0.6)
    write("radio_voice_c", radio_voice(5.0, 105, 13), 0.6)
    write("radio_voice_elias", radio_voice(3.5, 98, 14), 0.6)
    write("whisper_0", whisper(3.0, 21), 0.5)
    write("whisper_1", whisper(4.0, 22), 0.5)
