# .dots

Dotfiles and declarative configuration for my [GNU Guix System](https://guix.gnu.org/)
installation (`roundabits`): a `guix system` OS config, a `guix home`
environment, a `channels.scm`, and the plain-text dotfiles they reference via
`local-file`.

- `sys-config.scm` — the `operating-system` declaration (Sway session via
  SDDM, nonguix substitutes/kernel, filesystems, etc).
- `home-config.scm` — the `home-environment` declaration: packages, services,
  and where each dotfile under `dotfiles/` gets installed.
- `channels.scm` — symlinked to `~/.config/guix/channels.scm`, pins the
  channels these configs depend on.
- `dotfiles/` — the actual config files (sway, zsh, git, gtk, kanshi,
  swaylock, xdg-desktop-portal), installed verbatim or via `substituted-file`.

## Things that might be of interest to fellow Guix users

- **Store-path autostart, no PATH reliance.** The Sway autostart script is a
  template (`dotfiles/sway/guix-autostart.in`) substituted at build time via
  `substituted-file`, so binaries like `swaync`/`kanshi`/`dbus-*` resolve to
  absolute store paths instead of depending on PATH ordering between the
  system and home profiles.

## Usage

```sh
guix home reconfigure home-config.scm
sudo guix system reconfigure sys-config.scm
```
