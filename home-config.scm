;; ~/.dots/home-config.scm
(use-modules (gnu home)
             (gnu home services)
             (gnu home services desktop)
             (gnu home services gnupg)
             (gnu home services shells)
             (gnu home services sound)
             (gnu packages)
             (gnu packages gnupg)
             (gnu services)
             (gnu system shadow)
             (guix gexp)
             (ejyager00 packages editors)
             (saayix packages terminals))

;;; Resolve binaries to absolute store paths so autostart never depends on
;;; PATH ordering between the system and home profiles.
(define (bin spec name)
  (file-append (specification->package spec) "/bin/" name))

(define %sway-autostart
  (mixed-text-file "sway-guix-autostart"
                   ;; Push the Wayland session into the D-Bus activation
                   ;; environment. home-dbus starts before sway, so activated
                   ;; services (portals) otherwise inherit an env with no
                   ;; WAYLAND_DISPLAY and fail. Must precede everything else.
                   "exec "
                   (bin "dbus" "dbus-update-activation-environment")
                   " WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP"
                   " XDG_SESSION_TYPE DISPLAY XAUTHORITY\n"
                   ;; Polkit authentication agent. Without this, anything invoking polkit
                   ;; (udisks mounts, NM system connections) fails with no visible prompt.
                   "exec "
                   (bin "lxqt-policykit" "lxqt-policykit-agent")
                   "\n"
                   ;; Notification daemon; D-Bus-activatable but exec'd so it inherits
                   ;; WAYLAND_DISPLAY at a predictable point.
                   "exec "
                   (bin "swaynotificationcenter" "swaync")
                   "\n"
                   ;; Declarative output management, keyed on EDID.
                   "exec "
                   (bin "kanshi" "kanshi")
                   "\n"
                   ;; Clipboard history. clipman consumes a single persistent
                   ;; wl-paste stream rather than spawning per selection event,
                   ;; which avoids the MIME-negotiation race that corrupts
                   ;; Firefox-family selections.
                   "exec "
                   (bin "wl-clipboard" "wl-paste")
                   " -t text --watch "
                   (bin "clipman" "clipman")
                   " store --no-persist\n"))

