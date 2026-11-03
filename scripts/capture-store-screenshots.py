#!/usr/bin/env python
"""Capture Play/App Store screenshots of Color Rush without a device.

A real device or emulator is still the best source. This exists for the case
where neither is available (no hardware acceleration, no phone): it builds the
app for the web into a throwaway copy, drives it in headless Chrome at a
1080x1920 phone viewport over the DevTools protocol, plays a real run, and
writes store-ready PNGs.

    pip install websockets pillow
    python scripts/capture-store-screenshots.py            # en + ko, 4 shots each

Output: store/assets/screenshots/<locale>-{1-home,2-play,3-gameover,4-howtoplay}.png
        1080x1920 (9:16), 24-bit PNG - within Play and App Store limits.

Nothing in app/ is modified: the web platform files are generated in a copy
under the system temp directory and deleted afterwards.
"""
from __future__ import annotations

import argparse
import asyncio
import base64
import functools
import io
import json
import os
import shutil
import subprocess
import sys
import tempfile
import threading
import urllib.request
from collections.abc import Mapping
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

try:
    import websockets
    from PIL import Image
except ImportError as exc:  # pragma: no cover - dependency hint
    raise SystemExit(f"missing dependency: {exc}. Run: pip install websockets pillow")

REPO = Path(__file__).resolve().parent.parent
APP = REPO / "app"

# Logical px; x3 -> 1080x1920, an exact 9:16 Play phone asset. App Store wants
# device sizes instead, e.g. --viewport 430x932 for the 6.7" 1290x2796 slot.
_viewport = (360, 640)
DSF = 3
CLIP_SCALE = 0.34  # the in-game probe must stay well under the ~2s round timer
TARGET_SCORE = 12

COLORS = {
    "red": (0xFF, 0x47, 0x57),
    "blue": (0x3D, 0x9B, 0xFF),
    "green": (0x2E, 0xD5, 0x73),
    "yellow": (0xFF, 0xC0, 0x48),
    "purple": (0xA5, 0x5E, 0xEA),
    "orange": (0xFF, 0x7F, 0x50),
}
WORDS = {
    "en": {"RED": "red", "BLUE": "blue", "GREEN": "green", "YELLOW": "yellow",
           "PURPLE": "purple", "ORANGE": "orange"},
    "ko": {"빨강": "red", "파랑": "blue", "초록": "green", "노랑": "yellow",
           "보라": "purple", "주황": "orange"},
}
TEXT = {
    "en": {"play": "PLAY", "over": "GAME OVER", "newbest": "NEW BEST!", "ok": "OK",
           "help": "How to play", "start": "TAP TO START", "match": "MATCH",
           "nomatch": "NO MATCH"},
    "ko": {"play": "시작하기", "over": "게임 오버", "newbest": "신기록!", "ok": "확인",
           "help": "게임 방법", "start": "탭해서 시작", "match": "일치",
           "nomatch": "불일치"},
}
ACCEPT_LANGUAGE = {"en": "en-US", "ko": "ko-KR"}



CHROME_CANDIDATES = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
]


def log(msg: str) -> None:
    print(msg, flush=True)


def run(cmd: list[str], cwd: Path) -> None:
    proc = subprocess.run(cmd, cwd=cwd, shell=os.name == "nt",
                          capture_output=True, text=True, encoding="utf-8",
                          errors="replace")
    if proc.returncode != 0:
        sys.stdout.write(proc.stdout or "")
        sys.stderr.write(proc.stderr or "")
        raise SystemExit(f"command failed ({proc.returncode}): {' '.join(cmd)}")


def build_web(workdir: Path) -> Path:
    log(f"copying app/ -> {workdir}")
    shutil.copytree(APP, workdir, ignore=shutil.ignore_patterns(
        "build", ".dart_tool", "tool", ".git"))
    log("flutter create --platforms=web")
    run(["flutter", "create", "--platforms=web", "."], workdir)
    run(["flutter", "pub", "get"], workdir)
    log("flutter build web --release (this takes a couple of minutes)")
    run(["flutter", "build", "web", "--release"], workdir)
    return workdir / "build" / "web"


