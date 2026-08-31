;; ~/.dots/sys-config.scm

;; Put this file's own directory on the load path so the (roundabits ...)
;; modules alongside it are importable without passing -L to every guix
;; command.
(add-to-load-path (dirname (current-filename)))

(use-modules
  (gnu)
  (nongnu packages linux)
  (nongnu system linux-initrd)
  (guix packages)
  (guix download)
  (guix gexp)
  (gnu packages shells)
  (roundabits services cups-queue)
  (roundabits services ipp-usb)
  (roundabits services tailscale))

(use-service-modules cups desktop networking sound ssh xorg)

(define %gtkgreet-background
  (local-file "/home/eric/Images/backgrounds/library.jpg"))

(define %gtkgreet-css
  (mixed-text-file
    "gtkgreet.css"
    "window {\n"
    "  background-image: url(\"file://" %gtkgreet-background "\");\n"
    "  background-size: cover;\n"
    "  background-position: center;\n"
    "}\n"
    "\n"
    "#clock {\n"
    "  color: white;\n"
    "  text-shadow: 0px 1px 4px rgba(0, 0, 0, 0.8);\n"
    "}\n"
    "\n"
    "#body {\n"
    "  background-color: rgba(50, 50, 50, 0.5);\n"
    "  border-radius: 10px;\n"
    "  padding: 20px"
    "}\n"
    "\n"
    "#body label {\n"
    "  color: white;\n"
    "}\n"
    "\n"
    ;; Cancel button
    "#body button:nth-last-child(2) {\n"
    "  background-image: none;\n"
    "  background-color: #e01b24;\n"
    "}\n"))

(operating-system
  (locale "en_US.utf8")
  (timezone "America/Indiana/Indianapolis")
  (keyboard-layout (keyboard-layout "us"))
  (host-name "roundabits")

  (kernel linux)
  (kernel-arguments (append '("sysrq_always_enabled=1" "loglevel=8" "ignore_loglevel") %default-kernel-arguments))
  (initrd microcode-initrd)
  (firmware (list linux-firmware))

  ;; The list of user accounts ('root' is implicit).
  (users
    (cons*
      (user-account
        (name "eric")
        (comment "Eric Yager")
        (group "users")
        (home-directory "/home/eric")
        (supplementary-groups '("wheel" "netdev" "audio" "video" "lp" "lpadmin"))
        (shell (file-append zsh "/bin/zsh")))
      %base-user-accounts))

  ;; Packages installed system-wide.  Users can also install packages
  ;; under their own account: use 'guix search KEYWORD' to search
  ;; for packages and 'guix install PACKAGE' to install a package.
  (packages
    (append
      (list (specification->package "sway")
            ;; cups-service-type runs cupsd but extends no profile, so the
            ;; client tools (lpstat, lpadmin, lpinfo, lp) come from here.
            (specification->package "cups"))
      %base-packages))

  ;; Below is the list of system services.  To search for available
  ;; services, run 'guix system search KEYWORD' in a terminal.
  (services
    (append
      (list
        (service openssh-service-type)
        ;; web-interface? defaults to #f in Guix, which is why localhost:631
        ;; serves nothing and there is no way to add a printer from a browser.
        (service cups-service-type
                 (cups-configuration
                   (web-interface? #t)))
        (service ipp-usb-service-type)
        ;; Chromium/Brave lists only permanent CUPS destinations, not the
        ;; temporary queues CUPS auto-creates for discovered DNS-SD printers,
        ;; so the Brother needs a real queue to show up in its print dialog.
        ;; The loopback URI is ipp-usb's; port 60000 is persisted per device
        ;; serial under /var/ipp-usb/dev, so it is stable across replugs.
        ;; Addressing it directly also avoids CUPS's dnssd backend collapsing
        ;; the USB and WiFi adverts, which share a UUID, onto the WiFi one.
        (service cups-queues-service-type
                 (cups-queues-configuration
                   (queues
                     (list
                       (cups-queue
                         (name "Brother-MFC-J1010DW")
                         (device-uri "ipp://localhost:60000/ipp/print")
                         (description "Brother MFC-J1010DW (USB, driverless)")
                         (location "roundabits")
                         (default? #t))))))
        (service
          greetd-service-type
          (greetd-configuration
            (terminals
              (list
                (greetd-terminal-configuration
                  (terminal-vt "7")
                  (terminal-switch #t)
                  (default-session-command
                    (greetd-gtkgreet-sway-session
                      (command "sway")
                      (gtkgreet-style %gtkgreet-css))))))))
        (service
          screen-locker-service-type
          (screen-locker-configuration
            (name "swaylock")
            (program
              (file-append
                (specification->package "swaylock-effects")
                "/bin/swaylock"))
            (using-pam? #t)
            (using-setuid? #f)))
            (udev-rules-service
              'steam-devices
              (specification->package "steam-devices-udev-rules"))
        (service tailscale-service-type))
      (modify-services
        %desktop-services
        (delete gdm-service-type)
        (delete pulseaudio-service-type)
        (guix-service-type
          config
          =>
          (guix-configuration
            (inherit config)
            (substitute-urls
              (cons*
                "https://substitutes.nonguix.org"
                %default-substitute-urls))
            (authorized-keys
              (cons*
                (origin
                  (method url-fetch)
                  (uri "https://substitutes.nonguix.org/signing-key.pub")
                  (file-name "nonguix.pub")
                  (sha256
                    (base32
                      "0j66nq1bxvbxf5n8q2py14sjbkn57my0mjwq7k1qm9ddghca7177")))
                %default-authorized-guix-keys)))))))
                
  (bootloader
    (bootloader-configuration
      (bootloader grub-efi-bootloader)
      (targets (list "/boot/efi"))
      (keyboard-layout keyboard-layout)))

  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems
    (cons*
      (file-system
        (mount-point "/home")
        (device (uuid "7ba1bacc-8ea6-4822-ad1d-1d4a5166b096" 'ext4))
        (type "ext4"))
      (file-system
        (mount-point "/")
        (device (uuid "fc9b45b7-b004-46af-a062-3eae624c3e1b" 'ext4))
        (type "ext4"))
      (file-system
        (mount-point "/boot/efi")
        (device (uuid "1155-7188" 'fat32))
        (type "vfat"))
      (file-system
        (device (uuid "b76942b3-7e55-4750-b153-e2c203104b62" 'ext4))
        (mount-point "/mnt/ssd1")
        (type "ext4"))
      %base-file-systems)))
