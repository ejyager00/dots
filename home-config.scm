;; ~/.dots/home-config.scm
(define-module (home-configuration)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (gnu services)
  #:use-module (gnu system shadow)
  #:use-module (gnu packages)
  #:use-module (guix gexp))

(define home-config
  (home-environment
    (packages
     (specifications->packages
      (list "icecat"
            "git")))

    (services
      (append
        (list
          (service home-zsh-service-type
           (home-zsh-configuration
            (zprofile
             (list (local-file "dotfiles/zsh/zprofile-extra")))))

          (service home-files-service-type
           `((".guile" ,%default-dotguile)
             (".Xdefaults" ,%default-xdefaults)
             (".local/bin/powermenu", (local-file "dotfiles/powermenu.sh" #:recursive? #t))))

          (service home-xdg-configuration-files-service-type
           `(("gdb/gdbinit" ,%default-gdbinit)
             ("nano/nanorc" ,%default-nanorc)
             ("guix/channels.scm" ,(local-file "channels.scm"))
             ("sway/config" ,(local-file "dotfiles/sway/config"))
             ("swaylock/config", (local-file "dotfiles/swaylock/config")))))

        %base-home-services))))

;; Return value: reconfigure takes the last top-level expression.
home-config