def serve(directory: Path, port: int) -> ThreadingHTTPServer:
    handler = functools.partial(QuietHandler, directory=str(directory))
    httpd = ThreadingHTTPServer(("127.0.0.1", port), handler)
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    log(f"serving {directory} on http://127.0.0.1:{port}")
    return httpd


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, format: str, *args: object) -> None:  # noqa: A002
        pass


def launch_chrome(cdp_port: int, profile: Path) -> subprocess.Popen[bytes]:
    binary = next((c for c in CHROME_CANDIDATES if Path(c).exists()), None)
    if binary is None:
        raise SystemExit("Chrome not found; set one of CHROME_CANDIDATES")
    proc = subprocess.Popen([
        binary, "--headless=new", f"--remote-debugging-port={cdp_port}",
        f"--user-data-dir={profile}", "--hide-scrollbars", "--no-first-run",
        "--no-default-browser-check", "--disable-extensions", "about:blank",
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(60):
        try:
            urllib.request.urlopen(f"http://127.0.0.1:{cdp_port}/json/version", timeout=1)
            return proc
        except Exception:
            threading.Event().wait(0.5)
    proc.kill()
    raise SystemExit("headless Chrome did not expose a DevTools endpoint")


def cdp_endpoints(cdp_port: int) -> tuple[str, str]:
    version = json.load(urllib.request.urlopen(f"http://127.0.0.1:{cdp_port}/json/version"))
    targets = json.load(urllib.request.urlopen(f"http://127.0.0.1:{cdp_port}/json/list"))
    page = next(t for t in targets if t["type"] == "page" and "devtools" not in t["url"])
    return page["webSocketDebuggerUrl"], version["User-Agent"]


class Session:
    """Minimal CDP client: request/response plus the few input helpers needed."""

    def __init__(self, ws) -> None:
        self.ws = ws
        self.seq = 0

    async def send(self, method: str, **params):
        self.seq += 1
        mine = self.seq
        await self.ws.send(json.dumps({"id": mine, "method": method, "params": params}))
        while True:
            message = json.loads(await self.ws.recv())
            if message.get("id") == mine:
                if "error" in message:
                    raise RuntimeError(f"{method}: {message['error']}")
                return message.get("result", {})

    async def tap(self, point: tuple[int, int]) -> None:
        x, y = point
        for kind in ("mousePressed", "mouseReleased"):
            await self.send("Input.dispatchMouseEvent", type=kind, x=x, y=y,
                            button="left", clickCount=1,
                            buttons=1 if kind == "mousePressed" else 0)

    async def shot(self, path: Path | None = None,
                   clip: Mapping[str, float] | None = None) -> Image.Image:
        args: dict[str, object] = {"format": "png"}
        if clip:
            args["clip"] = {**clip, "scale": CLIP_SCALE}
        raw = base64.b64decode((await self.send("Page.captureScreenshot", **args))["data"])
        if path:
            path.write_bytes(raw)
            log(f"  wrote {path.name}")
        return Image.open(io.BytesIO(raw)).convert("RGB")

    async def js(self, expression: str):
        result = await self.send("Runtime.evaluate", expression=expression,
                                 returnByValue=True)
        return result.get("result", {}).get("value")

    async def labels(self) -> list[str]:
        raw = await self.js(
            "JSON.stringify([...document.querySelectorAll('flt-semantics')]"
            ".map(e=>e.getAttribute('aria-label')||e.textContent).filter(Boolean))")
        return json.loads(raw or "[]")

    async def rect(self, label: str) -> dict[str, float] | None:
        """Bounding box of the semantics node whose label is exactly `label`.

        Everything is located this way instead of by fixed coordinates, so the
        same script works at any viewport size.
        """
        raw = await self.js(
            "(()=>{const e=[...document.querySelectorAll('flt-semantics')]"
            ".find(e=>(e.getAttribute('aria-label')||e.textContent)==="
            f"{json.dumps(label)});"
            "if(!e)return null;const r=e.getBoundingClientRect();"
            "return JSON.stringify({x:r.x,y:r.y,width:r.width,height:r.height});})()")
        return json.loads(raw) if raw else None

    async def tap_label(self, label: str) -> None:
        box = await self.rect(label)
        if box is None:
            raise SystemExit(f"could not find a tappable {label!r} on screen")
        await self.tap((int(box["x"] + box["width"] / 2),
                        int(box["y"] + box["height"] / 2)))


def dominant_color(img: Image.Image) -> str | None:
    """Name of the game color covering most of the saturated pixels."""
    counts: dict[str, int] = {}
    raw = img.tobytes()
    for i in range(0, len(raw) - 2, 3):
        pixel = (raw[i], raw[i + 1], raw[i + 2])
        if max(pixel) - min(pixel) < 45:  # background and grey chrome
            continue
        name = min(COLORS, key=lambda key: sum(
            (a - b) ** 2 for a, b in zip(COLORS[key], pixel)))
        counts[name] = counts.get(name, 0) + 1
    if not counts:
        return None
    return max(counts, key=lambda k: counts[k])


async def read_round(page: Session, words: dict[str, str]) -> tuple[str, str] | None:
    """Current round as (word meaning, ink color), read from the live screen."""
    found = await page.labels()
    word = next((label for label in found if label in words), None)
    if word is None:
        return None
    box = await page.rect(word)
    if box is None:
        return None
    clip = {"x": box["x"], "y": box["y"], "width": box["width"], "height": box["height"]}
    ink = dominant_color(await page.shot(clip=clip))
    return (words[word], ink) if ink else None


async def capture(locale: str, url: str, out_dir: Path, ws_url: str, user_agent: str,
                  prefix: str = "") -> None:
    words, text = WORDS[locale], TEXT[locale]
    async with websockets.connect(ws_url, max_size=None) as ws:
        page = Session(ws)
        await page.send("Page.enable")
        await page.send("Runtime.enable")
        await page.send("Network.enable")
        await page.send("Network.setBypassServiceWorker", bypass=True)
        await page.send("Emulation.setDeviceMetricsOverride",
                        width=_viewport[0], height=_viewport[1],
                        deviceScaleFactor=DSF, mobile=True)
        # Locale comes from navigator.language; plain tags only - Flutter web
        # rejects q-values with "Incorrect locale information provided".
        await page.send("Emulation.setUserAgentOverride", userAgent=user_agent,
                        acceptLanguage=ACCEPT_LANGUAGE[locale])
        # shared_preferences(web) lives in localStorage; seed a best score before
        # the app boots so the shots do not advertise an empty profile.
        await page.send("Page.addScriptToEvaluateOnNewDocument", source=(
            "try{window.localStorage.setItem('flutter.high_score','37');"
            "window.localStorage.setItem('flutter.haptics_on','true');}catch(e){}"))
        await page.send("Page.navigate", url=url)
        await asyncio.sleep(10)
        # Flutter web only builds a DOM semantics tree once accessibility is on;
        # the game round is read from it.
        await page.js("document.querySelector('flt-semantics-placeholder')?.click()")
        await asyncio.sleep(1.2)

        found = await page.labels()
        if not any(text["play"] in label for label in found):
            raise SystemExit(f"{locale}: home screen never appeared: {found[:4]}")
        await page.shot(out_dir / f"{prefix}{locale}-1-home.png")

        await page.tap_label(text["help"])
        # CanvasKit fetches fallback glyphs (some Hangul syllables) lazily.
        await asyncio.sleep(4)
        await page.shot(out_dir / f"{prefix}{locale}-4-howtoplay.png")
        await page.tap_label(text["ok"])
        await asyncio.sleep(1)

        await page.tap_label(text["play"])
        await asyncio.sleep(1.2)
        await page.tap_label(text["start"])
        await asyncio.sleep(0.35)

        score = 0
        for _ in range(TARGET_SCORE * 3):
            if score >= TARGET_SCORE:
                break
            found = await page.labels()
            if any(text["over"] in l or text["newbest"] in l for l in found):
                log(f"  {locale}: run ended early at {score}")
                break
            round_state = await read_round(page, words)
            if round_state is None:
                await asyncio.sleep(0.2)
                continue
            word, ink = round_state
            await page.tap_label(text["match"] if word == ink else text["nomatch"])
            score += 1
            await asyncio.sleep(0.1)

        # A mismatch round (word meaning != ink color) shows the Stroop twist,
        # so keep playing correctly until one is on screen.
        for _ in range(8):
            round_state = await read_round(page, words)
            if round_state is None or round_state[0] != round_state[1]:
                break
            await page.tap_label(text["match"])
            score += 1
            await asyncio.sleep(0.1)

        await asyncio.sleep(0.45)
        await page.shot(out_dir / f"{prefix}{locale}-2-play.png")
        log(f"  {locale}: answered {score} rounds correctly")

        round_state = await read_round(page, words)
        if round_state is None:
            await asyncio.sleep(2.5)  # no readable round: let the timer run out
        else:
            word, ink = round_state  # answer wrong on purpose
            await page.tap_label(text["nomatch"] if word == ink else text["match"])
        await asyncio.sleep(1.2)
        found = await page.labels()
        if not any(text["over"] in l or text["newbest"] in l for l in found):
            raise SystemExit(f"{locale}: game over screen never appeared: {found[:6]}")
        await page.shot(out_dir / f"{prefix}{locale}-3-gameover.png")


def verify(out_dir: Path, locales: list[str], prefix: str) -> None:
    expected = [f"{prefix}{loc}-{name}.png" for loc in locales
                for name in ("1-home", "2-play", "3-gameover", "4-howtoplay")]
    for name in expected:
        path = out_dir / name
        with Image.open(path) as img:
            if img.size != (_viewport[0] * DSF, _viewport[1] * DSF):
                raise SystemExit(f"{name}: unexpected size {img.size}")
        if path.stat().st_size > 8 * 1024 * 1024:
            raise SystemExit(f"{name}: over the 8MB store limit")
    log(f"verified {len(expected)} screenshots in {out_dir}")


async def main_async(args: argparse.Namespace) -> None:
    global _viewport
    _viewport = args.viewport
    out_dir = (REPO / args.out).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    workdir = Path(tempfile.mkdtemp(prefix="colorrush-web-"))
    profile = Path(tempfile.mkdtemp(prefix="colorrush-chrome-"))
    httpd: ThreadingHTTPServer | None = None
    chrome: subprocess.Popen[bytes] | None = None
    try:
        web_root = build_web(workdir / "app")
        httpd = serve(web_root, args.port)
        chrome = launch_chrome(args.cdp_port, profile)
        ws_url, user_agent = cdp_endpoints(args.cdp_port)
        for locale in args.locales:
            log(f"capturing {locale}")
            await capture(locale, f"http://127.0.0.1:{args.port}/index.html",
                          out_dir, ws_url, user_agent, args.prefix)
        verify(out_dir, args.locales, args.prefix)
    finally:
        if httpd:
            httpd.shutdown()
        if chrome:
            chrome.kill()
        if args.keep:
            log(f"kept {workdir}")
        else:
            shutil.rmtree(workdir, ignore_errors=True)
        shutil.rmtree(profile, ignore_errors=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--locales", default="en,ko",
                        help="comma separated locales to capture (en, ko)")
    parser.add_argument("--out", default="store/assets/screenshots",
                        help="output directory, relative to the repo root")
    parser.add_argument("--port", type=int, default=8321, help="local web server port")
    parser.add_argument("--cdp-port", type=int, default=9333,
                        help="Chrome DevTools port (must be free)")
    parser.add_argument("--viewport", default="360x640",
                        help="logical viewport; x3 is the output size "
                             "(360x640 -> 1080x1920 for Play, "
                             "430x932 -> 1290x2796 for the App Store 6.7\" slot)")
    parser.add_argument("--prefix", default="",
                        help="file name prefix, e.g. ios67- for App Store sizes")
    parser.add_argument("--keep", action="store_true",
                        help="keep the temporary web build for inspection")
    args = parser.parse_args()
    try:
        width, height = (int(v) for v in args.viewport.lower().split("x"))
    except ValueError:
        raise SystemExit(f"--viewport must look like 360x640, got {args.viewport!r}")
    args.viewport = (width, height)
    args.locales = [l.strip() for l in args.locales.split(",") if l.strip()]
    unknown = [l for l in args.locales if l not in WORDS]
    if unknown:
        raise SystemExit(f"unsupported locale(s): {unknown}")
    asyncio.run(main_async(args))


if __name__ == "__main__":
    main()
