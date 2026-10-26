"""째깍이 목소리를 ElevenLabs로 미리 만들어 assets/voice에 저장한다.

준비: 프로젝트 폴더의 .env.local 에 ELEVENLABS_API_KEY=... (git에 올리지 않음)
실행:
  flutter test tool/voice/export_lines_test.dart   # 문장 목록 갱신
  python3 tool/voice/generate.py                    # 없는 음성만 새로 만든다

파일 이름은 문장 열쇠의 해시라서, 문장이 그대로면 다시 만들지 않는다.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VOICE_DIR = ROOT / "assets" / "voice"
LINES = ROOT / "tool" / "voice" / "lines.json"

VOICE_ID = "k5siOxi4qsPS2kASoRt7"  # Geaun - 동화책 읽어주는 목소리
MODEL_ID = "eleven_multilingual_v2"
# 무손실 PCM으로 받아 음량을 맞춘 뒤 AAC로 저장 (낮은 비트레이트 MP3는 잡음이 컸다)
OUTPUT_FORMAT = "pcm_24000"
SAMPLE_RATE = 24000
AAC_BITRATE = "48k"
VOICE_SETTINGS = {"stability": 0.5, "similarity_boost": 0.8, "style": 0.3}

NATIVE_HOUR = {1: "한", 2: "두", 3: "세", 4: "네", 5: "다섯", 6: "여섯", 7: "일곱",
               8: "여덟", 9: "아홉", 10: "열", 11: "열한", 12: "열두"}
NATIVE_COUNT = {1: "한", 2: "두", 3: "세", 4: "네", 5: "다섯"}
SINO_DIGIT = ["", "일", "이", "삼", "사", "오", "육", "칠", "팔", "구"]


def voice_key(text: str) -> str:
    """앱의 TtsService.voiceKey 와 같은 규칙"""
    return re.sub(r"[^0-9A-Za-z가-힣]", "", text)


def sino(n: int) -> str:
    if n == 0:
        return "영"
    tens, ones = divmod(n, 10)
    out = ""
    if tens:
        out += ("" if tens == 1 else SINO_DIGIT[tens]) + "십"
    return out + SINO_DIGIT[ones]


def speech_text(text: str) -> str:
    """숫자를 아이에게 읽어 주는 말로 바꾸고 이모지를 뺀다"""
    t = re.sub(r"(\d+)시", lambda m: NATIVE_HOUR[int(m[1])] + " 시", text)
    t = re.sub(r"(\d+)분", lambda m: sino(int(m[1])) + " 분", t)
    t = re.sub(r"별 (\d+)개", lambda m: "별 " + NATIVE_COUNT[int(m[1])] + " 개", t)
    t = re.sub(r"\d+", lambda m: sino(int(m[0])), t)
    t = re.sub(r"[^\w\s.,!?~'\"]", "", t)
    return re.sub(r"\s+", " ", t).strip()


def file_name(key: str) -> str:
    return "v_" + hashlib.sha1(key.encode()).hexdigest()[:12] + ".m4a"


def load_api_key() -> str:
    env = ROOT / ".env.local"
    for line in env.read_text().splitlines():
        if line.startswith("ELEVENLABS_API_KEY="):
            return line.split("=", 1)[1].strip()
    sys.exit(".env.local 에 ELEVENLABS_API_KEY 가 없습니다")


def synthesize(api_key: str, text: str, dest: Path) -> None:
    body = json.dumps({
        "text": text, "model_id": MODEL_ID, "voice_settings": VOICE_SETTINGS,
        "language_code": "ko",
    }).encode()
    url = (f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}"
           f"?output_format={OUTPUT_FORMAT}")
    for attempt in range(6):
        req = urllib.request.Request(url, data=body, method="POST", headers={
            "xi-api-key": api_key, "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=60) as res:
                encode(res.read(), dest)
                return
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503):
                time.sleep(2 ** attempt)
                continue
            raise RuntimeError(f"{e.code} {e.read()[:200]!r} :: {text}") from e
    raise RuntimeError(f"too many retries :: {text}")


def encode(pcm: bytes, dest: Path) -> None:
    """PCM → 저역 잡음 제거, 방송 음량(-16 LUFS)으로 맞춤 → AAC(m4a)"""
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
         "-f", "s16le", "-ar", str(SAMPLE_RATE), "-ac", "1", "-i", "pipe:0",
         "-af", "highpass=f=70,loudnorm=I=-16:TP=-1.5:LRA=11",
         "-ar", str(SAMPLE_RATE), "-c:a", "aac", "-b:a", AAC_BITRATE, str(dest)],
        input=pcm, check=True)


def main() -> None:
    api_key = load_api_key()
    lines = json.loads(LINES.read_text())
    VOICE_DIR.mkdir(parents=True, exist_ok=True)

    manifest = {}
    todo = []
    for line in lines:
        key = voice_key(line)
        name = file_name(key)
        manifest[key] = name
        if not (VOICE_DIR / name).exists():
            todo.append((speech_text(line), VOICE_DIR / name))

    print(f"{len(lines)} lines, {len(todo)} to generate, "
          f"{sum(len(t) for t, _ in todo)} chars")
    done = 0
    with ThreadPoolExecutor(max_workers=3) as pool:
        for _ in pool.map(lambda job: synthesize(api_key, *job), todo):
            done += 1
            if done % 50 == 0:
                print(f"  {done}/{len(todo)}", flush=True)

    # 더 이상 쓰지 않는 음성 파일 정리
    keep = set(manifest.values())
    for old in VOICE_DIR.glob("v_*.*"):
        if old.name not in keep:
            old.unlink()

    (VOICE_DIR / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True))
    print("done")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--preview":
        for line in json.loads(LINES.read_text())[:: max(1, int(sys.argv[2]) if len(sys.argv) > 2 else 40)]:
            print(line, "=>", speech_text(line))
    else:
        main()
