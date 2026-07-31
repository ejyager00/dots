;; ~/.dots/home-config.scm
(use-modules
  (gnu home)
  (gnu home services)
  (gnu home services desktop)
  (gnu home services gnupg)
  (gnu home services shells)
  (gnu home services sound)
  (gnu packages)
  (gnu packages gnupg)
  (gnu packages crypto)
  (gnu services)
  (gnu system shadow)
  (guix gexp)
  (ejyager00 home template)
  (ejyager00 packages editors)
  (ejyager00 packages brave)
  (px packages ai)
  (saayix packages terminals))

;;; Resolve binaries to absolute store paths so autostart never depends on
;;; PATH ordering between the system and home profiles.
(define
  (bin spec name)
  (file-append (specification->package spec) "/bin/" name))

(define %sway-autostart
  (substituted-file
   "sway-guix-autostart"
   (local-file "dotfiles/sway/guix-autostart.in")
   `(("dbus-update-activation-environment"
      . ,(bin "dbus" "dbus-update-activation-environment"))
     ("lxqt-policykit-agent" . ,(bin "lxqt-policykit" "lxqt-policykit-agent"))
     ("swaync"               . ,(bin "swaynotificationcenter" "swaync"))
     ("kanshi"               . ,(bin "kanshi" "kanshi"))
     ("wl-paste"             . ,(bin "wl-clipboard" "wl-paste"))
     ("clipman"              . ,(bin "clipman" "clipman")))))

(home-environment
  (packages
    (append
      (list brave-origin-bin fresh-editor claude-code ghostty)
      (specifications->packages
        (list
          "icecat"
          "git"
          "guile-lsp-server"
          "pinentry-qt"
          "keychain"
          "jq"
          "swaylock-effects"
          "foot"
          "wmenu"
          "gnupg"
          "playerctl"
          "wireplumber"
          "dbus"
          "lxqt-policykit"
          "swaynotificationcenter"
          "xdg-desktop-portal"
          "xdg-desktop-portal-wlr"
          "xdg-desktop-portal-gtk"
          "kanshi"
          "grim"
          "slurp"
          "wl-clipboard"
          "clipman"
          "hicolor-icon-theme"
          "adwaita-icon-theme"
          "breeze-icons"
          "font-dejavu"
          "font-google-noto"
          "font-google-noto-emoji"
          "font-google-noto-sans-cjk"
          "font-liberation"
          "font-fira-code"))))

  (services
    (append
      (list
        (service home-dbus-service-type)
        (service home-pipewire-service-type)
        (service
          home-zsh-service-type
          (home-zsh-configuration
            (zprofile (list (local-file "dotfiles/zsh/zprofile")))
            (zshrc
              (list
                (local-file "dotfiles/zsh/zshrc")
                (local-file "dotfiles/zsh/aliases.zsh")))))
        (service
          home-files-service-type
          `((".guile" ,%default-dotguile)
             (".Xdefaults" ,%default-xdefaults)
             (".local/bin/powermenu"
               ,(local-file "dotfiles/powermenu.sh" #:recursive? #t))
             (".local/bin/gsfmt"
               ,(local-file "dotfiles/gsfmt" #:recursive? #t))))
        (service
          home-xdg-configuration-files-service-type
          `(("gdb/gdbinit" ,%default-gdbinit)
             ("nano/nanorc" ,%default-nanorc)
             ("guix/channels.scm" ,(local-file "channels.scm"))
             ("sway/config" ,(local-file "dotfiles/sway/config"))
             ("sway/guix-autostart" ,%sway-autostart)
             ("swaylock/config" ,(local-file "dotfiles/swaylock/config"))
             ("fresh/config.json" ,(local-file "dotfiles/fresh/config.json"))
             ("git-config" ,(local-file "dotfiles/git/config"))
             ("kanshi/config" ,(local-file "dotfiles/kanshi/config"))
             ("xdg-desktop-portal/portals.conf"
               ,(local-file "dotfiles/xdg-desktop-portal/portals.conf"))
             ("xdg-desktop-portal-wlr/config"
               ,(local-file "dotfiles/xdg-desktop-portal/wlr-config"))
             ("gtk-3.0/settings.ini"
               ,(local-file "dotfiles/gtk/3.0-settings.ini"))
             ("gtk-4.0/settings.ini"
               ,(local-file "dotfiles/gtk/4.0-settings.ini"))))
        (simple-service
          'my-env
          home-environment-variables-service-type
          `(("EDITOR" . "fresh")
             ("BROWSER" . "brave-origin")
             ("PATH" . "$PATH:$HOME/.local/bin")
             ("XDG_CURRENT_DESKTOP" . "sway")
             ("XDG_SESSION_TYPE" . "wayland")
             ("QT_QPA_PLATFORM" . "wayland;xcb")
             ("QT_WAYLAND_DISABLE_WINDOWDECORATION" . "1")
             ("GDK_BACKEND" . "wayland,x11")
             ("MOZ_ENABLE_WAYLAND" . "1")
             ("SDL_VIDEODRIVER" . "wayland")
             ("_JAVA_AWT_WM_NONREPARENTING" . "1")
             ("GTK_THEME" . "Adwaita:dark")
             ("XCURSOR_THEME" . "Adwaita")
             ("XCURSOR_SIZE" . "24")))
        (service
          home-gpg-agent-service-type
          (home-gpg-agent-configuration
            (pinentry-program (file-append pinentry-qt "/bin/pinentry-qt"))
            (ssh-support? #t)
            (default-cache-ttl 28800)
            (max-cache-ttl 86400))))
      %base-home-services)))