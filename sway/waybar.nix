{ config, pkgs, cmd-get-half-width, cmd-get-half-height, ...}:

{
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
          "network"
          # "power-profiles-daemon"
          "cpu"
          "memory"
          "disk"
          "temperature"
          "custom/gpu-temperature"
          "backlight"
          "pulseaudio"
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
          "interval" = 2;
          "on-click-right" = "${pkgs.foot}/bin/foot --app-id=float_me_pls --window-size-pixels=${cmd-get-half-width}x${cmd-get-half-height} ${pkgs.bottom}/bin/btm";
        };

        "memory" = {
         # "format" = "{}% ";
          "format" = "{used:0.1f}G/{total:0.1f}G ";
          "interval" = 2;
        };

        "disk" = {
          "interval" = 30;
          "format" = "{used}/{total}";
          "path" = "/";
        };

        "temperature" = {
          "critical-threshold" = 80;
          # "format" = "CPU: {temperatureC}°C {icon}";
          "format" = "CPU: {temperatureC}°C";
          "format-icons" = ["" "" ""];
        };

        "custom/gpu-temperature" = {
          "exec" = "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits";
          "format" = "GPU: {}°C";
          "return-type" = "string";
          "interval" = 5;
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
          "interval" = 2;
        };

        "battery#bat2" = {
          "bat" = "BAT2";
          "interval" = 2;
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
          "on-click-right" = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
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
