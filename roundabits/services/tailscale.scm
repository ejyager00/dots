;; ~/.dots/roundabits/services/tailscale.scm
;;;
;;; A Shepherd service for the Tailscale daemon.
;;;
;;; The 'panther' channel ships a tailscale-service-type of its own, but its
;;; shepherd service requires only 'user-processes (so tailscaled races the
;;; network at boot), writes no log, and hands the daemon no PATH -- which
;;; makes its ip/iptables netfilter setup fail quietly.  This one fixes all
;;; three, and keeps daemon supervision independent of that channel's pin.
;;;
;;; The tailscale/tailscaled *packages* still come from panther; only the
;;; supervision lives here.

(define-module (roundabits services tailscale)
  #:use-module (gnu packages)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:export (tailscale-configuration
            tailscale-configuration?
            tailscale-configuration-package
            tailscale-configuration-port
            tailscale-configuration-state-directory
            tailscale-configuration-runtime-directory
            tailscale-configuration-log-file
            tailscale-configuration-extra-options
            tailscale-service-type))

(define-record-type* <tailscale-configuration>
  tailscale-configuration
  make-tailscale-configuration
  tailscale-configuration?
  (package tailscale-configuration-package
           (default (specification->package "tailscaled")))
  (client tailscale-configuration-client
          (default (specification->package "tailscale")))
  (port tailscale-configuration-port (default 41641))
  (state-directory tailscale-configuration-state-directory
                   (default "/var/lib/tailscale"))
  (runtime-directory tailscale-configuration-runtime-directory
                     (default "/var/run/tailscale"))
  (log-file tailscale-configuration-log-file
            (default "/var/log/tailscaled.log"))
  (extra-options tailscale-configuration-extra-options (default '())))

(define (tailscale-shepherd-service config)
  (let ((tailscaled (tailscale-configuration-package config))
        (state (tailscale-configuration-state-directory config))
        (runtime (tailscale-configuration-runtime-directory config))
        (log-file (tailscale-configuration-log-file config))
        (port (tailscale-configuration-port config))
        (extra-options (tailscale-configuration-extra-options config)))
    (list
      (shepherd-service
        (documentation "Run the Tailscale daemon.")
        (provision '(tailscaled))
        (requirement '(user-processes networking))
        (start
          #~(make-forkexec-constructor
              (list #$(file-append tailscaled "/bin/tailscaled")
                    (string-append "--state=" #$state "/tailscaled.state")
                    (string-append "--statedir=" #$state)
                    (string-append "--socket=" #$runtime "/tailscaled.sock")
                    #$(string-append "--port=" (number->string port))
                    #$@extra-options)
              #:log-file #$log-file
              ;; tailscaled shells out to 'ip' and 'iptables'/'nft' to install
              ;; its netfilter rules; without these on PATH it starts, but the
              ;; packet filter, subnet routes and exit-node support misbehave
              ;; quietly.
              #:environment-variables
              (cons*
                (string-append
                  "PATH="
                  #$(file-append (specification->package "iproute2") "/sbin")
                  ":"
                  #$(file-append (specification->package "iptables") "/sbin")
                  ":"
                  #$(file-append (specification->package "nftables") "/sbin"))
                (default-environment-variables))))
        (stop #~(make-kill-destructor))))))

(define (tailscale-activation config)
  (let ((state (tailscale-configuration-state-directory config))
        (runtime (tailscale-configuration-runtime-directory config)))
    #~(begin
        (use-modules (guix build utils))
        ;; /var/run is repopulated at boot, so the socket directory has to be
        ;; recreated every time; the state directory holds the node key.
        (mkdir-p #$runtime)
        (mkdir-p #$state)
        (chmod #$state #o700))))

(define (tailscale-profile config)
  (list (tailscale-configuration-client config)))

(define tailscale-service-type
  (service-type
    (name 'tailscale)
    (extensions
      (list (service-extension
              shepherd-root-service-type
              tailscale-shepherd-service)
            (service-extension
              activation-service-type
              tailscale-activation)
            (service-extension profile-service-type tailscale-profile)))
    (default-value (tailscale-configuration))
    (description
      "Run @command{tailscaled}, the Tailscale daemon, and install the
@command{tailscale} client in the system profile.  Joining a tailnet still
requires running @command{tailscale up} by hand, since it needs interactive
browser authentication.")))
