;; ~/.dots/roundabits/services/ipp-usb.scm
;;;
;;; A Shepherd service for the ipp-usb daemon.
;;;
;;; Guix packages ipp-usb but ships no service type for it, so supervision
;;; lives here.  ipp-usb speaks IPP-over-USB to an AirPrint-class printer and
;;; re-exposes it as an ordinary IPP device on localhost, advertised over
;;; DNS-SD.  CUPS then drives it driverless ("everywhere"), which is how we
;;; avoid Brother's non-free LPR blobs entirely.
;;;
;;; Two details the upstream packaging leaves to the distro:
;;;
;;;   - The quirks directory is not installed by the Guix package.  Only
;;;     default.conf matters for a device with no model-specific quirk: it
;;;     strips the "Connection:" header, which some firmware mishandles.  It
;;;     is small enough to inline rather than depend on the source layout.
;;;
;;;   - The shipped udev rule tags matching devices for shepherd and hands
;;;     them to group "lp"; without it the daemon cannot claim the interface.

(define-module (roundabits services ipp-usb)
  #:use-module (gnu packages)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (gnu services base)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:export (ipp-usb-configuration
            ipp-usb-configuration?
            ipp-usb-configuration-package
            ipp-usb-configuration-state-directory
            ipp-usb-configuration-log-directory
            ipp-usb-service-type))

(define-record-type* <ipp-usb-configuration>
  ipp-usb-configuration
  make-ipp-usb-configuration
  ipp-usb-configuration?
  (package ipp-usb-configuration-package
           (default (specification->package "ipp-usb")))
  (state-directory ipp-usb-configuration-state-directory
                   (default "/var/ipp-usb"))
  (log-directory ipp-usb-configuration-log-directory
                 (default "/var/log/ipp-usb")))

(define %ipp-usb-default-quirks
  (plain-file "default.conf"
              "# ipp-usb quirks file -- defaults\n\n[*]\n  # Drop Connection: header by default\n  http-connection = \"\"\n"))

(define %ipp-usb-blacklist-quirks
  (plain-file "blacklist.conf"
              "# ipp-usb quirks file -- blacklisted devices\n\n[HP Inc. HP Laser MFP 135a]\n  blacklist = true\n\n[HP Inc. HP Laser 107a]\n  blacklist = true\n"))

(define %ipp-usb-conf
  ;; Bind only to loopback: the printer is ours, and exposing it to the LAN
  ;; would also break the IPP-over-USB requirement that Host: be "localhost".
  (plain-file "ipp-usb.conf"
              "[network]\n  interface = loopback\n\n[logging]\n  device-log = all\n  main-log   = all\n  console-log = error\n  max-file-size = 256K\n  max-backup-files = 2\n"))

(define (ipp-usb-etc config)
  (list `("ipp-usb"
          ,(file-union "ipp-usb"
                       `(("ipp-usb.conf" ,%ipp-usb-conf)
                         ("quirks/default.conf" ,%ipp-usb-default-quirks)
                         ("quirks/blacklist.conf" ,%ipp-usb-blacklist-quirks))))))

(define (ipp-usb-shepherd-service config)
  (let ((ipp-usb (ipp-usb-configuration-package config)))
    (list
      (shepherd-service
        (documentation "Run the ipp-usb daemon for IPP-over-USB printers.")
        (provision '(ipp-usb))
        ;; avahi-daemon is a hard requirement, not a nicety: ipp-usb registers
        ;; the device over DNS-SD, and that registration is how CUPS finds it.
        (requirement '(user-processes udev avahi-daemon))
        (start
          #~(make-forkexec-constructor
              (list #$(file-append ipp-usb "/bin/ipp-usb") "standalone")))
        (stop #~(make-kill-destructor))
        (respawn? #t)))))

(define (ipp-usb-activation config)
  (let ((state (ipp-usb-configuration-state-directory config))
        (log-dir (ipp-usb-configuration-log-directory config)))
    #~(begin
        (use-modules (guix build utils))
        (mkdir-p (string-append #$state "/dev"))
        (mkdir-p (string-append #$state "/lock"))
        (mkdir-p #$log-dir))))

(define (ipp-usb-udev-rules config)
  ;; The package ships lib/udev/rules.d/71-ipp-usb.rules, which matches the
  ;; 7/1/4 (printer/printer/IPP-USB) interface triple.
  (list (ipp-usb-configuration-package config)))

(define (ipp-usb-profile config)
  ;; Puts "ipp-usb check" and "ipp-usb status" on PATH for diagnosis.
  (list (ipp-usb-configuration-package config)))

(define ipp-usb-service-type
  (service-type
    (name 'ipp-usb)
    (extensions
      (list (service-extension shepherd-root-service-type
                               ipp-usb-shepherd-service)
            (service-extension activation-service-type
                               ipp-usb-activation)
            (service-extension etc-service-type
                               ipp-usb-etc)
            (service-extension udev-service-type
                               ipp-usb-udev-rules)
            (service-extension profile-service-type
                               ipp-usb-profile)))
    (default-value (ipp-usb-configuration))
    (description
      "Run @command{ipp-usb}, which exposes an IPP-over-USB (AirPrint) printer
as a local IPP device advertised over DNS-SD, enabling driverless printing and
eSCL scanning without vendor drivers.")))
