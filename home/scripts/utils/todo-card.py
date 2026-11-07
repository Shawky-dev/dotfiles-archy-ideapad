#!/usr/bin/env python3
"""Always-on todo card (read-only). Drag it with the mouse to move it.

Shows ~/notes/todo.md and redraws when it changes. Edit with
~/.config/rofi/scripts/todo.sh. Show/hide (or start):
    todo-card.py --toggle
    todo-card.py --here      (move to the focused monitor; the rofi menu does this)
It shows on the focused monitor; toggling while it's on another monitor
brings it over instead of hiding it.
"""
import json
import os
import subprocess
import signal
import sys
from pathlib import Path

import cairo
import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, Gio, GLib, Gtk  # noqa: E402

FILE = Path.home() / "notes" / "todo.md"
WIDTH = 320
# Default spot, measured from the monitor's top-right corner. Dragging the
# card saves a new spot to STATE, used on every monitor.
MARGIN_RIGHT = 12
MARGIN_TOP = 40  # clears polybar
STATE = Path(GLib.get_user_state_dir()) / "todo-card.json"

CSS = b"""
#card {
    background-color: rgba(29, 32, 33, 0.85);
    border: 2px solid #962b1f;
    border-radius: 5px;
    padding: 12px 14px;
}
label { font-family: "Iosevka Nerd Font Mono"; font-size: 12pt; color: #d5c4a1; }
#title { font-weight: bold; font-size: 13pt; }
#count { color: #a89984; }
.done { color: #a89984; text-decoration-line: line-through; }
"""


def read_tasks():
    try:
        lines = FILE.read_text().splitlines()
    except FileNotFoundError:
        return []
    tasks = []
    for line in lines:
        if line.startswith("- [ ] "):
            tasks.append((False, line[6:]))
        elif line[:6].lower() == "- [x] ":
            tasks.append((True, line[6:]))
    # open tasks first, like the rofi menu
    return [t for t in tasks if not t[0]] + [t for t in tasks if t[0]]


