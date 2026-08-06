#!/bin/sh
# List available commits
# flatpak --user remote-info --log flathub com.valvesoftware.Steam
# Choose one, then
# flatpak --user mask --remove com.valvesoftware.Steam
# flatpak --user update -y --commit=NEW_HASH com.valvesoftware.Steam
# flatpak --user mask com.valvesoftware.Steam
set -eu
STEAM_COMMIT="1ea2cc62d5d76d9122fb2980b3829555b8f5076a67a6bcd42c4a6f6becd33390"

flatpak --user remote-add --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo
flatpak --user install -y --noninteractive flathub com.valvesoftware.Steam
flatpak --user update -y --commit="$STEAM_COMMIT" com.valvesoftware.Steam
flatpak --user mask com.valvesoftware.Steam
flatpak override --user --filesystem=/mnt/ssd1 com.valvesoftware.Steam
flatpak override --user \
  --filesystem=/run/current-system/profile/share/fonts:ro \
  com.valvesoftware.Steam