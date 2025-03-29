{ config, pkgs, ... }:
let
  cfg = config.wayland.windowManager.sway;
in {
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # Fixes common issues with GTK 3 apps
    config = rec {
      modifier = "Mod4";
      # Use kitty as default terminal
      terminal = "foot"; 
      startup = [ ];
      input = {
        "type:keyboard" = {
          repeat_delay = "180";
          repeat_rate = "40";
        };
      };
    };

    extraConfig = ''
      bindsym ${cfg.config.modifier}+o exec "rofi -modi drun,run -show drun" 
    '';
  };
  services.gnome-keyring.enable = true;
}
