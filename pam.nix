{
  security.pam.services.sudo_local = {
    enable = true;        # Tells nix-darwin to manage `/etc/pam.d/sudo_local`
    touchIdAuth = true;   # Automatically appends 'auth sufficient pam_tid.so'
    # watchIdAuth = true; # Enables Apple Watch authentication for sudo
    reattach = true;      # Fixes Touch ID breaks inside tmux/screen via pam_reattach
  };
}
