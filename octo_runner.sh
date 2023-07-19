#!/bin/sh

config_path=${1:-$IRSSI_CONFIG}

if [ -z "$config_path" ]; then
  echo "A config path is required. Either provide it as an argument or set the IRSSI_CONFIG environment variable."
  exit 1
fi

process_name="irssi --config $config_path"
screen_name="irc"

if pgrep -u "$USER" "$process_name" >/dev/null; then
  echo "$process_name is already running" && exit 0
else
  if ! screen -list | grep -q "$screen_name"; then
    screen -dmS "$screen_name"
  fi

  screen -S "$screen_name" -p 0 -X stuff "$process_name$(printf \\r)"

  echo "Started $process_name"
fi
