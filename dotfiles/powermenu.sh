#!/bin/sh
# power menu for wmenu; works under any compositor that sets its IPC socket
# (sway: SWAYSOCK, niri: NIRI_SOCKET)

if [ -n "$SWAYSOCK" ]; then
  nag() { swaynag -t error -m "powermenu: $1" >/dev/null 2>&1 & }
  quit() { swaymsg exit; }
elif [ -n "$NIRI_SOCKET" ]; then
  nag() { notify-send -u critical powermenu "$1" >/dev/null 2>&1 & }
  quit() { niri msg action quit --skip-confirmation; }
else
  nag() { notify-send -u critical powermenu "$1" >/dev/null 2>&1 & }
  quit() { echo "no known compositor (SWAYSOCK/NIRI_SOCKET unset)" >&2; return 1; }
fi

# run a command, surfacing failure instead of discarding it. note that
# loginctl reports errors to syslog only -- it writes nothing to stdout
# or stderr -- so for those the exit code is all we get here.
run() {
  err="$("$@" 2>&1 >/dev/null)"; rc=$?
  [ "$rc" -ne 0 ] && nag "$* failed (exit $rc): ${err:-no output; see /var/log/messages}"
  return "$rc"
}

# loginctl also exits 0 while the action silently never happens (elogind
# wedging on a broken kexec path does exactly this), so the only reliable
# signal is that we are still alive long after the request was accepted
watchdog() { (sleep 15; nag "$1 was accepted but the system is still up; see /var/log/messages") & }

case "$(printf '%s\n' lock logout sleep reboot shutdown | wmenu -i -p power)" in
  lock)     run porter lock ;;
  logout)   run quit ;;
  # porter lock -f returns once the lock is confirmed, so no sleep is
  # needed; swayidle's before-sleep hook would lock anyway.
  sleep)    run porter lock -f && run loginctl suspend ;;
  reboot)   watchdog reboot; run loginctl reboot ;;
  shutdown) watchdog poweroff; run loginctl poweroff ;;
esac
