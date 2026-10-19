#!/usr/bin/env python3

## Rofi : Workspace sessions
#
## Save the open windows (app, workspace, folder) under a name and reopen
## them later on the same workspaces.
#
## Enter         restore the session / save current windows
## Ctrl+s        overwrite the selected session with the current windows
## Shift+Delete  delete the selected session
#
## CLI: sessions.sh [save <name> | restore <name> | list | selftest]

import json
import os
import re
import shlex
import shutil
import subprocess as sp
import sys
from pathlib import Path

import i3ipc

THEME = os.path.expanduser('~/.config/rofi/themes/menu.rasi')
STORE = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local/share')) / 'i3-sessions'
TIMEOUT = 20  # seconds to wait for restored windows to appear

SHELLS = {'zsh', 'bash', 'fish', 'sh'}
VSCODE = {'Code', 'com.microsoft.VSCode'}  # window class differs between VS Code versions
# Foreground programs worth reopening in a restored terminal (anything else gets a plain shell)
RERUN = {
    'claude': 'claude --continue',
    'nvim': 'nvim', 'vim': 'vim',
    'btop': 'btop', 'htop': 'htop',
    'lazygit': 'lazygit', 'yazi': 'yazi',
}


# ---------------------------------------------------------------- /proc helpers

def read(path, binary=False):
    try:
        with open(path, 'rb' if binary else 'r') as f:
            return f.read()
    except OSError:
        return b'' if binary else ''


def children(pid):
    return [int(p) for p in read(f'/proc/{pid}/task/{pid}/children').split()]


def comm(pid):
    return read(f'/proc/{pid}/comm').strip()


def cwd(pid):
    try:
        return os.readlink(f'/proc/{pid}/cwd')
    except OSError:
        return None


def cmdline(pid):
    args = [a.decode(errors='replace') for a in read(f'/proc/{pid}/cmdline', True).split(b'\0') if a]
    # Electron/Chromium rewrite argv into one space-joined string
    if len(args) == 1 and not shutil.which(args[0]):
        args = args[0].split()
    return args


def window_pid(xid):
    p = sp.run(['xdotool', 'getwindowpid', str(xid)], capture_output=True, text=True)
    return int(p.stdout) if p.stdout.strip().isdigit() else None


# ---------------------------------------------------------------- launch specs

def kitty_spec(pid):
    # shortcut: kitty only, one shell per kitty process; add other terminals here if you switch
    shell = next((c for c in children(pid) if comm(c) in SHELLS), None)
    if shell is None:
        return None
    run = next((RERUN[comm(c)] for c in children(shell) if comm(c) in RERUN), None)
    sh = os.environ.get('SHELL', '/bin/sh')
    return {'cmd': ['kitty'] + ([sh, '-ic', f'{run}; exec {shlex.quote(sh)}'] if run else []),
            'cwd': cwd(shell)}


def vscode_folder(title):
    # Needs "window.title" to contain ${rootPath} (see VS Code settings)
    return next((p for p in (title or '').split(' - ') if p.startswith('/') and os.path.isdir(p)), None)


def launch_spec(con, pid):
    if con.window_class in VSCODE:
        folder = vscode_folder(con.name)
        return {'cmd': ['code', folder] if folder else ['code'], 'cwd': None}
    if con.window_class == 'firefox':
        return {'cmd': ['firefox'], 'cwd': None}  # Firefox restores its own tabs
    if not pid:
        return None
    if con.window_class == 'kitty':
        return kitty_spec(pid)
    args = cmdline(pid)
    # Apps on the system electron (bruno...) need their /usr/bin wrapper, which sets env like ELECTRON_IS_DEV=0
    wrapper = shutil.which((con.window_class or '').lower())
    if args and re.fullmatch(r'electron\d*', os.path.basename(args[0])) and wrapper:
        args = [wrapper] + args[2:]
    return {'cmd': args, 'cwd': cwd(pid)} if args else None


