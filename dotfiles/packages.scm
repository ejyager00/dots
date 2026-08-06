;; ~/.dots/dotfiles/packages.scm
(define-module (dotfiles packages)
  #:use-module (gnu packages)
  #:export (%home-packages))

(define %home-packages
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
      
      ;; Flatpak
      "flatpak")))
