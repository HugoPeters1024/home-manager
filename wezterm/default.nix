{
  pkgs,
  lib,
  config,
  ...
}:
let
  fontConfig = {
    nerdfont = {
      primary = "'JetBrainsMono Nerd Font Mono'";
      tabBar = "JetBrainsMono Nerd Font Mono";
      weight = "Regular";
      boldWeight = "Bold";
      fallback = ''
        'JetBrains Mono',
        'DejaVu Sans Mono',
        'monospace',
      '';
    };
    terminus = {
      primary = "{ family = 'Terminus (TTF)', weight = 'Medium' }";
      tabBar = "Terminus (TTF)";
      weight = "Medium";
      boldWeight = "Bold";
      fallback = ''
        'JetBrainsMono Nerd Font Mono',
        'JetBrains Mono',
        'DejaVu Sans Mono',
        'monospace',
      '';
    };
  };

  selectedFont = fontConfig.${config.wezterm.font};
in
{
  options.wezterm.font = lib.mkOption {
    type = lib.types.enum [ "nerdfont" "terminus" ];
    default = "nerdfont";
    description = "The primary font to use in wezterm (nerdfont or terminus)";
  };

  config = {
    home.packages = lib.optionals (config.wezterm.font == "terminus") [ pkgs.terminus_font_ttf ];

    programs.wezterm = {
      enable = true;
      extraConfig = ''
        -- Pull in the wezterm API
        local wezterm = require 'wezterm'

        -- This table will hold the configuration.
        local config = wezterm.config_builder()
        config.max_fps = 166

        -- For example, changing the color scheme:
        config.color_scheme = 'Gruvbox Dark (Gogh)'

        -- Font configuration - ${config.wezterm.font}
        config.font = wezterm.font_with_fallback({
          ${selectedFont.primary},
          ${selectedFont.fallback}
        })

        config.font_size = 14.0
        config.line_height = 1.10
        config.font_rules = {
          {
            intensity = "Normal",
            italic = false,
            font = wezterm.font(${selectedFont.primary}),
          },
          {
            intensity = "Bold",
            italic = false,
            font = wezterm.font('${selectedFont.tabBar}', { weight = '${selectedFont.boldWeight}' }),
          },
        }

        -- Window configuration
        config.window_decorations = "TITLE | RESIZE"
        config.window_background_opacity = 1.0
        config.text_background_opacity = 1.0
        -- Set initial window size to be much larger
        config.initial_cols = 160
        config.initial_rows = 50
        config.window_padding = {
          left = 8,
          right = 8,
          top = 8,
          bottom = 8,
        }

        -- Tab bar configuration
        config.use_fancy_tab_bar = true
        config.hide_tab_bar_if_only_one_tab = true
        config.tab_bar_at_bottom = true
        config.show_tab_index_in_tab_bar = false
        config.show_new_tab_button_in_tab_bar = false
        config.tab_max_width = 24
        config.window_decorations = "TITLE | RESIZE"

        -- Custom tab bar function with icons and better formatting
        local function tab_title(tab_info)
          local title = tab_info.tab_title
          if title and #title > 0 then
            return title
          end
          return tab_info.active_pane.title
        end

        local function get_process_icon(process_name)
          local icons = {
            ["zsh"] = "🐚",
            ["bash"] = "🐚",
            ["fish"] = "🐟",
            ["vim"] = "📝",
            ["nvim"] = "📝",
            ["nano"] = "📝",
            ["emacs"] = "📝",
            ["git"] = "🌿",
            ["docker"] = "🐳",
            ["kubectl"] = "☸️",
            ["node"] = "🟢",
            ["python"] = "🐍",
            ["rust"] = "🦀",
            ["go"] = "🐹",
            ["cargo"] = "🦀",
            ["npm"] = "📦",
            ["yarn"] = "📦",
            ["ssh"] = "🔐",
            ["tmux"] = "🖥️",
            ["htop"] = "📊",
            ["top"] = "📊",
            ["ps"] = "📊",
            ["ls"] = "📁",
            ["cat"] = "📄",
            ["grep"] = "🔍",
            ["find"] = "🔍",
            ["cd"] = "📁",
            ["pwd"] = "📍",
            ["curl"] = "🌐",
            ["wget"] = "🌐",
          }

          for process, icon in pairs(icons) do
            if string.find(process_name:lower(), process) then
              return icon
            end
          end

          return "💻"
        end

        wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
          local background = tab.is_active and "#3c3836" or "#1d2021"
          local foreground = tab.is_active and "#ebdbb2" or "#928374"

          local text = tab_title(tab)
          local icon = get_process_icon(tab.active_pane.foreground_process_name)

          -- Truncate text if too long
          if #text > 15 then
            text = string.sub(text, 1, 12) .. "..."
          end

          return {
            { Background = { Color = background } },
            { Foreground = { Color = foreground } },
            { Text = " " .. icon .. " " .. text .. " " },
          }
        end)

        -- Cursor configuration
        config.default_cursor_style = "SteadyBlock"
        config.cursor_thickness = 0.8

        -- Scrollback configuration
        config.scrollback_lines = 100000

        -- Bell configuration - completely disabled
        config.audible_bell = "Disabled"
        config.visual_bell = {
          fade_in_function = "EaseIn",
          fade_in_duration_ms = 0,
          fade_out_function = "EaseOut",
          fade_out_duration_ms = 0,
        }

        -- Window behavior
        config.window_close_confirmation = "NeverPrompt"
        -- Remove background gradient for solid background

        -- Key bindings
        config.keys = {
          -- Make Option-Left equivalent to Alt-b which many line editors interpret as backward-word
          {
            key = "LeftArrow",
            mods = "OPT",
            action = wezterm.action { SendString = "\\x1bb" },
          },
          -- Make Option-Right equivalent to Alt-f; forward-word
          {
            key = "RightArrow",
            mods = "OPT",
            action = wezterm.action { SendString = "\\x1bf" },
          },
          -- Cmd+Shift+Enter to open new tab
          {
            key = "Enter",
            mods = "CMD|SHIFT",
            action = wezterm.action { SpawnTab = "CurrentPaneDomain" },
          },
          -- Cmd+Shift+W to close tab
          {
            key = "w",
            mods = "CMD|SHIFT",
            action = wezterm.action { CloseCurrentTab = { confirm = false } },
          },
          -- Cmd+Shift+D to duplicate tab
          {
            key = "d",
            mods = "CMD|SHIFT",
            action = wezterm.action { SpawnTab = "CurrentPaneDomain" },
          },
          -- Ctrl+Shift+Left/Right to switch tabs
          {
            key = "LeftArrow",
            mods = "CTRL|SHIFT",
            action = wezterm.action { ActivateTabRelative = -1 },
          },
          {
            key = "RightArrow",
            mods = "CTRL|SHIFT",
            action = wezterm.action { ActivateTabRelative = 1 },
          },
          -- Cmd+Shift+Up/Down to switch panes
          {
            key = "UpArrow",
            mods = "CMD|SHIFT",
            action = wezterm.action { ActivatePaneDirection = "Up" },
          },
          {
            key = "DownArrow",
            mods = "CMD|SHIFT",
            action = wezterm.action { ActivatePaneDirection = "Down" },
          },
          {
            key = "LeftArrow",
            mods = "CMD|SHIFT",
            action = wezterm.action { ActivatePaneDirection = "Left" },
          },
          {
            key = "RightArrow",
            mods = "CMD|SHIFT",
            action = wezterm.action { ActivatePaneDirection = "Right" },
          },
          -- Cmd+Shift+H/V to split panes
          {
            key = "h",
            mods = "CMD|SHIFT",
            action = wezterm.action { SplitHorizontal = { domain = "CurrentPaneDomain" } },
          },
          {
            key = "v",
            mods = "CMD|SHIFT",
            action = wezterm.action { SplitVertical = { domain = "CurrentPaneDomain" } },
          },
          -- Cmd+Shift+Q to close pane
          {
            key = "q",
            mods = "CMD|SHIFT",
            action = wezterm.action { CloseCurrentPane = { confirm = false } },
          },
        }

        -- Mouse bindings
        config.mouse_bindings = {
          -- Change the default click behavior so that it only selects text and doesn't open hyperlinks
          {
            event = { Up = { streak = 1, button = "Left" } },
            mods = "NONE",
            action = wezterm.action { CompleteSelection = "Clipboard" },
          },
          -- Ctrl-click will open the link under the mouse cursor
          {
            event = { Up = { streak = 1, button = "Left" } },
            mods = "CTRL",
            action = "OpenLinkAtMouseCursor",
          },
        }

        -- Custom color scheme for Gruvbox Dark
        config.color_schemes = {
          ["Gruvbox Dark"] = {
            foreground = "#ebdbb2",
            background = "#282828",
            cursor_bg = "#ebdbb2",
            cursor_border = "#ebdbb2",
            cursor_fg = "#282828",
            selection_bg = "#3c3836",
            selection_fg = "#ebdbb2",

            ansi = {
              "#282828", -- black
              "#cc241d", -- red
              "#98971a", -- green
              "#d79921", -- yellow
              "#458588", -- blue
              "#b16286", -- magenta
              "#689d6a", -- cyan
              "#a89984", -- white
            },

            brights = {
              "#928374", -- bright black
              "#fb4934", -- bright red
              "#b8bb26", -- bright green
              "#fabd2f", -- bright yellow
              "#83a598", -- bright blue
              "#d3869b", -- bright magenta
              "#8ec07c", -- bright cyan
              "#ebdbb2", -- bright white
            },

            indexed = { [16] = "#fabd2f", [17] = "#d3869b" },
          },
        }

        -- Use the Gruvbox Dark color scheme
        config.color_scheme = "Gruvbox Dark"

        -- Tab bar styling - Subtle Gruvbox theme
        config.colors = {
          tab_bar = {
            -- The color of the inactive tab bar area/background
            background = "#1d2021",

            -- The active tab is the one that has focus in the window
            active_tab = {
              -- The color of the background area for the active tab
              bg_color = "#3c3836",
              -- The color of the text for the active tab
              fg_color = "#ebdbb2",
              intensity = "Normal",
            },

            -- Inactive tabs are the tabs that do not have focus
            inactive_tab = {
              -- The color of the background area for the inactive tab
              bg_color = "#1d2021",
              -- The color of the text for the inactive tab
              fg_color = "#928374",
              intensity = "Normal",
            },

            -- The same applies to the hovered tab and other tab bar elements
            inactive_tab_hover = {
              bg_color = "#282828",
              fg_color = "#a89984",
              intensity = "Normal",
              italic = false,
            },

            new_tab = {
              bg_color = "#1d2021",
              fg_color = "#928374",
            },

            new_tab_hover = {
              bg_color = "#282828",
              fg_color = "#a89984",
              intensity = "Normal",
              italic = false,
            },
          },
        }

        -- Window frame styling - Enhanced Gruvbox theme
        config.window_frame = {
          -- The font used in the tab bar.
          font = wezterm.font { family = "${selectedFont.tabBar}", weight = "${selectedFont.weight}" },

          -- The size of the font in the tab bar.
          font_size = 11.0,

          -- The active tab title max length
          active_titlebar_bg = "#1d2021",
          inactive_titlebar_bg = "#1d2021",

          -- Window frame colors
          border_left_width = "0px",
          border_right_width = "0px",
          border_bottom_height = "0px",
          border_top_height = "0px",
          border_left_color = "#1d2021",
          border_right_color = "#1d2021",
          border_bottom_color = "#1d2021",
          border_top_color = "#1d2021",
        }

        -- Additional tab styling
        config.tab_max_width = 24
        config.warn_about_missing_glyphs = false

        -- Window padding
        config.window_padding = {
          left = 12,
          right = 12,
          top = 12,
          bottom = 12,
        }

        -- Ensure WezTerm inherits the same environment as Kitty
        -- This will use the zsh configuration from home-manager which includes proper PATH setup
        config.default_prog = { "/bin/zsh", "-l" }

        -- And finally, return the configuration to wezterm
        return config
      '';
    };
  };
}
