;; ~/.dots/dotfiles/porter.scm
;;; porter's config file, shared by sys-config (the greeter) and home-config
;;; (the locker) so both screens look the same.
(define-module (dotfiles porter)
  #:use-module (guix gexp)
  #:use-module (ejyager00 home template)
  #:export (%porter-config))

;;; In the store, so the greeter user can read it; it can't read /home/eric.
(define %porter-background
  (local-file "/home/eric/Images/backgrounds/library.jpg"))

(define %porter-config
  (substituted-file
   "porter.ini"
   (local-file "porter/porter.ini.in")
   `(("background" . ,%porter-background))))
