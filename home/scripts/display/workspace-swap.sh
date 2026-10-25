#!/usr/bin/env bash
# Requires jq

# Get visible workspaces
mapfile -t WS < <(
  i3-msg -t get_workspaces | jq -r '.[] | select(.visible==true) | .name'
)

# Need exactly 2
[ "${#WS[@]}" -eq 2 ] || exit 1

WS1="${WS[0]}"
WS2="${WS[1]}"

# Get windows in workspace (reliable way)
get_windows() {
  local ws="$1"

  i3-msg -t get_tree | jq -r --arg WS "$ws" '
    # Find workspace nodes
    recurse(.nodes[], .floating_nodes[])
    | select(.type=="workspace" and .name==$WS)
    # From workspace, go down to windows
    | recurse(.nodes[], .floating_nodes[])
    | select(.type=="con" and .window!=null)
    | .id
  '
}

# Get IDs
W1=$(get_windows "$WS1")
W2=$(get_windows "$WS2")

# Swap
for id in $W1; do
  i3-msg "[con_id=$id] move to workspace \"$WS2\""
done

for id in $W2; do
  i3-msg "[con_id=$id] move to workspace \"$WS1\""
done
