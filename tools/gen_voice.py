#!/usr/bin/env python3
"""Speaks every line in assets/audio/voice/lines.json with Kokoro TTS
(Kokoro-82M, Apache-2.0; kokoro-onnx, MIT) and gives each speaker its own
treatment: radio, tape, whisper, Suha's warm close voice.

Setup (offline once the model files are present):
    python3 -m venv venv && venv/bin/pip install kokoro-onnx soundfile
    model files: kokoro-v1.0.onnx and voices-v1.0.bin from
    https://github.com/thewh1teagle/kokoro-onnx/releases/tag/model-files-v1.0
Run:
    godot --headless --path . --script res://tools/export_lines.gd
    venv/bin/python tools/gen_voice.py /path/to/model-dir
"""
import json
import os
import re
import sys

import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "assets", "audio", "voice")
SR = 24000
rng = np.random.default_rng(3)

# speaker -> (kokoro voice or blend, language, speed, treatment)
# Elias's own thoughts are subtitles only (no "ELIAS" entry on purpose).
SUHA_VOICE = {"af_heart": 0.55, "af_nicole": 0.45}   # warm + breathy = dreamy
VOICES = {
    "RADIO — YOUR VOICE": ("bm_george", "en-gb", 0.95, "radio"),
    "TAPE — YOUR VOICE": ("bm_george", "en-gb", 0.92, "tape"),
    "RADIO — VERY QUIET": ("bm_george", "en-gb", 0.85, "whisper"),
    "WHISPER": ("bm_george", "en-gb", 0.8, "whisper"),
    "SUHA": (SUHA_VOICE, "en-us", 0.76, "suha"),
    "RADIO — SUHA": (SUHA_VOICE, "en-us", 0.78, "suha_radio"),
    "THE ISLAND — IN HER VOICE": ("af_heart", "en-us", 0.78, "island"),
    "RADIO — A WOMAN": ("bf_emma", "en-gb", 0.95, "radio"),
    "VOICES — FROM THE BLUE HOUSE": ("bf_emma", "en-gb", 0.95, "muffled"),
    "RADIO — A MAN": ("bm_lewis", "en-gb", 0.95, "radio"),
    "RADIO": ("am_michael", "en-us", 0.95, "radio"),
    "RADIO — MAINLAND": ("am_michael", "en-us", 0.95, "radio"),
    "TRANSMITTER": ("am_onyx", "en-us", 0.9, "machine"),
    "REC_morrow_tape": ("bm_daniel", "en-gb", 0.9, "tape"),
    "REC_mayday": ("am_eric", "en-us", 1.0, "radio"),
    "REC_kell_tape": ("bm_lewis", "en-gb", 0.82, "tape"),
}


def spoken_text(text):
    """Only the words actually said: drop narration and stage directions."""
    t = text.strip()
    if t.startswith("("):
        return ""
    quoted = re.findall(r'"([^"]+)"', t) or re.findall(r":\s*'(.+)'", t) or re.findall(r"(?<![A-Za-z])'([^']{6,}?)'(?![A-Za-z])", t)
    if quoted:
        t = " ".join(quoted)
    t = re.sub(r"\[[^\]]*\]", "", t)
    t = t.replace("—", ", ").replace("...", "… ").strip(" .")
    return t if re.search(r"[A-Za-z]", t) else ""


def fft_filter(x, lo, hi):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    g = 1 / (1 + (lo / np.maximum(f, 1)) ** 4) / (1 + (f / hi) ** 4)
    return np.fft.irfft(X * g, len(x))


def reverb(x, size, mix):
    n = int(size * SR)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / (n / 5))
    ir = fft_filter(np.concatenate([ir, np.zeros(len(x))]), 200, 4000)[:n]
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    L = len(x) + n
    N2 = 1 << (L - 1).bit_length()
    wet = np.fft.irfft(np.fft.rfft(x, N2) * np.fft.rfft(ir, N2), N2)[:L]
    dry = np.concatenate([x, np.zeros(n)])
    return dry * (1 - mix) + wet * mix * 0.6


def envelope(x, ms=15):
    k = int(SR * ms / 1000)
    return np.convolve(np.abs(x), np.ones(k) / k, mode="same")


