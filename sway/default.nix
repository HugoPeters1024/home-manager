{ config, pkgs, ... }:
let
  cfg = config.wayland.windowManager.sway;
in {
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # Fixes common issues with GTK 3 apps
    config = rec {
      modifier = "Mod4";
      terminal = "/usr/bin/foot ${pkgs.zsh}/bin/zsh"; 
      startup = [ ];
      bars = [{ command = "${pkgs.waybar}/bin/waybar"; }];
      input = {
        "type:keyboard" = {
          repeat_delay = "180";
          repeat_rate = "40";
        };
      };
    };

    extraConfig = ''
      for_window [class="^.*"] border pixel 4
      for_window [floating] border pixel 5
      for_window [class=.*] exec ~/.config/i3/i3-autosplit.sh
      hide_edge_borders smart

      bindsym ${cfg.config.modifier}+o exec "rofi -modi drun,run -show drun" 
    '';
  };
  services.gnome-keyring.enable = true;

  programs.waybar = {
    enable = true;
    style = ./waybar.css;
  };
}
