;; ~/.dots/home-config.scm
(eval-when (expand load eval)
  (add-to-load-path (dirname (current-filename))))

(use-modules
  (gnu home)
  (gnu home services)
  (gnu home services desktop)
  (gnu home services gnupg)
  (gnu home services shells)
  (gnu home services shepherd)
  (gnu home services sound)
  (gnu home services ssh)
  (gnu packages)
  (gnu packages gnupg)
  (gnu services)
  (gnu services shepherd)
  (gnu system shadow)
  (guix gexp)
  (ejyager00 home template)
  (dotfiles packages))

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
     ("clipman"              . ,(bin "clipman" "clipman"))
     ("udiskie"              . ,(bin "udiskie" "udiskie"))
     ("eww"                  . ,(bin "eww" "eww")))))

(define %eww-yuck
  (substituted-file
   "eww-yuck"
   (local-file "dotfiles/eww/eww.yuck.in")
   `(("fastfetch" . ,(bin "fastfetch" "fastfetch"))
     ("python3"   . ,(bin "python" "python3"))
     ("ansi2pango" . ,(local-file "dotfiles/eww/ansi2pango.py")))))

(home-environment
  (packages %home-packages)

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
               ,(local-file "dotfiles/gsfmt" #:recursive? #t))
             (".cups/lpoptions" ,(local-file "dotfiles/cups/lpoptions"))
             (".local/bin/steam-flatpak"
               ,(program-file "steam-flatpak"
                 #~(execl "/bin/sh" "sh" "-c"
                          "exec flatpak run com.valvesoftware.Steam \"$@\"")))))
        (service
          home-xdg-configuration-files-service-type
          `(("gdb/gdbinit" ,%default-gdbinit)
             ("nano/nanorc" ,%default-nanorc)
             ("guix/channels.scm" ,(local-file "channels.scm"))
             ("sway/config" ,(local-file "dotfiles/sway/config"))
             ("sway/guix-autostart" ,%sway-autostart)
             ("eww/eww.yuck" ,%eww-yuck)
             ("eww/eww.scss" ,(local-file "dotfiles/eww/eww.scss"))
             ("swaylock/config" ,(local-file "dotfiles/swaylock/config"))
             ("fresh/config.json" ,(local-file "dotfiles/fresh/config.json"))
             ("git/config" ,(local-file "dotfiles/git/config"))
             ("kanshi/config" ,(local-file "dotfiles/kanshi/config"))
             ("i3status-rust/config.toml"
               ,(local-file "dotfiles/i3status-rust/config.toml"))
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
             ("NB_BROWSER" . "w3m")
             ("PATH" . "$PATH:$HOME/.local/bin")
             ("XDG_CURRENT_DESKTOP" . "sway")
             ("XDG_SESSION_TYPE" . "wayland")
             ("TMPDIR" . "/tmp")
             ("JAVA_HOME" . ,#~(ungexp %jdk "jdk"))
             ("SSH_AUTH_SOCK" . "$XDG_RUNTIME_DIR/ssh-agent.sock")
             ("QT_QPA_PLATFORM" . "wayland;xcb")
             ("QT_WAYLAND_DISABLE_WINDOWDECORATION" . "1")
             ("GDK_BACKEND" . "wayland,x11")
             ("MOZ_ENABLE_WAYLAND" . "1")
             ("SDL_VIDEODRIVER" . "wayland")
             ("_JAVA_AWT_WM_NONREPARENTING" . "1")
             ("GTK_THEME" . "Adwaita:dark")
             ("XCURSOR_THEME" . "Adwaita")
             ("XCURSOR_SIZE" . "24")
             ("XDG_DATA_DIRS" . "$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:$XDG_DATA_DIRS")))
        (service
          home-openssh-service-type
          (home-openssh-configuration
            (hosts
              (list
                (openssh-host
                  (name "asahihome")
                  (user "eric")
                  (identity-file "~/.ssh/id_ed25519")
                  (control-master 'auto)
                  (control-file-name "~/.ssh/cm-%C")
                  (control-persist "10m"))
                ;;; Forgejo's built-in SSH server.  It is published straight
                ;;; on the tailnet address, not through Caddy -- Caddy only
                ;;; fronts HTTPS (git.ericbits.win -> forgejo:3000).  Port
                ;;; 2222 matches SSH_PORT in Forgejo's app.ini, so the name
                ;;; here lets the short git@host:owner/repo form work.
                (openssh-host
                  (name "git.ericbits.win")
                  (user "git")
                  (port 2222)
                  (identity-file "~/.ssh/id_ed25519"))))))
        (simple-service
          'ssh-agent
          home-shepherd-service-type
          (list
            (shepherd-service
              (provision '(ssh-agent))
              (documentation "Run ssh-agent on a fixed socket path.")
              (modules '((shepherd support)))   ;for '%user-runtime-dir'
              (start
                #~(lambda args
                    (let ((socket (string-append %user-runtime-dir
                                                 "/ssh-agent.sock")))
                      ;;; ssh-agent refuses to bind over an existing file, so
                      ;;; clear the socket a previous generation left behind.
                      (false-if-exception (delete-file socket))
                      (apply (make-forkexec-constructor
                               (list #$(bin "openssh" "ssh-agent")
                                     "-D" "-a" socket))
                             args))))
              (stop #~(make-kill-destructor))
              (respawn? #t))))
        ;;; ssh-support? must stay #f.
        (service
          home-gpg-agent-service-type
          (home-gpg-agent-configuration
            (pinentry-program (file-append pinentry-qt "/bin/pinentry-qt"))
            (ssh-support? #f)
            (default-cache-ttl 28800)
            (max-cache-ttl 86400))))
      %base-home-services)))