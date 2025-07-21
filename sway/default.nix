{ config, pkgs, ... }:
let
  cfg = config.wayland.windowManager.sway;
  autotiling-script = import ./autotiling.nix;
  grimScreenshotSave = "(${pkgs.slurp}/bin/slurp | ${pkgs.grim}/bin/grim -g - - | ${pkgs.wl-clipboard}/bin/wl-copy && ${pkgs.wl-clipboard}/bin/wl-paste > ~/Pictures/Screenshots/$(date +'%Y-%m-%d-%H%M%S_grim.png'))";
  grimScreenshotClipboard = "(${pkgs.slurp}/bin/slurp | ${pkgs.grim}/bin/grim -g - - | ${pkgs.wl-clipboard}/bin/wl-copy)";

  cmd-get-half-width = "$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused==true).rect.width' | awk '{ print $1/2 }')";
  cmd-get-half-height = "$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused==true).rect.height' | awk '{ print $1/2 }')";
in {
  imports = [
    (import ./waybar.nix { inherit pkgs config cmd-get-half-width cmd-get-half-height; })
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

  home.file.".local/share/applications/fix-displays.desktop" = {
    text = ''
      [Desktop Entry]
      Name=Fix Displays
      Comment=Run wlr-randr to fix displays
      Exec=~/.nix-profile/bin/fix-displays.sh
      Icon=terminal
      Terminal=true
      Type=Application
      Categories=Utility;
    '';
  };

  home.file.".config/sway/wallpaper.jpg" = {
    source = ./wallpaper.jpg;
  };

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

      exec_always ${pkgs.swaybg}/bin/swaybg --image ${config.home.homeDirectory}/.config/sway/wallpaper.jpg


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

      bindsym ${cfg.config.modifier}+o exec "XDG_DATA_DIRS=$HOME/.nix-profile/share:$XDG_DATA_DIRS PATH=$HOME/.nix-profile/bin:$PATH ${pkgs.rofi}/bin/rofi -modi drun,run -show drun"
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
      bindsym Print exec ${grimScreenshotClipboard}
      bindsym Shift+Print exec ${grimScreenshotSave}

      # Floating windows
      for_window [title="chicken game"] floating enable, move position center
      for_window [title="float_me_pls"] floating enable, move position center
      for_window [app_id="float_me_pls"] floating enable, move position center
      for_window [app_id="nm-connection-editor"] floating enable
      for_window [app_id="wdisplays"] floating enable
      for_window [app_id="pavucontrol"] floating enable; resize set width 60 ppt height 60 ppt

      workspace 1
    '';
  };
  services.gnome-keyring.enable = true;
}
