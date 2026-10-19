#!/usr/bin/env python3

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
#
## Rofi   : Clipboard history (copyq)

import json
import os
import subprocess as sp

copyq_script = r"""
var result=[];
for (var i = 0; i < size(); ++i) {
  var obj = {};
  obj.row = i;
  obj.text = str(read(i));
  result.push(obj);
}
JSON.stringify(result);
"""

p = sp.run(['copyq', '-'], input=copyq_script, encoding='utf-8', stdout=sp.PIPE, stderr=sp.PIPE)
items = json.loads(p.stdout)

# Collapse newlines for display only
display = [" ".join(obj['text'].replace("\n", " ").split()) for obj in items]

rofi = ['rofi', '-dmenu', '-i', '-p', '󰅌  Clipboard', '-format', 'i',
        '-theme', os.path.expanduser('~/.config/rofi/themes/clipboard.rasi')]

p = sp.run(rofi, input='\n'.join(display), encoding='utf-8', stdout=sp.PIPE)

if p.returncode == 0:
    idx = int(p.stdout.strip())
    result = sp.run(['copyq', 'read', str(idx)], stdout=sp.PIPE)
    sp.run(['copyq', 'copy', '-'], input=result.stdout, stdout=sp.PIPE)
