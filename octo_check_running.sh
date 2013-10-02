#!/bin/bash

# if irssi isnt running then check
# if a screen is running. if so, just run irssi in it
# otherwise make screen then run irssi in it

if ps -u octotrog | grep "[i]rssi" > /dev/null
then
	echo "already running"
else
	echo "..not running"
	if ! screen -list | grep -q "irc"; then
		echo "screen didn't exist"
		screen -dmS irc sh
	fi
	
	screen -S irc -p 0 -X stuff "irssi
	"

	echo "..running irssi"
fi
