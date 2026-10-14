#!/usr/bin/env python3
import json
import os
import re
import subprocess
import sys
import unicodedata
from datetime import datetime
from pathlib import Path

SOURCE_DIR = Path("/mnt/nasdata1/Music/1manu")
DEST_DIR = Path("music/assets")
PLAYLIST_FILE = Path("music/playlist.json")

def get_duration(path: Path) -> str:
    cmd = [
        "ffprobe", "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=nw=1:nk=1",
        str(path)
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    try:
        sec = int(float(res.stdout.strip()))
        return f"{sec // 60}:{sec % 60:02d}"
    except (ValueError, TypeError):
        return "--:--"

MEDIA_EXTENSIONS = {
    ".mp3", ".mp4", ".m4v", ".mkv", ".opus", ".webm",
    ".flac", ".wav", ".aac", ".ogg", ".m4a", ".wma",
}

def parse_track_name(filename: str):
    base = filename
    while True:
        root, ext = os.path.splitext(base)
        if ext.lower() in MEDIA_EXTENSIONS:
            base = root
        else:
            break

    canonical = re.sub(r"\s*\(\d+\)$", "", base).strip()
    if " - " not in canonical:
        return None, None, None

    artist, title = canonical.split(" - ", 1)
    return canonical.lower(), artist.strip(), title.strip()

# Load existing durations cache from playlist.json if present
existing_durations = {}
if PLAYLIST_FILE.exists():
    try:
        with open(PLAYLIST_FILE, "r", encoding="utf-8") as f:
            for item in json.load(f):
                if "src" in item and "duration" in item:
                    existing_durations[item["src"]] = item["duration"]
    except Exception:
        pass

# 1. Discover tracks adhering to contract
songs = {}
for p in SOURCE_DIR.rglob("*"):
    if p.is_file() and not p.name.startswith(".") and p.suffix.lower() in MEDIA_EXTENSIONS:
        canon_key, artist, title = parse_track_name(p.name)
        if not canon_key:
            print(f"Skipped '{p.name}': missing ' - ' (expected 'Artist - Title')", file=sys.stderr)
            continue
        mtime = p.stat().st_mtime
        if canon_key not in songs or mtime > songs[canon_key][0]:
            songs[canon_key] = (mtime, p, artist, title)

# 2. Sort newest first
sorted_songs = sorted(songs.values(), key=lambda x: x[0], reverse=True)

DEST_DIR.mkdir(parents=True, exist_ok=True)
playlist = []

print(f"Total canonical tracks: {len(sorted_songs)}\n")

from concurrent.futures import ThreadPoolExecutor

def process_track(item):
    idx, (mtime, src_path, artist, title) = item
    raw_slug = f"{artist}-{title}".lower().replace(" ", "-")
    ascii_slug = unicodedata.normalize("NFKD", raw_slug).encode("ASCII", "ignore").decode("utf-8")
    slug = re.sub(r"[^\w-]", "", ascii_slug)
    slug = re.sub(r"-+", "-", slug).strip("-")
    out_file = DEST_DIR / f"{slug}.opus"
    rel_src = f"assets/{out_file.name}"

    converted = False
    if not out_file.exists() or out_file.stat().st_mtime < mtime:
        print(f"[{idx:03d}/{len(sorted_songs):03d}] Converting: {artist} - {title}")
        cmd = [
            "ffmpeg", "-y", "-i", str(src_path),
            "-vn", "-c:a", "libopus", "-b:a", "96k", "-vbr", "on",
            str(out_file)
        ]
        res = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        if res.returncode != 0:
            print(f"Failed {src_path.name}: {res.stderr.decode()}", file=sys.stderr)
            return None
        converted = True
    else:
        print(f"[{idx:03d}/{len(sorted_songs):03d}] Cached: {artist} - {title}")

    if not converted and rel_src in existing_durations and existing_durations[rel_src] != "--:--":
        dur_str = existing_durations[rel_src]
    else:
        dur_str = get_duration(out_file)

    date_str = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d")

    return {
        "id": idx,
        "title": title,
        "artist": artist,
        "src": rel_src,
        "date": date_str,
        "duration": dur_str,
    }

with ThreadPoolExecutor(max_workers=os.cpu_count()) as pool:
    results = pool.map(process_track, enumerate(sorted_songs, 1))

playlist = [r for r in results if r is not None]

valid_assets = {Path(item["src"]).name for item in playlist}
for dir_path in (DEST_DIR, Path("dist/music/assets")):
    if dir_path.exists():
        for p in dir_path.glob("*.opus"):
            if p.name not in valid_assets:
                p.unlink()
                print(f"Pruned stale asset: {p}")

with open(PLAYLIST_FILE, "w", encoding="utf-8") as f:
    json.dump(playlist, f, indent=2, ensure_ascii=False)

print(f"\nDone. Exported {len(playlist)} track(s) to {PLAYLIST_FILE}.") 