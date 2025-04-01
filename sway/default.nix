{ config, pkgs, ... }:
let
  cfg = config.wayland.windowManager.sway;
  autotiling-script = import ./autotiling.nix;
in {
  imports = [
    ./waybar.nix
    ./autotiling.nix
  ];

  # Set up the right set of files, according to:
  # https://github.com/alebastr/sway-systemd/tree/main
  # Make sure to bring in updates from there periodically!
  home.file.".config/systemd/user/sway-session-shutdown.target".source =
    ./systemd-units/sway-session-shutdown.target;

  # home.file.".config/systemd/user/sway-session.target".source =
  #   ./systemd-units/sway-session.target;

  home.file.".config/systemd/user/sway-xdg-autostart.target".source =
    ./systemd-units/sway-xdg-autostart.target;

  # Also copy the session.sh from the same repo into our config directory,
  # so it can be called from our sway startup.
  home.file.".config/sway/session.sh" = {
    source = ./session.sh;
    executable = true;
  };

  # Autotiling utilities
  # home.file.".config/sway/autotiling" = {
  #   source = autotiling-script{};
  #   executable = true;
  # };

  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # Fixes common issues with GTK 3 apps
    config = rec {
      modifier = "Mod4";
      terminal = "${pkgs.foot}/bin/foot ${pkgs.zsh}/bin/zsh";
      startup = [ ];
      bars = [];
      input = {
        "type:keyboard" = {
          repeat_delay = "180";
          repeat_rate = "40";
        };
      };
    };

    extraConfig = ''
      # Execute the session command that does all sorts of magic, including
      # ensuring we can screen-share.
      exec ${config.home.homeDirectory}/.config/sway/session.sh

      ## include the default sway config
      include /etc/sway/config.d/*

      # autotiling utilities
      exec_always ${config.home.homeDirectory}/.config/sway/autotiling

      for_window [class="^.*"] border pixel 4
      for_window [floating] border pixel 5
      for_window [class=.*] exec ~/.config/i3/i3-autosplit.sh
      hide_edge_borders smart

      bar {
        swaybar_command ${pkgs.waybar}/bin/waybar
        position bottom
        hidden_state hide
        mode hide
        modifier ${cfg.config.modifier}
      }

      bindsym ${cfg.config.modifier}+o exec "rofi -modi drun,run -show drun"
      bindsym ${cfg.config.modifier}+BackSpace exec --no-startup-id swaylock -c 333344

      # Brightness
      bindsym XF86MonBrightnessDown exec ${pkgs.brightnessctl}/bin/brightnessctl s 5-
      bindsym XF86MonBrightnessUp exec ${pkgs.brightnessctl}/bin/brightnessctl s +5

      # Volume
      bindsym XF86AudioRaiseVolume exec amixer set Master 5%+
      bindsym XF86AudioLowerVolume exec amixer set Master 5%-
      bindsym XF86AudioMute exec amixer -D pulse set Master 1+ toggle
      bindsym XF86AudioMicMute exec amixer set Capture toggle

      # Screenshot
      bindsym Print exec ${pkgs.sway-contrib.grimshot}/bin/grim -g "$(slurp)"

      # Floating windows
      for_window [app_id="float_me_pls"] floating enable; move position center; resize set width 50 ppt height 50 ppt
      for_window [app_id="nm-connection-editor"] floating enable
      for_window [app_id="wdisplays"] floating enable
      for_window [app_id="pavucontrol"] floating enable; resize set width 60 ppt height 60 ppt

      workspace 1
    '';
  };
  services.gnome-keyring.enable = true;
}