def chorus(x, depth_ms=6.0, base_ms=14.0, rate=0.23):
    """Two slowly drifting copies: a soft, floating doubling."""
    t = np.arange(len(x)) / SR
    out = x.copy()
    for ph in (0.0, 2.1):
        d = (base_ms + depth_ms * np.sin(2 * np.pi * rate * t + ph)) * SR / 1000
        out += np.interp(np.arange(len(x)) - d, np.arange(len(x)), x, left=0) * 0.45
    return out / 1.9


def dreamy(x, lo, hi, room, mix):
    y = chorus(fft_filter(x, lo, hi))
    env = envelope(y, 25)
    y = y + fft_filter(rng.standard_normal(len(y)), 2500, 9000) * env * 0.5   # breath
    t = np.arange(len(y)) / SR
    y = y * (0.88 + 0.12 * np.sin(2 * np.pi * 0.31 * t))                       # slow swell
    pre = np.zeros(int(0.03 * SR))
    wet = reverb(np.concatenate([pre, y]), room, 1.0)
    dry = np.concatenate([y, np.zeros(len(wet) - len(y))])
    return dry * (1 - mix) + wet * mix * 1.6


def treat(x, kind):
    if kind == "close":
        return reverb(x, 0.35, 0.08)
    if kind == "radio":
        y = fft_filter(x, 320, 3300)
        y = np.tanh(y / (np.max(np.abs(y)) + 1e-9) * 2.2)
        y += fft_filter(rng.standard_normal(len(y)), 1500, 5000) * 0.03
        return y
    if kind == "tape":
        t = np.arange(len(x)) / SR
        wow = 1 + 0.004 * np.sin(2 * np.pi * 0.7 * t)
        idx = np.clip(np.cumsum(wow) - 1, 0, len(x) - 1)
        y = np.interp(idx, np.arange(len(x)), x)
        y = fft_filter(y, 180, 4800)
        return y + fft_filter(rng.standard_normal(len(y)), 3000, 9000) * 0.012
    if kind == "whisper":
        env = envelope(x)
        breath = fft_filter(rng.standard_normal(len(x)), 1200, 7000) * env * 2.2
        y = fft_filter(x, 900, 7000) * 0.35 + breath
        return reverb(y, 0.6, 0.2)
    if kind == "suha":
        return dreamy(x, 110, 6000, 2.6, 0.42)
    if kind == "suha_radio":
        y = dreamy(x, 220, 4800, 2.0, 0.34)
        return y + fft_filter(rng.standard_normal(len(y)), 2000, 6000) * 0.005
    if kind == "island":
        idx = np.arange(0, len(x), 0.86)
        y = np.interp(idx, np.arange(len(x)), x)
        y = np.tanh(y * 3.0) * 0.5 + y * 0.5
        return reverb(y, 2.4, 0.45)
    if kind == "muffled":
        return reverb(fft_filter(x, 200, 1200), 0.8, 0.3)
    if kind == "machine":
        t = np.arange(len(x)) / SR
        return fft_filter(x * (0.6 + 0.4 * np.sin(2 * np.pi * 45 * t)), 250, 3800)
    return x


def main():
    model_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    k = Kokoro(os.path.join(model_dir, "kokoro-v1.0.onnx"), os.path.join(model_dir, "voices-v1.0.bin"))
    lines = json.load(open(os.path.join(OUT, "lines.json")))
    only = set(sys.argv[2:])
    if only:
        lines = [l for l in lines if l["id"] in only]
    made = 0
    for line in lines:
        text = spoken_text(line["text"])
        spec = VOICES.get(line["speaker"])
        if not text or spec is None:
            continue
        voice, lang, speed, kind = spec
        if isinstance(voice, dict):
            voice = sum(k.get_voice_style(v) * w for v, w in voice.items())
        pause = 0.55 if kind.startswith("suha") else 0.25
        audio, sr = k.create(text, voice=voice, speed=speed, lang=lang, sentence_pause=pause)
        assert sr == SR
        y = treat(np.asarray(audio, dtype=float), kind)
        pad = np.zeros(int(0.12 * SR))
        y = np.concatenate([pad, y, pad])
        y = y / (np.max(np.abs(y)) + 1e-9) * (0.55 if kind in ("whisper", "suha") else 0.8)
        sf.write(os.path.join(OUT, line["id"] + ".wav"), y.astype(np.float32), SR, subtype="PCM_16")
        made += 1
        print("spoke", line["id"], f"{len(y) / SR:.1f}s", text[:50])
    print("total", made)


if __name__ == "__main__":
    main()