(home-environment
  (packages (append (list fresh-editor ghostty)
                    (specifications->packages (list "icecat"
                                               "git"
                                               "guile-lsp-server"
                                               "pinentry-qt"
                                               "jq"
                                               "swaylock-effects"
                                               "foot"
                                               "wmenu"
                                               ;; session utilities
                                               "playerctl"
                                               "wireplumber"
                                               "dbus"
                                               ;; session agents
                                               "lxqt-policykit"
                                               "swaynotificationcenter"
                                               ;; portals: -wlr does ScreenCast/Screenshot only,
                                               ;; -gtk supplies FileChooser/AppChooser/Settings
                                               "xdg-desktop-portal"
                                               "xdg-desktop-portal-wlr"
                                               "xdg-desktop-portal-gtk"
                                               ;; output management
                                               "kanshi"
                                               ;; screenshots and clipboard
                                               "grim"
                                               "slurp"
                                               "wl-clipboard"
                                               "clipman"
                                               ;; icon fallback chain
                                               "hicolor-icon-theme"
                                               "adwaita-icon-theme"
                                               "breeze-icons"
                                               ;; fonts
                                               "font-dejavu"
                                               "font-google-noto"
                                               "font-google-noto-emoji"
                                               "font-google-noto-sans-cjk"
                                               "font-liberation"
                                               "font-fira-code"))))

  (services
   (append (list (service home-dbus-service-type)
                 (service home-pipewire-service-type)

                 (service home-zsh-service-type
                          (home-zsh-configuration (zprofile (list (local-file
                                                                   "dotfiles/zsh/zprofile")))
                                                  (zshrc (list (local-file
                                                                "dotfiles/zsh/zshrc")
                                                               (local-file
                                                                "dotfiles/zsh/aliases.zsh")))))

                 (service home-files-service-type
                          `((".guile" ,%default-dotguile)
                            (".Xdefaults" ,%default-xdefaults)
                            (".local/bin/powermenu" ,(local-file
                                                      "dotfiles/powermenu.sh"
                                                      #:recursive? #t))
                            (".local/bin/gsfmt" ,(local-file "dotfiles/gsfmt"
                                                             #:recursive? #t))))

                 (service home-xdg-configuration-files-service-type
                          `(("gdb/gdbinit" ,%default-gdbinit)
                            ("nano/nanorc" ,%default-nanorc)
                            ("guix/channels.scm" ,(local-file "channels.scm"))
                            ("sway/config" ,(local-file "dotfiles/sway/config"))
                            ("sway/guix-autostart" ,%sway-autostart)
                            ("swaylock/config" ,(local-file
                                                 "dotfiles/swaylock/config"))
                            ("fresh/config.json" ,(local-file
                                                   "dotfiles/fresh/config.json"))
                            ("kanshi/config" ,(local-file
                                               "dotfiles/kanshi/config"))

                            ;; Portal backend routing. Generic filename is read for any
                            ;; XDG_CURRENT_DESKTOP, unlike sway-portals.conf.
                            ("xdg-desktop-portal/portals.conf" ,(plain-file
                                                                 "portals.conf"
                                                                 "[preferred]
default=gtk
org.freedesktop.impl.portal.ScreenCast=wlr
org.freedesktop.impl.portal.Screenshot=wlr
"))

                            ("xdg-desktop-portal-wlr/config" ,(plain-file
                                                               "wlr-portal-config"
                                                               "[screencast]
max_fps=60
chooser_type=simple
chooser_cmd=slurp -f %o -or
"))

                            ;; GTK3 reads this directly. Note: Adwaita-dark is not a real
                            ;; theme name post-GTK3.20 -- use Adwaita plus the prefer-dark flag.
                            ("gtk-3.0/settings.ini" ,(plain-file
                                                      "gtk3-settings"
                                                      "[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=breeze-dark
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-font-name=DejaVu Sans 10
gtk-application-prefer-dark-theme=1
gtk-enable-animations=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
"))

                            ;; GTK4/libadwaita ignores gtk-theme-name; icon, cursor, and
                            ;; font settings still apply.
                            ("gtk-4.0/settings.ini" ,(plain-file
                                                      "gtk4-settings"
                                                      "[Settings]
gtk-icon-theme-name=breeze-dark
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-font-name=DejaVu Sans 10
gtk-application-prefer-dark-theme=1
"))))

                 (simple-service 'my-env
                                 home-environment-variables-service-type
                                 `(("EDITOR" . "fresh") ("BROWSER" . "icecat")
                                   ("PATH" . "$PATH:$HOME/.local/bin")
                                   ;; Portals key off this; also what SwayNC and
                                   ;; xdg-desktop-portal-wlr use to identify the session.
                                   ("XDG_CURRENT_DESKTOP" . "sway")
                                   ("XDG_SESSION_TYPE" . "wayland")
                                   ;; Native Wayland where supported, X11 fallback.
                                   ("QT_QPA_PLATFORM" . "wayland;xcb")
                                   ("QT_WAYLAND_DISABLE_WINDOWDECORATION" . "1")
                                   ("GDK_BACKEND" . "wayland,x11")
                                   ("MOZ_ENABLE_WAYLAND" . "1")
                                   ("SDL_VIDEODRIVER" . "wayland")
                                   ;; Swing/AWT windows misbehave under non-reparenting
                                   ;; WMs without this.
                                   ("_JAVA_AWT_WM_NONREPARENTING" . "1")
                                   ;; Belt and braces: GTK_THEME overrides settings
                                   ;; resolution entirely, which matters because GTK4 may
                                   ;; prefer the Settings portal over settings.ini.
                                   ("GTK_THEME" . "Adwaita:dark")
                                   ("XCURSOR_THEME" . "Adwaita")
                                   ("XCURSOR_SIZE" . "24")))

                 (service home-gpg-agent-service-type
                          (home-gpg-agent-configuration (pinentry-program (file-append
                                                                           pinentry-qt
                                                                           "/bin/pinentry-qt"))
                                                        (ssh-support? #t)
                                                        (default-cache-ttl
                                                                           28800)
                                                        (max-cache-ttl 86400))))

           %base-home-services)))
