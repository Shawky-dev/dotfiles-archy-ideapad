#!/usr/bin/env python3

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
#
## Rofi   : Launcher (Modi Drun, Run, File Browser, Window)
#
## Available Styles
#
## style-1     style-2     style-3     style-4     style-5
## style-6     style-7     style-8     style-9     style-10
## style-11    style-12    style-13    style-14    style-15

import json
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

rofi = ['rofi', '-dmenu', '-i', '-p', ' ', '-format', 'i',
        '-theme', '/home/shawky/.config/rofi/text/style-5.rasi']

p = sp.run(rofi, input='\n'.join(display), encoding='utf-8', stdout=sp.PIPE)

if p.returncode == 0:
    idx = p.stdout.strip()
    sp.run(f'copyq select({idx});', shell=True)
