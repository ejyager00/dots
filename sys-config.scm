;; ~/.dots/sys-config.scm
;; Use the 'guix system reconfigure' command to effect your
;; changes.

;; Indicate which modules to import to access the variables
;; used in this configuration.
(use-modules (gnu)
             (nongnu packages linux)
             (nongnu system linux-initrd)
             (guix packages)
             (guix download)
             (gnu services sddm)
             (gnu packages shells))
(use-service-modules cups desktop networking ssh xorg)

(operating-system
  (locale "en_US.utf8")
  (timezone "America/Indiana/Indianapolis")
  (keyboard-layout (keyboard-layout "us"))
  (host-name "roundabits")

  (kernel linux)
  (initrd microcode-initrd)
  (firmware (list linux-firmware))

  ;; The list of user accounts ('root' is implicit).
  (users (cons* (user-account
                  (name "eric")
                  (comment "Eric Yager")
                  (group "users")
                  (home-directory "/home/eric")
                  (supplementary-groups '("wheel" "netdev" "audio" "video"))
                  (shell (file-append zsh "/bin/zsh"))) %base-user-accounts))

  ;; Packages installed system-wide.  Users can also install packages
  ;; under their own account: use 'guix search KEYWORD' to search
  ;; for packages and 'guix install PACKAGE' to install a package.
  (packages (append (list (specification->package "sway")) %base-packages))

  ;; Below is the list of system services.  To search for available
  ;; services, run 'guix system search KEYWORD' in a terminal.
  (services
   (append (list (service openssh-service-type)
                 (service cups-service-type)
                 (service sddm-service-type
                          (sddm-configuration (display-server "x11")
                                              (theme "maldives")
                                              (remember-last-user? #t)))
                 (set-xorg-configuration
                  (xorg-configuration (keyboard-layout keyboard-layout))
                  sddm-service-type)
                 (service screen-locker-service-type
                          (screen-locker-configuration (name "swaylock")
                                                       (program (file-append
                                                                 (specification->package "swaylock-effects")
                                                                 "/bin/swaylock"))
                                                       (using-pam? #t)
                                                       (using-setuid? #f))))
           (modify-services %desktop-services
             (delete gdm-service-type)
             (guix-service-type config =>
                                (guix-configuration (inherit config)
                                                    (substitute-urls (cons*
                                                                      "https://substitutes.nonguix.org"
                                                                      %default-substitute-urls))
                                                    (authorized-keys (cons* (origin
                                                                              
                                                                              
                                                                              (method
                                                                               url-fetch)

                                                                              
                                                                              (uri
                                                                               "https://substitutes.nonguix.org/signing-key.pub")

                                                                              
                                                                              (file-name
                                                                               "nonguix.pub")

                                                                              
                                                                              (sha256
                                                                               (base32
                                                                                "0j66nq1bxvbxf5n8q2py14sjbkn57my0mjwq7k1qm9ddghca7177")))
                                                                      %default-authorized-guix-keys)))))))
  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets (list "/boot/efi"))
                (keyboard-layout keyboard-layout)))

  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems (cons* (file-system
                         (mount-point "/home")
                         (device (uuid "7ba1bacc-8ea6-4822-ad1d-1d4a5166b096"
                                       'ext4))
                         (type "ext4"))
                       (file-system
                         (mount-point "/")
                         (device (uuid "fc9b45b7-b004-46af-a062-3eae624c3e1b"
                                       'ext4))
                         (type "ext4"))
                       (file-system
                         (mount-point "/boot/efi")
                         (device (uuid "1155-7188"
                                       'fat32))
                         (type "vfat")) %base-file-systems)))
