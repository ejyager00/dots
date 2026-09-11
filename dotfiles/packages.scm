;; ~/.dots/dotfiles/packages.scm
(define-module (dotfiles packages)
  #:use-module (gnu packages)
  #:export (%home-packages %jdk))

(define %jdk (specification->package "openjdk@21"))

(define %home-packages
  (append
    (list (list %jdk "jdk"))
    (specifications->packages
      (list
        ;; Browsers
        "brave-origin-bin"

        ;; Editors & language tooling
        "fresh-editor"
        "micro"
        "guile-lsp-server"
        "claude-code"

        ;; Terminal emulators
        "ghostty"

        ;; Version control
        "git"
        "tig"
        "gh"

        ;; Build & language toolchains
        "make"
        "node"
        "maven-bin"
        "glibc"
        "python"
        "rust"
        "rust:cargo"
        "rust:tools"
        "rust:rust-src"
        ;; gcc-toolchain + pinned linux-libre-headers: needed as a `cc` for
        ;; building cargo-installed tools (e.g. zstd-sys wants linux/limits.h,
        ;; missing from glibc's own headers). Pin matches glibc's propagated
        ;; version to avoid a profile conflict.
        "gcc-toolchain"
        "linux-libre-headers@6.12.17"
        "zig"
        "just"
        "sqlite"

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
