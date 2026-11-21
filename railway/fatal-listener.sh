#!/bin/sh
# supervisord event listener: on the first PROCESS_STATE_FATAL, stop supervisord.
printf 'READY\n'
read -r header
echo "linkace: a process failed for good ($header); stopping the container" >&2
touch /tmp/linkace-fatal
kill -TERM "$(cat /tmp/supervisord.pid)"
sleep 30