# ---------------------------------------------------------------- capture / restore

def windows(tree):
    for con in tree.descendants():
        ws = con.workspace()
        if con.window and con.parent.type != 'dockarea' and ws and not ws.name.startswith('__'):
            yield con, ws


def capture(i3):
    tree = i3.get_tree()
    entries, skipped = [], []
    for con, ws in windows(tree):
        pid = window_pid(con.window)
        spec = launch_spec(con, pid)
        if spec:
            entries.append({'workspace': ws.name, 'num': ws.num, 'class': con.window_class,
                            'title': con.name, 'pid': pid, **spec})
        else:
            skipped.append(con.window_class or con.name)
    focused = tree.find_focused()
    return {'focused': focused.workspace().name if focused and focused.workspace() else None,
            'windows': entries}, skipped


def launch(entry):
    d = entry['cwd']
    try:
        return sp.Popen(entry['cmd'], cwd=d if d and os.path.isdir(d) else Path.home(),
                        stdin=sp.DEVNULL, stdout=sp.DEVNULL, stderr=sp.DEVNULL, start_new_session=True).pid
    except OSError:
        return None


def restore(i3, session):
    pending = session['windows']
    move = lambda con, e: i3.command(f'[con_id={con.id}] move container to workspace "{e["workspace"]}"')

    # Adopt windows that are already open instead of launching duplicates
    for con, _ in windows(i3.get_tree()):
        spec = launch_spec(con, window_pid(con.window))
        e = spec and next((e for e in pending if (e['class'], e['cmd'], e['cwd'])
                           == (con.window_class, spec['cmd'], spec['cwd'])), None)
        if e:
            move(con, e)
            pending.remove(e)

    # Windows of one process (Firefox restoring several windows) come back from a single launch
    groups = {}
    for e in pending:
        e['group'] = (e['pid'], tuple(e['cmd']), e['cwd'])
        groups.setdefault(e['group'], e)
    launched, failed = {}, []
    for key, e in groups.items():
        pid = launch(e)
        if pid:
            launched[pid] = key
        else:
            failed.append(e['class'])
    pending = [e for e in pending if e['group'] in launched.values()]

    def on_new(i3, ev):
        con = ev.container
        key = launched.get(window_pid(con.window))
        # shortcut: apps that fork (code, firefox) are matched by class in launch order, so two
        # same-class windows can swap workspaces; match on title change events if that bites
        e = (next((e for e in pending if e['group'] == key), None)
             or next((e for e in pending if e['class'] == con.window_class), None))
        if e:
            move(con, e)
            pending.remove(e)
            if not pending:
                i3.main_quit()

    if pending:
        i3.on(i3ipc.Event.WINDOW_NEW, on_new)
        i3.main(timeout=TIMEOUT)

    if session['focused']:
        i3.command(f'workspace "{session["focused"]}"')
    return [e['class'] for e in pending] + [f'{c} (failed to launch)' for c in failed]


# ---------------------------------------------------------------- storage

def session_path(name):
    return STORE / f'{name}.json'


def load(name):
    return json.loads(session_path(name).read_text())


def sessions():
    return sorted(p.stem for p in STORE.glob('*.json'))


def summary(name):
    try:
        wins = load(name)['windows']
    except (OSError, ValueError, KeyError):
        return 'unreadable'
    ws = sorted({(w['num'], w['workspace']) for w in wins})
    return f"{len(wins)} windows · ws {' '.join(n for _, n in ws)}"


def clean_name(name):
    return re.sub(r'[\s/]+', '-', name.strip()).strip('-.')


# ---------------------------------------------------------------- actions / UI

def notify(title, body=''):
    sp.run(['notify-send', '-a', 'Sessions', title, body])


def do_save(i3, name):
    STORE.mkdir(parents=True, exist_ok=True)
    session, skipped = capture(i3)
    session_path(name).write_text(json.dumps(session, indent=2))
    notify(f'Saved "{name}"', summary(name) + (f"\nskipped: {', '.join(skipped)}" if skipped else ''))


