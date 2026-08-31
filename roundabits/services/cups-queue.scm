;; ~/.dots/roundabits/services/cups-queue.scm
;;;
;;; Declarative CUPS print queues.
;;;
;;; CUPS keeps its queue definitions in /etc/cups/printers.conf, which cupsd
;;; owns and rewrites at runtime, so it cannot be a read-only store file the
;;; way most Guix configuration is.  Instead this service reconciles the
;;; declared queues at boot by invoking lpadmin, which makes sys-config.scm
;;; the source of truth even though the file it produces stays mutable.
;;;
;;; Why permanent queues are needed at all: CUPS 2.4 auto-creates *temporary*
;;; queues for DNS-SD driverless printers, and those are enough for lpstat and
;;; for GTK applications -- but Chromium (hence Brave) enumerates only
;;; permanent destinations, so a printer that works everywhere else is simply
;;; absent from its print dialog until a real queue exists.
;;;
;;; Reconciliation is deliberately non-fatal: a printer that is switched off or
;;; unplugged at boot should not leave a failed service behind, and an existing
;;; queue is left alone rather than re-queried on every boot.

(define-module (roundabits services cups-queue)
  #:use-module (gnu packages)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (srfi srfi-1)
  #:export (cups-queue
            cups-queue?
            cups-queue-name
            cups-queues-configuration
            cups-queues-configuration?
            cups-queues-service-type))

(define-record-type* <cups-queue>
  cups-queue make-cups-queue cups-queue?
  (name        cups-queue-name)
  (device-uri  cups-queue-device-uri)
  (model       cups-queue-model       (default "everywhere"))
  (description cups-queue-description (default #f))
  (location    cups-queue-location    (default #f))
  (default?    cups-queue-default?    (default #f)))

(define-record-type* <cups-queues-configuration>
  cups-queues-configuration make-cups-queues-configuration
  cups-queues-configuration?
  (cups     cups-queues-configuration-cups
            (default (specification->package "cups")))
  (queues   cups-queues-configuration-queues   (default '()))
  ;; How long to keep retrying lpadmin.  "-m everywhere" queries the device
  ;; live to build its PPD, and ipp-usb needs a moment after the daemon starts
  ;; before it is actually serving the printer on loopback.
  (retries  cups-queues-configuration-retries  (default 12))
  (delay    cups-queues-configuration-delay    (default 5)))

(define (cups-queues-script config)
  (let ((cups    (cups-queues-configuration-cups config))
        (queues  (cups-queues-configuration-queues config))
        (retries (cups-queues-configuration-retries config))
        (delay   (cups-queues-configuration-delay config)))
    (program-file
      "cups-ensure-queues"
      #~(begin
          (use-modules (ice-9 format))

          (define lpadmin #$(file-append cups "/sbin/lpadmin"))
          (define lpstat  #$(file-append cups "/bin/lpstat"))

          (define (queue-exists? name)
            ;; lpstat -p NAME exits non-zero for an unknown destination, and
            ;; chatters on both streams, so route them to /dev/null to keep the
            ;; boot log quiet.  Queue names come from this service's own
            ;; configuration, so they are trusted here.
            (zero? (system (string-append lpstat " -p " name
                                          " >/dev/null 2>&1"))))

          (define (try-add name args)
            (let loop ((n #$retries))
              (cond
                ((zero? (apply system* args))
                 (format #t "cups-queues: added ~a~%" name)
                 #t)
                ((<= n 1)
                 (format #t "cups-queues: giving up on ~a (device unreachable?)~%"
                         name)
                 #f)
                (else
                  (sleep #$delay)
                  (loop (- n 1))))))

          (for-each
            (lambda (spec)
              (let ((name (car spec))
                    (args (cadr spec))
                    (def? (caddr spec)))
                (if (queue-exists? name)
                    (format #t "cups-queues: ~a already present~%" name)
                    (try-add name args))
                (when (and def? (queue-exists? name))
                  (system* lpadmin "-d" name))))
            (list
              #$@(map
                   (lambda (q)
                     #~(list
                         #$(cups-queue-name q)
                         (list #$(file-append cups "/sbin/lpadmin")
                               "-p" #$(cups-queue-name q)
                               "-E"
                               "-v" #$(cups-queue-device-uri q)
                               "-m" #$(cups-queue-model q)
                               #$@(if (cups-queue-description q)
                                      #~("-D" #$(cups-queue-description q))
                                      #~())
                               #$@(if (cups-queue-location q)
                                      #~("-L" #$(cups-queue-location q))
                                      #~()))
                         #$(cups-queue-default? q)))
                   queues)))

          ;; Always succeed: an absent printer is not a boot failure.
          #t))))

(define (cups-queues-shepherd-service config)
  (list
    (shepherd-service
      (documentation "Reconcile declaratively-defined CUPS print queues.")
      (provision '(cups-queues))
      ;; ipp-usb must be up first, or the loopback device URI for a USB-only
      ;; printer will not answer and "-m everywhere" cannot build its PPD.
      (requirement '(cups ipp-usb))
      (one-shot? #t)
      (start
        #~(make-forkexec-constructor (list #$(cups-queues-script config))))
      (stop #~(make-kill-destructor)))))

(define cups-queues-service-type
  (service-type
    (name 'cups-queues)
    (extensions
      (list (service-extension shepherd-root-service-type
                               cups-queues-shepherd-service)))
    (default-value (cups-queues-configuration))
    (description
      "Ensure the declared CUPS print queues exist, by running
@command{lpadmin} once at boot after cupsd and ipp-usb are up.")))
