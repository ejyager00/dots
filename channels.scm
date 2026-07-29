(list (channel
       (name 'nonguix)
       (url "https://gitlab.com/nonguix/nonguix")
       (branch "master")
       (introduction
        (make-channel-introduction
         "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
         (openpgp-fingerprint
          "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
      (channel
       (name 'guix)
       (url "https://git.guix.gnu.org/guix.git")
       (branch "master")
       (introduction
        (make-channel-introduction
         "9edb3f66fd807b096b48283debdcddccfea34bad"
         (openpgp-fingerprint
          "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))
      (channel
       (name 'ejyager00)
       (url "https://github.com/ejyager00/guix-channel")
       (branch "master")
       (introduction
        (make-channel-introduction
         "03dda62faab96a84d0fab61d46366d5b9cd8894f"
         (openpgp-fingerprint
          "1C96 9810 49FF 9A9D 0021  D960 A632 52C7 09EC BA81")))))
