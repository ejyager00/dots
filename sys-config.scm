;; ~/.dots/sys-config.scm
(use-modules
  (gnu)
  (nongnu packages linux)
  (nongnu system linux-initrd)
  (guix packages)
  (guix download)
  (guix gexp)
  (gnu packages shells)
  (ejyager00 packages regreet))

(use-service-modules cups desktop networking sound ssh xorg)

;; greetd + regreet, with sway as the throwaway kiosk compositor that hosts
;; the greeter (dropped in favor of cage per upstream's documented sway
;; deployment: https://github.com/rharish101/ReGreet -- sway is already
;; resident in the system closure for the real desktop session, so this
;; avoids pulling in a second, differently-pinned wlroots via cage).
;;
;; regreet's default reboot/poweroff commands shell out to systemctl, which
;; doesn't exist under Shepherd; point them at loginctl (elogind) instead.
;; theme_name is deliberately absent here: on this GTK version (4.22.1) it's
;; silently ignored (verified) -- the GTK_THEME env var in %regreet-command
;; below is what actually selects the theme.
(define %regreet-config
  (plain-file
    "regreet.toml"
    "[background]\n\
path = \"/home/eric/Images/backgrounds/running-animals.png\"\n\
fit = \"Contain\"\n\
\n\
[GTK]\n\
application_prefer_dark_theme = true\n\
cursor_theme_name = \"Adwaita\"\n\
cursor_blink = true\n\
font_name = \"Cantarell 16\"\n\
icon_theme_name = \"Adwaita\"\n\
\n\
[commands]\n\
reboot = [\"loginctl\", \"reboot\"]\n\
poweroff = [\"loginctl\", \"poweroff\"]\n\
\n\
[widget.clock]\n\
resolution = \"500ms\"\n\
label_width = 220\n"))

;; Custom stylesheet for regreet-guix's UI patch: the clock now lives in the
;; grid slot that used to hold the static greeting message (see the
;; regreet-guix package), and the error InfoBar's wrapping frame stays
;; mapped (just collapsed) once armed at startup, showing as a stray line
;; above the reboot/poweroff buttons unless stripped here.
(define %regreet-css
  (plain-file
    "regreet.css"
    ".greeting-clock label {\n\
  font-weight: bold;\n\
  font-size: 1.4em;\n\
}\n\
\n\
.info-frame {\n\
  border: none;\n\
  background: none;\n\
  box-shadow: none;\n\
  min-height: 0;\n\
}\n"))

;; Sway config for the greeter's throwaway compositor instance: run regreet,
;; then tear the compositor down when it exits (successful login or not --
;; greetd starts the real session separately once regreet hands off).
(define %regreet-sway-config
  (mixed-text-file
    "regreet-sway-config"
    "xwayland disable\n"
    "exec \""
    (file-append regreet-guix "/bin/regreet") " -c " %regreet-config
    " -s " %regreet-css
    "; "
    (file-append (specification->package "sway") "/bin/swaymsg") " exit"
    "\"\n"))

