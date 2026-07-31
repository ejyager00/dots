(list
  (channel
    (name 'guix)
    (url "git@codeberg.org:guix/guix.git")
    (branch "master")
    (introduction
      (make-channel-introduction
        "9edb3f66fd807b096b48283debdcddccfea34bad"
        (openpgp-fingerprint
          "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))
  (channel
    (name 'nonguix)
    (url "https://gitlab.com/nonguix/nonguix")
    (branch "master")
    (introduction
      (make-channel-introduction
        "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
        (openpgp-fingerprint
          "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
  (channel
    (name 'ejyager00)
    (url "https://github.com/ejyager00/guix-channel")
    (branch "master")
    (introduction
      (make-channel-introduction
        "03dda62faab96a84d0fab61d46366d5b9cd8894f"
        (openpgp-fingerprint
          "1C96 9810 49FF 9A9D 0021  D960 A632 52C7 09EC BA81"))))
  (channel
    (name 'saayix)
    (branch "main")
    (commit "1383e5e465b82cf8d82e31d43c9477c8d1265692")
    (url "https://codeberg.org/look/saayix")
    (introduction
      (make-channel-introduction
        "12540f593092e9a177eb8a974a57bb4892327752"
        (openpgp-fingerprint
          "3FFA 7335 973E 0A49 47FC  0A8C 38D5 96BE 07D3 34AB"))))
  (channel
    (name 'panther)
    (url "git@codeberg.org:gofranz/panther.git")
    (branch "master")
    (introduction
      (make-channel-introduction
        "54b4056ac571611892c743b65f4c47dc298c49da"
        (openpgp-fingerprint
          "A36A D41E ECC7 A871 1003  5D24 524F EB1A 9D33 C9CB")))))
