;; ~/.dots/dotfiles/packages.scm
(define-module (dotfiles packages)
  #:use-module (gnu packages)
  #:export (%home-packages %jdk))

;;; Pinned to an LTS release rather than the bare "openjdk" spec, which always
;;; resolves to the newest JDK in the channel and would silently jump major
;;; versions on the next `guix pull'.  Exported so home-config.scm can point
;;; JAVA_HOME at this exact package instead of restating the version.
(define %jdk (specification->package "openjdk@21"))

(define %home-packages
  (append
    ;;; Guix splits openjdk into two outputs: `out' is only a JRE (java,
    ;;; keytool), while `jdk' is the full kit (javac, jar, jshell, jlink).
    ;;; Install `jdk' -- a JRE alone cannot compile anything.
    (list (list %jdk "jdk"))
    (specifications->packages
      (list
        ;; Browsers
        "icecat"
        "brave-origin-bin"

        ;; Editors & language tooling
        "fresh-editor"
        "micro"
        "guile-lsp-server"
        "claude-code"

        ;; Terminal emulators
        "ghostty"
        "foot"

        ;; Version control
        "git"
        "tig"
        "gh"

        ;; Build & language toolchains
        "make"
        "node"
        ;;; Apache's own distribution, from the saayix channel.  Guix's `maven'
        ;;; package is unusable for real projects: it pins the default lifecycle
        ;;; plugins to versions that do not exist on Maven Central (surefire
        ;;; "3.0.0-M4-M8"), and its bundled cglib/guice trip JDK 17+ module
        ;;; encapsulation before it even gets that far.
        "maven-bin"
        "glibc"
        "python"

        ;; CLI utilities
        "bat"
        "ripgrep"
        "jq"
        "curl"
        "socat"
        "ncurses"

        ;; Documents & notes
        "glow"
        "pandoc"
        "w3m"
        "nb"
        "anki"
        "direnv"
        "zathura"
        "zathura-pdf-poppler"
        "pdfarranger"

        ;; Security & secrets
        "gnupg"
        "pinentry-qt"
        "keychain"
        "password-store"

        ;; Sway/Wayland desktop
        "swaylock-effects"
        "wmenu"
        "kanshi"
        "swaynotificationcenter"
        "lxqt-policykit"
        "udiskie"
        "i3status-rust"

        ;; XDG desktop portals
        "xdg-desktop-portal"
        "xdg-desktop-portal-wlr"
        "xdg-desktop-portal-gtk"

        ;; Screenshots & clipboard
        "grim"
        "slurp"
        "wl-clipboard"
        "clipman"

        ;; Media & system services
        "ffmpeg"
        "playerctl"
        "wireplumber"
        "dbus"

        ;; Icon themes
        "hicolor-icon-theme"
        "adwaita-icon-theme"
        "breeze-icons"

        ;; Fonts
        "font-dejavu"
        "font-google-noto"
        "font-google-noto-emoji"
        "font-google-noto-sans-cjk"
        "font-liberation"
        "font-fira-code"
      
        ;; Messaging
        "telegram-desktop"

        ;; Flatpak
        "flatpak"

        ;; Desktop widgets
        "eww"
        "fastfetch"))))
