#!/bin/bash
# obs-focus-follow.sh - event-driven version (instant switching)

OBS_HOST="localhost"
OBS_PORT="4455"
OBS_PASSWORD=""
SCENE_MONITOR_1="Monitor1"
SCENE_MONITOR_2="Monitor2"
BLOCK_SCENE="Block"

get_current_obs_scene() {
    python3 - <<PYEOF
import websocket, json, hashlib, base64

host = "${OBS_HOST}"
port = ${OBS_PORT}
password = "${OBS_PASSWORD}"

ws = websocket.WebSocket()
ws.connect(f"ws://{host}:{port}")

hello = json.loads(ws.recv())
if "authentication" in hello["d"]:
    challenge = hello["d"]["authentication"]["challenge"]
    salt = hello["d"]["authentication"]["salt"]
    secret = base64.b64encode(
        hashlib.sha256((password + salt).encode()).digest()
    ).decode()
    auth = base64.b64encode(
        hashlib.sha256((secret + challenge).encode()).digest()
    ).decode()
else:
    auth = ""

ws.send(json.dumps({
    "op": 1,
    "d": {"rpcVersion": 1, "authentication": auth, "eventSubscriptions": 0}
}))
ws.recv()

ws.send(json.dumps({
    "op": 6,
    "d": {
        "requestType": "GetCurrentProgramScene",
        "requestId": "1",
        "requestData": {}
    }
}))
resp = json.loads(ws.recv())
ws.close()
print(resp["d"]["responseData"]["sceneName"])
PYEOF
}

switch_obs_scene() {
    local scene="$1"
    python3 - <<PYEOF
import websocket, json, hashlib, base64

host = "${OBS_HOST}"
port = ${OBS_PORT}
password = "${OBS_PASSWORD}"
scene = "${scene}"

ws = websocket.WebSocket()
ws.connect(f"ws://{host}:{port}")

hello = json.loads(ws.recv())
if "authentication" in hello["d"]:
    challenge = hello["d"]["authentication"]["challenge"]
    salt = hello["d"]["authentication"]["salt"]
    secret = base64.b64encode(
        hashlib.sha256((password + salt).encode()).digest()
    ).decode()
    auth = base64.b64encode(
        hashlib.sha256((secret + challenge).encode()).digest()
    ).decode()
else:
    auth = ""

ws.send(json.dumps({
    "op": 1,
    "d": {"rpcVersion": 1, "authentication": auth, "eventSubscriptions": 0}
}))
ws.recv()

ws.send(json.dumps({
    "op": 6,
    "d": {
        "requestType": "SetCurrentProgramScene",
        "requestId": "1",
        "requestData": {"sceneName": scene}
    }
}))
ws.close()
PYEOF
}

# Subscribe to i3 workspace focus events — fires instantly on change
i3-msg -t subscribe -m '["workspace"]' | while read -r event; do
    # Check if OBS is currently on the Block scene — if so, do nothing
    CURRENT_SCENE=$(get_current_obs_scene)
    if [ "$CURRENT_SCENE" = "$BLOCK_SCENE" ]; then
        echo "Blocked: OBS is on '$BLOCK_SCENE', skipping switch"
        continue
    fi

    OUTPUT=$(i3-msg -t get_workspaces | python3 -c "
import json, sys
for ws in json.load(sys.stdin):
    if ws['focused']:
        print(ws['output'])
        break
")
    echo "Monitor: $OUTPUT"
    if [ "$OUTPUT" = "eDP-1" ]; then
        switch_obs_scene "$SCENE_MONITOR_1"
    elif [ "$OUTPUT" = "HDMI-1" ]; then
        switch_obs_scene "$SCENE_MONITOR_2"
    fi
done
