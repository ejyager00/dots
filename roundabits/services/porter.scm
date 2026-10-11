;; ~/.dots/roundabits/services/porter.scm
;;;
;;; System glue for porter (github.com/ejyager00/porter), a greetd greeter
;;; and Wayland screen locker that share one look.
;;;
;;;   - porter-greetd-session: a greetd default-session command that runs a
;;;     bare sway whose only job is "porter greet; swaymsg exit".  porter
;;;     greet exits after greetd accepts start_session; sway then exits and
;;;     greetd starts the user's session.  If the greeter crashes, sway
;;;     exits too and greetd restarts the whole thing.
;;;
;;;   - porter-service-type: the "porter" PAM service for porter lock, plus
;;;     the greeter's directories.  porter lock checks passwords with PAM
;;;     as the locking user; pam_unix's setuid helper reads /etc/shadow, so
;;;     porter itself needs no setuid bit.
;;;
;;; Guix's own sway greeter wrapper (make-greetd-sway-greeter-command) is
;;; private and puts HOME and XDG_RUNTIME_DIR under a fixed /tmp path; this
;;; one uses directories created here, owned by the greeter user:
;;;
;;;   /var/lib/porter   HOME and porter's state dir (state.ini, greet.log,
;;;                     sway.log for the last greeter run)
;;;   /run/porter       XDG_RUNTIME_DIR (tmpfs, so no stale sockets)

(define-module (roundabits services porter)
  #:use-module (gnu packages wm)
  #:use-module (gnu services)
  #:use-module (gnu system pam)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (ejyager00 packages porter)
  #:export (porter-greetd-session
            porter-configuration
            porter-configuration?
            porter-service-type))

(define %greeter-user "greeter")         ;created by greetd-service-type
(define %state-directory "/var/lib/porter")
(define %runtime-directory "/run/porter")

(define* (porter-greetd-session config-file
                                #:key
                                (porter porter)
                                (sway sway)
                                (sway-configuration ""))
  "Return a program for greetd's default-session-command that runs porter
greet under sway.  CONFIG-FILE is porter's config (file-like);
SWAY-CONFIGURATION is extra sway config text, such as output modes."
  (let ((sway-config
         (mixed-text-file
          "porter-greeter-sway-config"
          sway-configuration "\n"
          "xwayland disable\n"
          "exec \"" porter "/bin/porter greet --config " config-file
          "; " sway "/bin/swaymsg exit\"\n")))
    (program-file
     "porter-greeter"
     #~(begin
         (setenv "HOME" #$%state-directory)
         (setenv "XDG_RUNTIME_DIR" #$%runtime-directory)
         ;; Keep only the last run's sway log; porter's own greet.log
         ;; is appended to.  A missing log must not stop the greeter.
         (let ((log (false-if-exception
                     (open-fdes #$(string-append %state-directory "/sway.log")
                                (logior O_CREAT O_WRONLY O_TRUNC) #o640))))
           (when log
             (dup2 log 1)
             (dup2 log 2)))
         (execl #$(file-append sway "/bin/sway")
                "sway" "-c" #$sway-config)))))

(define-record-type* <porter-configuration>
  porter-configuration make-porter-configuration
  porter-configuration?
  ;; Must match [lock] pam-service in porter's config (default "porter").
  (pam-service porter-configuration-pam-service (default "porter")))

(define (porter-pam-services config)
  (list (unix-pam-service (porter-configuration-pam-service config))))

(define (porter-activation config)
  (with-imported-modules '((guix build utils))
    #~(begin
        (use-modules (guix build utils))
        (let* ((user (getpwnam #$%greeter-user))
               (uid (passwd:uid user))
               (gid (passwd:gid user)))
          (for-each (lambda (directory mode)
                      (mkdir-p directory)
                      (chown directory uid gid)
                      (chmod directory mode))
                    '(#$%state-directory #$%runtime-directory)
                    '(#o755 #o700))))))

(define porter-service-type
  (service-type
   (name 'porter)
   (extensions
    (list (service-extension pam-root-service-type porter-pam-services)
          (service-extension activation-service-type porter-activation)))
   (default-value (porter-configuration))
   (description
    "Set up porter: the PAM service for @command{porter lock} and the
directories @command{porter greet} needs when run by greetd (use
@code{porter-greetd-session} as the greetd terminal's default session
command).")))
