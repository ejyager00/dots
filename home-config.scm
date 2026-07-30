;; ~/.dots/home-config.scm
(use-modules (gnu home)
             (gnu home services)
             (gnu home services shells)
             (gnu services)
             (gnu system shadow)
             (gnu packages)
             (guix gexp)
             (gnu home services gnupg)
             (gnu packages gnupg)
             (ejyager00 packages editors)
             (saayix packages terminals))

(home-environment
  (packages (append (list fresh-editor ghostty)
                    (specifications->packages (list "icecat" "git"
                                                    "guile-lsp-server"
                                                    "pinentry-qt" "jq" "swaylock-effects" "foot" "wmenu"))))

  (services
   (append (list (service home-zsh-service-type
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
                                                      #:recursive? #t))))

                 (service home-xdg-configuration-files-service-type
                          `(("gdb/gdbinit" ,%default-gdbinit)
                            ("nano/nanorc" ,%default-nanorc)
                            ("guix/channels.scm" ,(local-file "channels.scm"))
                            ("sway/config" ,(local-file "dotfiles/sway/config"))
                            ("swaylock/config" ,(local-file
                                                 "dotfiles/swaylock/config"))
                            ("fresh/config.json", (local-file "dotfiles/fresh/config.json"))))

                 (simple-service 'my-env
                                 home-environment-variables-service-type
                                 `(("EDITOR" . "fresh") ("BROWSER" . "icecat")
                                   ("PATH" . "$PATH:$HOME/.local/bin")))

                 (service home-gpg-agent-service-type
                          (home-gpg-agent-configuration (pinentry-program (file-append
                                                                           pinentry-qt
                                                                           "/bin/pinentry-qt"))
                                                        (ssh-support? #t)
                                                        (default-cache-ttl
                                                                           28800)
                                                        (max-cache-ttl 86400))))

           %base-home-services)))
