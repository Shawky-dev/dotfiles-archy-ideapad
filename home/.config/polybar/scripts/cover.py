#!/usr/bin/env python3
"""Polybar album cover: a tiny image drawn over a gap in the bar.

Polybar can't show images, so this runs as the `cover` custom/script module:
it prints a fixed-size gap for polybar and draws the cover in a small window
placed over that gap. One copy runs per bar ($MONITOR) and exits with it.

Art comes from MPRIS (playerctl). Local files (Firefox) are read in place;
web URLs are downloaded to a single file in $XDG_RUNTIME_DIR (RAM, wiped at
logout), overwritten each song and deleted on exit.
Run with --test for a quick self-check.
"""
import os
import subprocess
import sys
import urllib.parse
import urllib.request

SIZE = 20          # cover size in px
GAP = "%{O24}"     # space reserved in the bar for it
LEFT = 16          # px from the bar window's left edge to the gap (calibrated against a screenshot)
CACHE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), f"polybar-cover-{os.environ.get('MONITOR', 'bar')}")


def source_for(url):
    """('file', path) for local art, ('http', url) for web art, None otherwise."""
    if url.startswith("file://"):
        return "file", urllib.parse.unquote(urllib.parse.urlparse(url).path)
    if url.startswith(("http://", "https://")):
        return "http", url
    return None


def self_test():
    assert source_for("file:///home/u/a%20b.png") == ("file", "/home/u/a b.png")
    assert source_for("https://i.scdn.co/image/x") == ("http", "https://i.scdn.co/image/x")
    assert source_for("") is None and source_for("data:image/png;base64,xx") is None
    print("ok")


def main():
    import cairo
    import gi
    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    gi.require_version("GdkX11", "3.0")
    gi.require_version("GdkPixbuf", "2.0")
    from gi.repository import Gdk, GdkPixbuf, GdkX11, GLib, Gtk

    class Cover(Gtk.Window):
        def __init__(self):
            # POPUP = override-redirect, so i3 leaves it alone
            super().__init__(type=Gtk.WindowType.POPUP)
            self.pixbuf = None
            self.set_app_paintable(True)
            visual = self.get_screen().get_rgba_visual()
            if visual:
                self.set_visual(visual)
            self.set_size_request(SIZE, SIZE)
            self.connect("draw", self.draw)
            self.connect("realize", lambda *_: self.get_window().input_shape_combine_region(cairo.Region(), 0, 0))

        def draw(self, _w, cr):
            cr.set_operator(cairo.OPERATOR_CLEAR)
            cr.paint()
            cr.set_operator(cairo.OPERATOR_OVER)
            if self.pixbuf:
                r = 3  # rounded corners
                cr.new_sub_path()
                for x, y, a in ((SIZE - r, r, -90), (SIZE - r, SIZE - r, 0), (r, SIZE - r, 90), (r, r, 180)):
                    cr.arc(x, y, r, a * 3.14159 / 180, (a + 90) * 3.14159 / 180)
                cr.close_path()
                cr.clip()
                Gdk.cairo_set_source_pixbuf(cr, self.pixbuf, 0, 0)
                cr.paint()
            return False

        def bar_window(self):
            """This bar's polybar window (named polybar-<bar>_<monitor>)."""
            monitor = os.environ.get("MONITOR", "")
            out = subprocess.run(["xdotool", "search", "--name", f"^polybar-.*_{monitor}$"],
                                 capture_output=True, text=True).stdout.split()
            if not out:
                return None
            return GdkX11.X11Window.foreign_new_for_display(self.get_display(), int(out[0]))

        def show_art(self, path):
            try:
                self.pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, SIZE, SIZE, False)
            except GLib.Error:
                return self.hide_art()
            bar = self.bar_window()
            if not bar:
                return self.hide_art()
            _, bx, by = bar.get_origin()
            bh = bar.get_height()
            self.move(bx + LEFT, by + (bh - SIZE) // 2)
            self.show()
            self.queue_draw()
            # sit right above the bar, so fullscreen windows cover both
            self.get_window().restack(bar, True)
            print(GAP, flush=True)

        def hide_art(self):
            self.pixbuf = None
            self.hide()
            print("", flush=True)

        def update(self, line):
            status, _, url = line.rstrip("\n").partition("\t")
            src = source_for(url) if status in ("Playing", "Paused") else None
            if not src:
                return self.hide_art()
            kind, where = src
            if kind == "http":
                try:
                    # shortcut: blocks the bar's cover for up to 3s on a slow download
                    with urllib.request.urlopen(where, timeout=3) as resp, open(CACHE, "wb") as f:
                        f.write(resp.read(2_000_000))
                except OSError:
                    return self.hide_art()
                where = CACHE
            self.show_art(where)

    cover = Cover()
    cmd = ["playerctl", "--player=playerctld,%any", "metadata", "--follow",
           "--format", "{{status}}\t{{mpris:artUrl}}"]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, text=True, bufsize=1)

    def on_line(source, _cond):
        line = source.readline()
        if not line:  # playerctl exited
            Gtk.main_quit()
            return False
        cover.update(line)
        return True

    GLib.io_add_watch(proc.stdout, GLib.IO_IN | GLib.IO_HUP, on_line)
    parent = os.getppid()
    GLib.timeout_add_seconds(2, lambda: os.getppid() == parent or Gtk.main_quit())  # exit with polybar
    cover.hide_art()
    try:
        Gtk.main()
    finally:
        proc.terminate()
        if os.path.exists(CACHE):
            os.remove(CACHE)


if __name__ == "__main__":
    if "--test" in sys.argv:
        self_test()
    else:
        try:
            main()
        except (KeyboardInterrupt, BrokenPipeError):
            pass
