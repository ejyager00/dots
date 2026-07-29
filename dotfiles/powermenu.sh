#!/bin/sh
# power menu for wmenu & sway
case "$(printf '%s\n' lock logout sleep reboot shutdown | wmenu -i -p power)" in
  lock)     swaylock ;;
  logout)   swaymsg exit ;;
  sleep)    swaylock -f; sleep 5; loginctl suspend ;;
  reboot)   loginctl reboot ;;
  shutdown) loginctl poweroff ;;
esac