;; greetd's "greeter" account has no writable home or /var directories, so
;; carve out a scratch HOME under /tmp for regreet's cache/state/log dirs
;; (matching STATE_DIR/LOG_DIR baked into regreet-guix above) before execing
;; into a D-Bus session + sway, mirroring Guix's own (private, gtkgreet-only)
;; make-greetd-sway-greeter-command helper in (gnu services base).  The
;; D-Bus session wrapper matches upstream ReGreet's documented sway example.
(define %regreet-command
  (program-file
    "regreet-greeter-command"
    (with-imported-modules '((guix build utils))
      #~(begin
          (use-modules (guix build utils))

          (let* ((username (getenv "USER"))
                 (user (getpwnam username))
                 (useruid (passwd:uid user))
                 (usergid (passwd:gid user))
                 (user-home-dir "/tmp/.greeter-home")
                 (user-xdg-runtime-dir (string-append user-home-dir "/run"))
                 (user-xdg-cache-dir (string-append user-home-dir "/cache"))
                 (user-state-dir (string-append user-home-dir "/state"))
                 (user-log-dir (string-append user-home-dir "/log"))
                 (log-file
                   (string-append user-home-dir "/"
                                  (number->string (getpid)) ".log")))
            (for-each (lambda (d)
                        (mkdir-p d)
                        (chown d useruid usergid) (chmod d #o700))
                      (list user-home-dir
                            user-xdg-runtime-dir
                            user-xdg-cache-dir
                            user-state-dir
                            user-log-dir))
            (setenv "HOME" user-home-dir)
            (setenv "XDG_CACHE_HOME" user-xdg-cache-dir)
            (setenv "XDG_CACHE_DIR" user-xdg-cache-dir)
            (setenv "XDG_RUNTIME_DIR" user-xdg-runtime-dir)
            ;; GTK (4.22.1) silently ignores regreet.toml's theme_name --
            ;; GTK_THEME is the only thing that actually switches the theme
            ;; (verified). XDG_DATA_DIRS needs the system profile explicitly
            ;; since this process execs straight into sway with no shell/
            ;; profile sourcing to set it, and orchis-theme is installed
            ;; there (see the system packages list).
            (setenv "GTK_THEME" "Orchis-Dark")
            (setenv "XDG_DATA_DIRS" "/run/current-system/profile/share")
            (dup2 (open-fdes log-file
                             (logior O_CREAT O_WRONLY O_APPEND) #o640) 1)
            (dup2 1 2)
            (execl #$(file-append (specification->package "dbus") "/bin/dbus-run-session")
                   "dbus-run-session" "--"
                   #$(file-append (specification->package "sway") "/bin/sway")
                   "-d" "-c" #$%regreet-sway-config))))))

(operating-system
  (locale "en_US.utf8")
  (timezone "America/Indiana/Indianapolis")
  (keyboard-layout (keyboard-layout "us"))
  (host-name "roundabits")

  (kernel linux)
  (kernel-arguments (append '("sysrq_always_enabled=1" "loglevel=8" "ignore_loglevel") %default-kernel-arguments))
  (initrd microcode-initrd)
  (firmware (list linux-firmware))

  ;; The list of user accounts ('root' is implicit).
  (users
    (cons*
      (user-account
        (name "eric")
        (comment "Eric Yager")
        (group "users")
        (home-directory "/home/eric")
        (supplementary-groups '("wheel" "netdev" "audio" "video"))
        (shell (file-append zsh "/bin/zsh")))
      %base-user-accounts))

  ;; Packages installed system-wide.  Users can also install packages
  ;; under their own account: use 'guix search KEYWORD' to search
  ;; for packages and 'guix install PACKAGE' to install a package.
  (packages
    (append
      (list
        (specification->package "sway")
        (specification->package "orchis-theme"))
      %base-packages))

  ;; Below is the list of system services.  To search for available
  ;; services, run 'guix system search KEYWORD' in a terminal.
  (services
    (append
      (list
        (service openssh-service-type)
        (service cups-service-type)
        (service
          greetd-service-type
          (greetd-configuration
            (terminals
              (list
                (greetd-terminal-configuration
                  (terminal-vt "7")
                  (terminal-switch #t)
                  (default-session-command %regreet-command))))))
        (service
          screen-locker-service-type
          (screen-locker-configuration
            (name "swaylock")
            (program
              (file-append
                (specification->package "swaylock-effects")
                "/bin/swaylock"))
            (using-pam? #t)
            (using-setuid? #f)))
            (udev-rules-service
              'steam-devices
              (specification->package "steam-devices-udev-rules")))
      (modify-services
        %desktop-services
        (delete gdm-service-type)
        (delete pulseaudio-service-type)
        (guix-service-type
          config
          =>
          (guix-configuration
            (inherit config)
            (substitute-urls
              (cons*
                "https://substitutes.nonguix.org"
                %default-substitute-urls))
            (authorized-keys
              (cons*
                (origin
                  (method url-fetch)
                  (uri "https://substitutes.nonguix.org/signing-key.pub")
                  (file-name "nonguix.pub")
                  (sha256
                    (base32
                      "0j66nq1bxvbxf5n8q2py14sjbkn57my0mjwq7k1qm9ddghca7177")))
                %default-authorized-guix-keys)))))))
                
  (bootloader
    (bootloader-configuration
      (bootloader grub-efi-bootloader)
      (targets (list "/boot/efi"))
      (keyboard-layout keyboard-layout)))

  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems
    (cons*
      (file-system
        (mount-point "/home")
        (device (uuid "7ba1bacc-8ea6-4822-ad1d-1d4a5166b096" 'ext4))
        (type "ext4"))
      (file-system
        (mount-point "/")
        (device (uuid "fc9b45b7-b004-46af-a062-3eae624c3e1b" 'ext4))
        (type "ext4"))
      (file-system
        (mount-point "/boot/efi")
        (device (uuid "1155-7188" 'fat32))
        (type "vfat"))
      (file-system
        (device (uuid "b76942b3-7e55-4750-b153-e2c203104b62" 'ext4))
        (mount-point "/mnt/ssd1")
        (type "ext4"))
      %base-file-systems)))
