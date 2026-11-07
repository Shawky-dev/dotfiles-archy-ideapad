#!/usr/bin/env python3
"""Polybar media title: "icon  Title · Artist", tidy for English and Arabic.

Follows playerctl and prints one line per change. Titles are cleaned of
YouTube-style junk, shortened in reading order, then Arabic parts are put
into display order with fribidi (polybar can't do right-to-left itself).
"""
import re
import subprocess
import sys

DIM = "#665c54"  # colors.base03
TITLE_MAX = 28
ARTIST_MAX = 18
SEP = " · "

ARABIC = re.compile("[؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿]")
LATIN = re.compile("[A-Za-zÀ-ɏ]")

# Bracketed tags like "(Official Music Video)", "[Lyrics]", "(فيديو كليب)"
JUNK_WORDS = (
    r"official|video|audio|lyrics?|visuali[sz]er|music|hd|hq|4k|1080p|remaster(?:ed)?|"
    r"m/?v|clip|explicit|فيديو|كليب|كلمات|حصريا|حصريًا|اوديو|أوديو|بالكلمات"
)
JUNK_BRACKETS = re.compile(r"\s*[(\[【][^)\]】]*\b(?:" + JUNK_WORDS + r")\b[^)\]】]*[)\]】]", re.I)
JUNK_TAIL = re.compile(r"\s*(?:[-|–—]\s*YouTube(?: Music)?|\|.*)$", re.I)
DASH = re.compile(r"\s+[-–—]\s+")
# Bare quality tags at the end: "Song 4K", "Song HD"
QUALITY_TAIL = re.compile(r"(?:\s+(?:4k|hd|hq|1080p|720p))+$", re.I)

FIELDS = ["player", "status", "artist", "title", "url"]
FORMAT = "\t".join("{{%s}}" % f for f in ["playerName", "status", "artist", "title", "xesam:url"])


def icon_for(player, url):
    key = f"{player} {url}".lower()
    for needle, icon in [
        ("youtube", "\U000f05c3"),
        ("youtu.be", "\U000f05c3"),
        ("twitch", "\U000f0543"),
        ("spotify", "\U000f04c7"),
        ("mpv", ""),
        ("vlc", "\U000f057c"),
    ]:
        if needle in key:
            return icon
    return "\U000f075a"  # music note (Anghami and everything else)


def clean_title(title):
    title = JUNK_BRACKETS.sub("", title)
    title = JUNK_TAIL.sub("", title)
    title = QUALITY_TAIL.sub("", title.strip())
    return re.sub(r"\s{2,}", " ", title).strip(" -|·–—")


def clean_artist(artist):
    artist = re.sub(r"\s*-\s*Topic$|VEVO$", "", artist, flags=re.I)
    return artist.strip()


def squash(text):
    return re.sub(r"\W", "", text).casefold()


def split_artist(title, artist, url):
    """YouTube titles are often "Artist - Song" with the channel as artist."""
    parts = DASH.split(title, maxsplit=1)
    if len(parts) == 2 and all(parts):
        left, right = parts
        if not artist or "youtu" in url or squash(artist) in squash(left) or squash(left) in squash(artist):
            return right, left
    if artist and squash(artist) in squash(title):
        artist = ""  # already in the title
    return title, artist


def clip(text, limit):
    return text if len(text) <= limit else text[: limit - 1].rstrip() + "…"


def is_rtl(text):
    """First letter decides the reading direction, like fribidi does."""
    for ch in text:
        if ARABIC.match(ch):
            return True
        if LATIN.match(ch):
            return False
    return False


def visual(text):
    """Arabic → shaped, display-order text; anything else unchanged."""
    if not ARABIC.search(text):
        return text
    out = subprocess.run(["fribidi", "--nopad", "--nobreak"], input=text, capture_output=True, text=True)
    return out.stdout.strip() or text


def render(info):
    if info.get("status") not in ("Playing", "Paused") or not info.get("title"):
        return ""
    # "%{" would start a polybar formatting tag
    raw_title = info["title"].replace("%{", "% {")
    title = clean_title(raw_title) or raw_title
    artist = clean_artist(info.get("artist", "").replace("%{", "% {"))
    title, artist = split_artist(title, artist, info.get("url", ""))
    title, artist = clip(title, TITLE_MAX), clip(artist, ARTIST_MAX)

    paused = info["status"] == "Paused"
    t, a = visual(title), visual(artist)
    if a and not paused:
        a = f"%{{F{DIM}}}{a}%{{F-}}"
    if not a:
        text = t
    elif is_rtl(title):
        text = a + SEP + t  # right-to-left: title on the right, read first
    else:
        text = t + SEP + a

    icon = f"%{{T3}}{icon_for(info.get('player', ''), info.get('url', ''))}%{{T-}}"
    line = f"{icon}  {text}"
    return f"%{{F{DIM}}}{line}%{{F-}}" if paused else line


def main():
    cmd = ["playerctl", "--player=playerctld,%any", "metadata", "--follow", "--format", FORMAT]
    with subprocess.Popen(cmd, stdout=subprocess.PIPE, text=True, bufsize=1) as proc:
        for raw in proc.stdout:
            values = raw.rstrip("\n").split("\t")
            info = dict(zip(FIELDS, values)) if len(values) == len(FIELDS) else {}
            print(render(info), flush=True)


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        sys.exit(0)