def focused_monitor(display):
    """Monitor of the focused i3 workspace (falls back to the mouse's)."""
    try:
        out = subprocess.run(["i3-msg", "-t", "get_workspaces"], capture_output=True, text=True, timeout=1)
        ws = next(w for w in json.loads(out.stdout) if w["focused"])
        r = ws["rect"]
        return display.get_monitor_at_point(r["x"] + r["width"] // 2, r["y"] + r["height"] // 2)
    except Exception:
        _, x, y = display.get_default_seat().get_pointer().get_position()[0:3]
        return display.get_monitor_at_point(x, y)


def load_offset():
    try:
        d = json.loads(STATE.read_text())
        return int(d["right"]), int(d["top"])
    except Exception:
        return MARGIN_RIGHT, MARGIN_TOP


class Card(Gtk.Window):
    def __init__(self):
        # POPUP = override-redirect: i3 leaves it alone, so it sits on top
        # of every workspace without any i3 rules.
        super().__init__(type=Gtk.WindowType.POPUP)
        self.hidden = False
        self.drag = None  # (pointer x, pointer y, window x, window y) while dragging
        self.offset = load_offset()
        self.mon = focused_monitor(self.get_display())
        self.set_app_paintable(True)
        visual = self.get_screen().get_rgba_visual()
        if visual:
            self.set_visual(visual)
        self.connect("draw", self.clear_bg)
        self.connect("size-allocate", lambda *_: self.drag or self.place())

        self.add_events(Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK
                        | Gdk.EventMask.POINTER_MOTION_MASK)
        self.connect("realize", lambda *_: self.get_window().set_cursor(
            Gdk.Cursor.new_from_name(self.get_display(), "grab")))
        self.connect("button-press-event", self.drag_start)
        self.connect("motion-notify-event", self.drag_move)
        self.connect("button-release-event", self.drag_end)

        self.box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.box.set_name("card")
        self.box.set_size_request(WIDTH, -1)
        self.add(self.box)

        self.monitor = Gio.File.new_for_path(str(FILE)).monitor_file(Gio.FileMonitorFlags.NONE, None)
        self.monitor.connect("changed", lambda *_: self.render())
        try:
            from gi.repository import GLibUnix
            add_signal = GLibUnix.signal_add
        except ImportError:  # older PyGObject
            add_signal = GLib.unix_signal_add
        add_signal(GLib.PRIORITY_DEFAULT, signal.SIGUSR1, self.toggle)
        add_signal(GLib.PRIORITY_DEFAULT, signal.SIGUSR2, self.come_here)
        self.render()

    def clear_bg(self, _widget, cr):
        cr.set_operator(cairo.OPERATOR_CLEAR)
        cr.paint()
        cr.set_operator(cairo.OPERATOR_OVER)
        return False

    def render(self):
        for child in self.box.get_children():
            child.destroy()
        tasks = read_tasks()
        open_count = sum(1 for done, _ in tasks if not done)

        header = Gtk.Box(spacing=8)
        title = Gtk.Label(label="󰄵  TODO", xalign=0)
        title.set_name("title")
        count = Gtk.Label(label=f"{open_count} left", xalign=1)
        count.set_name("count")
        header.pack_start(title, True, True, 0)
        header.pack_end(count, False, False, 0)
        self.box.pack_start(header, False, False, 0)
        self.box.pack_start(Gtk.Separator(), False, False, 4)

        for done, text in tasks:
            label = Gtk.Label(label=("☑  " if done else "☐  ") + text, xalign=0)
            label.set_line_wrap(True)
            label.set_max_width_chars(30)
            if done:
                label.get_style_context().add_class("done")
            self.box.pack_start(label, False, False, 0)

        self.resize(1, 1)  # shrink to fit the new list
        if tasks and not self.hidden:
            self.show_all()
            self.place()
        else:
            self.hide()

    def place(self):
        """Put the card at the saved offset from self.mon's top-right corner."""
        geo = self.mon.get_geometry()
        width, _ = self.get_size()
        right, top = self.offset
        self.move(geo.x + geo.width - width - right, geo.y + top)

    def drag_start(self, _w, event):
        if event.button == 1:
            x, y = self.get_position()
            self.drag = (event.x_root, event.y_root, x, y)
            self.get_window().set_cursor(Gdk.Cursor.new_from_name(self.get_display(), "grabbing"))
        return True

    def drag_move(self, _w, event):
        if self.drag:
            px, py, wx, wy = self.drag
            self.move(int(wx + event.x_root - px), int(wy + event.y_root - py))
        return True

    def drag_end(self, _w, _event):
        if not self.drag:
            return True
        self.drag = None
        self.get_window().set_cursor(Gdk.Cursor.new_from_name(self.get_display(), "grab"))
        # Remember the spot relative to whichever monitor it was dropped on.
        x, y = self.get_position()
        width, height = self.get_size()
        self.mon = self.get_display().get_monitor_at_point(x + width // 2, y + height // 2)
        geo = self.mon.get_geometry()
        self.offset = (geo.x + geo.width - x - width, y - geo.y)
        STATE.parent.mkdir(parents=True, exist_ok=True)
        STATE.write_text(json.dumps({"right": self.offset[0], "top": self.offset[1]}))
        return True

    def toggle(self):
        here = focused_monitor(self.get_display())
        if self.hidden or not self.get_visible():
            self.hidden = False  # show it on the focused monitor
        elif here != self.mon:
            pass  # visible on another monitor: bring it here instead of hiding
        else:
            self.hidden = True
        self.mon = here
        self.render()
        return GLib.SOURCE_CONTINUE

    def come_here(self):
        """Move to the focused monitor without changing shown/hidden."""
        self.mon = focused_monitor(self.get_display())
        self.place()
        return GLib.SOURCE_CONTINUE


PIDFILE = Path(GLib.get_user_runtime_dir()) / "todo-card.pid"


def running_pid():
    try:
        pid = int(PIDFILE.read_text())
        os.kill(pid, 0)
        return pid
    except (FileNotFoundError, ValueError, ProcessLookupError, PermissionError):
        return None


def main():
    pid = running_pid()
    if pid:
        # Already running: --toggle shows/hides it, --here moves it to the
        # focused monitor, a plain start does nothing.
        if "--toggle" in sys.argv:
            os.kill(pid, signal.SIGUSR1)
        elif "--here" in sys.argv:
            os.kill(pid, signal.SIGUSR2)
        return
    if "--here" in sys.argv:
        return
    PIDFILE.write_text(str(os.getpid()))

    provider = Gtk.CssProvider()
    provider.load_from_data(CSS)
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )
    FILE.parent.mkdir(parents=True, exist_ok=True)
    FILE.touch(exist_ok=True)
    Card()
    Gtk.main()


if __name__ == "__main__":
    main()
