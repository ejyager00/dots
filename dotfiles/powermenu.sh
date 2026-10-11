#!/bin/sh
# power menu for wmenu & sway

nag() { swaynag -t error -m "powermenu: $1" >/dev/null 2>&1 & }

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
  logout)   run swaymsg exit ;;
  # porter lock -f returns once the lock is confirmed, so no sleep is
  # needed; swayidle's before-sleep hook would lock anyway.
  sleep)    run porter lock -f && run loginctl suspend ;;
  reboot)   watchdog reboot; run loginctl reboot ;;
  shutdown) watchdog poweroff; run loginctl poweroff ;;
esac