def do_restore(i3, name):
    missing = restore(i3, load(name))
    notify(f'Restored "{name}"', f"didn't appear: {', '.join(missing)}" if missing else '')


def rofi(lines, prompt, *args):
    p = sp.run(['rofi', '-dmenu', '-i', '-p', prompt, '-theme', THEME, *args],
               input='\n'.join(lines), capture_output=True, text=True)
    return p.returncode, p.stdout.strip()


def confirm(question):
    _, ans = rofi(['Yes', 'No'], 'Confirmation', '-mesg', question, '-no-custom',
                  '-theme-str', 'window {width: 250px;}',
                  '-theme-str', 'mainbox {children: [ "message", "listview" ];}',
                  '-theme-str', 'listview {columns: 2; lines: 1;}',
                  '-theme-str', 'element-text {horizontal-align: 0.5;}',
                  '-theme-str', 'textbox {horizontal-align: 0.5;}')
    return ans == 'Yes'


def menu(i3):
    names = sessions()
    lines = ['󰐕  Save current…'] + [f'{n}\t{summary(n)}' for n in names]
    code, idx = rofi(lines, 'Sessions >', '-format', 'i', '-no-custom',
                     '-display-columns', '1,2', '-display-column-separator', '\t',
                     '-mesg', 'Enter restore · Ctrl+s overwrite · Shift+Del delete',
                     '-kb-delete-entry', '', '-kb-custom-1', 'Control+s', '-kb-custom-2', 'Shift+Delete',
                     '-theme-str', 'window {width: 600px;}')
    if code not in (0, 10, 11) or not idx.isdigit():
        return
    i = int(idx)

    if i == 0:
        _, name = rofi([], 'Name >', '-theme-str', 'entry {placeholder: "session name...";}',
                       '-theme-str', 'listview {enabled: false;}')
        name = clean_name(name)
        if name and (name not in names or confirm(f'Overwrite "{name}"?')):
            do_save(i3, name)
        return

    name = names[i - 1]
    if code == 0:
        do_restore(i3, name)
    elif code == 10 and confirm(f'Overwrite "{name}"?'):
        do_save(i3, name)
    elif code == 11 and confirm(f'Delete "{name}"?'):
        session_path(name).unlink()
        notify(f'Deleted "{name}"')


def selftest():
    assert clean_name(' Trunk work/setup ') == 'Trunk-work-setup'
    assert vscode_folder('main.py - /tmp - Visual Studio Code') == '/tmp'
    assert vscode_folder('Welcome - trunk - Visual Studio Code') is None
    global read
    read = lambda path, binary=False: b'/usr/share/code/code .' if binary else ''
    assert cmdline(1) == ['/usr/share/code/code', '.']
    read = lambda path, binary=False: b'kitty\0--directory\0/my dir' if binary else ''
    assert cmdline(1) == ['kitty', '--directory', '/my dir']
    read = lambda path, binary=False: b'/usr/lib/electron37/electron\0/usr/lib/bruno' if binary else ''
    if shutil.which('bruno'):
        con = type('Con', (), {'window_class': 'bruno', 'name': 'Bruno'})
        assert launch_spec(con, 1)['cmd'] == [shutil.which('bruno')]
    print('ok')


def main():
    args = sys.argv[1:]
    if args == ['selftest']:
        return selftest()
    if args == ['list']:
        return print('\n'.join(f'{n}\t{summary(n)}' for n in sessions()))
    i3 = i3ipc.Connection()
    if not args:
        menu(i3)
    elif args[0] in ('save', 'restore') and len(args) == 2:
        (do_save if args[0] == 'save' else do_restore)(i3, clean_name(args[1]))
    else:
        sys.exit(f'usage: {Path(sys.argv[0]).name} [save <name> | restore <name> | list | selftest]')


if __name__ == '__main__':
    main()
