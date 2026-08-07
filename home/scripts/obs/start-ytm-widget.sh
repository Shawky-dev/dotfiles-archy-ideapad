#!/usr/bin/env bash
#
# start-ytm-widget.sh
#
# Serves the youtube-music-obs-widget folder over localhost HTTP so that
# OBS's Browser Source (CEF) treats it as loopback-to-loopback when it
# talks to YTMDesktop's companion server on 127.0.0.1:9863.
# This avoids Chrome's Local Network Access (LNA) / CORS restrictions
# that block file:// pages from reaching localhost APIs.
#
# Usage:
#   ./start-ytm-widget.sh            # start (or confirm already running)
#   ./start-ytm-widget.sh stop       # stop the server
#   ./start-ytm-widget.sh restart    # restart the server
#   ./start-ytm-widget.sh status     # check if it's running

set -euo pipefail

# ---- Configuration ----------------------------------------------------
WIDGET_DIR="/home/shawky/scripts/obs/youtube-music-obs-widget"
PORT=8080
PID_FILE="/tmp/ytm-widget-server.pid"
LOG_FILE="/tmp/ytm-widget-server.log"
# ------------------------------------------------------------------------

is_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid="$(cat "$PID_FILE")"
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

start_server() {
    if is_running; then
        echo "YT Music widget server already running (PID $(cat "$PID_FILE"))."
        echo "URL: http://localhost:${PORT}/index.html"
        return 0
    fi

    if [[ ! -d "$WIDGET_DIR" ]]; then
        echo "Error: widget directory not found: $WIDGET_DIR" >&2
        exit 1
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        echo "Error: python3 not found. Install it with: sudo pacman -S python" >&2
        exit 1
    fi

    # Check the port isn't already taken by something else
    if command -v ss >/dev/null 2>&1 && ss -ltn "( sport = :$PORT )" | grep -q ":$PORT"; then
        echo "Error: port $PORT is already in use by another process." >&2
        echo "Change PORT in this script, or free up the port." >&2
        exit 1
    fi

    cd "$WIDGET_DIR"
    nohup python3 -m http.server "$PORT" > "$LOG_FILE" 2>&1 &
    local pid=$!
    echo "$pid" > "$PID_FILE"

    # Give it a moment to fail fast if something's wrong
    sleep 0.5
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "Error: server failed to start. Check $LOG_FILE" >&2
        rm -f "$PID_FILE"
        exit 1
    fi

    echo "YT Music widget server started (PID $pid)."
    echo "URL for OBS Browser Source: http://localhost:${PORT}/index.html"
    echo "Log file: $LOG_FILE"
}

stop_server() {
    if is_running; then
        local pid
        pid="$(cat "$PID_FILE")"
        kill "$pid"
        rm -f "$PID_FILE"
        echo "YT Music widget server stopped (was PID $pid)."
    else
        echo "YT Music widget server is not running."
    fi
}

status_server() {
    if is_running; then
        echo "Running (PID $(cat "$PID_FILE")) — http://localhost:${PORT}/index.html"
    else
        echo "Not running."
    fi
}

case "${1:-start}" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        stop_server
        sleep 0.5
        start_server
        ;;
    status)
        status_server
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}" >&2
        exit 1
        ;;
esac
