{ config, pkgs, ... }:
let
  cfg = config.wayland.windowManager.sway;
  autotiling-script = import ./autotiling.nix;
in {
  imports = [
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
      bindsym Print exec ${pkgs.sway-contrib.grimshot}/bin/grim -g "$(slurp)" - | wl-copy

      workspace 1
    '';
  };
  services.gnome-keyring.enable = true;

  programs.waybar = {
    enable = true;
    style = ./waybar.css;
    settings = [
    {
        "position" = "bottom";
        "height" = 48;
        "spacing" = 4;

        "modules-left" = [
          "sway/workspaces"
          "sway/mode"
          "sway/scratchpad"
          "custom/media"
        ];

        "modules-center" = [
          "sway/window"
        ];

        "modules-right" = [
          "mpd"
          # "idle_inhibitor"
          "pulseaudio"
          "network"
          # "power-profiles-daemon"
          "cpu"
          "memory"
          "disk"
          "temperature"
          "backlight"
          "keyboard-state"
          # "sway/language"
          "battery"
          "battery#bat2"
          "clock"
          "tray"
          # "custom/power"
        ];

        "keyboard-state" = {
          "numlock" = true;
          "capslock" = true;
          "format" = "{name} {icon}";
          "format-icons" = {
            "locked" = "";
            "unlocked" = "";
          };
        };

        "sway/mode" = {
          "format" = "<span style=\"italic\">{}</span>";
        };

        "sway/scratchpad" = {
          "format" = "{icon} {count}";
          "show-empty" = false;
          "format-icons" = ["" ""];
          "tooltip" = true;
          "tooltip-format" = "{app}: {title}";
        };

        "mpd" = {
          "format" = "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ⸨{songPosition}|{queueLength}⸩ {volume}% ";
          "format-disconnected" = "Disconnected ";
          "format-stopped" = "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ";
          "unknown-tag" = "N/A";
          "interval" = 5;
          "consume-icons" = {
            "on" = " ";
          };
          "random-icons" = {
            "off" = "<span color=\"#f53c3c\"></span> ";
            "on" = " ";
          };
          "repeat-icons" = {
            "on" = " ";
          };
          "single-icons" = {
            "on" = "1 ";
          };
          "state-icons" = {
            "paused" = "";
            "playing" = "";
          };
          "tooltip-format" = "MPD (connected)";
          "tooltip-format-disconnected" = "MPD (disconnected)";
        };

        "idle_inhibitor" = {
          "format" = "{icon}";
          "format-icons" = {
            "activated" = "";
            "deactivated" = "";
          };
        };

        "tray" = {
          "spacing" = 10;
        };

        "clock" = {
          "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          "format-alt" = "{:%Y-%m-%d}";
        };

        "cpu" = {
          "format" = "{usage}% ";
          "tooltip" = false;
        };

        "memory" = {
          "format" = "{}% ";
        };

        "disk" = {
          "interval" = 30;
          "format" = "{used}/{total}";
          "path" = "/";
        };

        "temperature" = {
          "critical-threshold" = 80;
          "format" = "{temperatureC}°C {icon}";
          "format-icons" = ["" "" ""];
        };

        "backlight" = {
          "format" = "{percent}% {icon}";
          "format-icons" = ["🔅" "🔆"];
        };

        "battery" = {
          "states" = {
            "warning" = 30;
            "critical" = 15;
          };
          "format" = "{capacity}% {icon}";
          "format-full" = "{capacity}% {icon}";
          "format-charging" = "{capacity}% ";
          "format-plugged" = "{capacity}% ";
          "format-alt" = "{time} {icon}";
          "format-icons" = ["" "" "" "" ""];
        };

        "battery#bat2" = {
          "bat" = "BAT2";
        };

        "power-profiles-daemon" = {
          "format" = "{icon}";
          "tooltip-format" = "Power profile: {profile}\nDriver: {driver}";
          "tooltip" = true;
          "format-icons" = {
            "default" = "";
            "performance" = "";
            "balanced" = "";
            "power-saver" = "";
          };
        };

        "network" = {
          "format-wifi" = "{essid} ({signalStrength}%) ";
          "format-ethernet" = "{ipaddr}/{cidr} ";
          "tooltip-format" = "{ifname} via {gwaddr} ";
          "format-linked" = "{ifname} (No IP) ";
          "format-disconnected" = "Disconnected ⚠";
          "format-alt" = "{ifname}: {ipaddr}/{cidr}";
        };

        "pulseaudio" = {
          "format" = "{volume}% {icon} {format_source}";
          "format-bluetooth" = "{volume}% {icon} {format_source}";
          "format-bluetooth-muted" = " {icon} {format_source}";
          "format-muted" = " {format_source}";
          "format-source" = "{volume}% ";
          "format-source-muted" = "";
          "format-icons" = {
            "headphone" = "";
            "hands-free" = "";
            "headset" = "";
            "phone" = "";
            "portable" = "";
            "car" = "";
            "default" = ["" "" ""];
          };
          "on-click" = "pavucontrol";
        };

        "custom/media" = {
          "format" = "{icon} {text}";
          "return-type" = "json";
          "max-length" = 40;
          "format-icons" = {
            "spotify" = "";
            "default" = "🎜";
          };
          "escape" = true;
          "exec" = "$HOME/.config/waybar/mediaplayer.py 2> /dev/null";
        };

        "custom/power" = {
          "format" = "⏻ ";
          "tooltip" = false;
          "menu" = "on-click";
          "menu-file" = "$HOME/.config/waybar/power_menu.xml";
          "menu-actions" = {
            "shutdown" = "shutdown";
            "reboot" = "reboot";
            "suspend" = "systemctl suspend";
            "hibernate" = "systemctl hibernate";
          };
        };
      }
    ];
  };
}
