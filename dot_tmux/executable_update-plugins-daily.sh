#!/bin/sh
STAMP="$HOME/.cache/tmux_update_plugins.stamp"
NOW=$(date +%Y-%m-%d)

# if stamp doesn’t exist or is older than today → update
if [ ! -f "$STAMP" ] || [ "$(cat $STAMP)" != "$NOW" ]; then
  mkdir -p "$(dirname "$STAMP")"
  echo "$NOW" >"$STAMP"
  "$HOME/.tmux/plugins/tpm/bin/update_plugins" all >/dev/null 2>&1
fi
