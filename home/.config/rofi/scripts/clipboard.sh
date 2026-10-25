#!/usr/bin/env python3

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
#
## Rofi   : Clipboard history (copyq), with thumbnails for images

import json
import os
import subprocess as sp

CACHE = os.path.expanduser('~/.cache/rofi-clipboard')
THEME = os.path.expanduser('~/.config/rofi/themes/clipboard.rasi')
TEXT_ICON = os.path.join(CACHE, '_text.png')

copyq_script = r"""
var result=[];
for (var i = 0; i < size(); ++i) {
  var it = getItem(i);
  var image = '';
  for (var k in it) if (k.indexOf('image/') === 0) { image = k; break; }
  result.push({
    row: i, image: image,
    hash: image ? sha1sum(it[image]).substring(0, 16) : '',
    text: image ? '' : str(it['text/plain']).substring(0, 400)
  });
}
JSON.stringify(result);
"""


def thumbnail(row, mime, key):
    """Cache a rounded thumbnail for an image item; return (path, label).
    Image data is only fetched from copyq the first time an image is seen."""
    path = os.path.join(CACHE, key + '.png')
    meta = path + '.txt'
    if not os.path.exists(path):
        data = sp.run(['copyq', 'read', mime, str(row)], stdout=sp.PIPE).stdout
        sp.run(['magick', '-', '-auto-orient', '-thumbnail', '160x160^', '-gravity', 'center', '-extent', '160x160',
                '(', '+clone', '-alpha', 'extract', '-fill', 'black', '-colorize', '100',
                '-fill', 'white', '-draw', 'roundrectangle 0,0 159,159 18,18', ')',
                '-alpha', 'off', '-compose', 'CopyOpacity', '-composite', path],
               input=data, stdout=sp.DEVNULL, stderr=sp.DEVNULL)
        size = sp.run(['magick', 'identify', '-format', '%wx%h', '-'],
                      input=data, stdout=sp.PIPE, stderr=sp.DEVNULL).stdout.decode()
        with open(meta, 'w') as f:
            f.write(size.split('x')[0] + '×' + size.split('x')[-1] if 'x' in size else '')
    try:
        dims = open(meta).read().strip()
    except OSError:
        dims = ''
    kind = mime.split('/')[-1].upper()
    label = f"Image  <span alpha='60%'>{dims}  ·  {kind}</span>" if dims else 'Image'
    return path, label


def text_icon():
    """Small muted glyph so text rows line up with image rows."""
    if not os.path.exists(TEXT_ICON):
        sp.run(['magick', '-size', '160x160', 'xc:none', '-fill', '#32302f',
                '-draw', 'roundrectangle 0,0 159,159 18,18',
                '-fill', '#7c6f64', '-draw', 'roundrectangle 46,52 114,60 4,4',
                '-draw', 'roundrectangle 46,76 114,84 4,4',
                '-draw', 'roundrectangle 46,100 92,108 4,4', TEXT_ICON],
               stdout=sp.DEVNULL, stderr=sp.DEVNULL)
    return TEXT_ICON


def escape(s):
    return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


os.makedirs(CACHE, exist_ok=True)
p = sp.run(['copyq', '-'], input=copyq_script, encoding='utf-8', stdout=sp.PIPE, stderr=sp.PIPE)
items = json.loads(p.stdout)

rows, used = [], {TEXT_ICON}
for obj in items:
    if obj['image']:
        icon, label = thumbnail(obj['row'], obj['image'], obj['hash'])
        used.add(icon)
    else:
        icon = text_icon()
        # Collapse newlines for display only
        label = escape(' '.join(obj['text'].replace('\n', ' ').split())[:300])
    rows.append(f"{label}\0icon\x1f{icon}")

# Drop thumbnails of items no longer in the history
for name in os.listdir(CACHE):
    full = os.path.join(CACHE, name)
    if full.removesuffix('.txt') not in used:
        os.remove(full)

rofi = ['rofi', '-dmenu', '-i', '-markup-rows', '-show-icons', '-p', '󰅌  Clipboard',
        '-format', 'i', '-theme', THEME]

p = sp.run(rofi, input='\n'.join(rows), encoding='utf-8', stdout=sp.PIPE)

if p.returncode == 0 and p.stdout.strip():
    # select() puts the item back on the clipboard with all its formats (keeps images intact)
    sp.run(['copyq', 'select', p.stdout.strip()], stdout=sp.PIPE)
