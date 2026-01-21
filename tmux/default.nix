{
  pkgs,
  lib,
  config,
  ...
}:
{
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    historyLimit = 50000000;
    clock24 = true;

    # Change prefix from C-b to C-f
    # prefix = "C-f";

    # Enable mouse support
    mouse = true;

    # Start window and pane indices at 1
    baseIndex = 1;

    # Use vi mode keys
    keyMode = "vi";

    # Plugins
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
    ];

    extraConfig = ''
      # Pane base index
      set -g pane-base-index 0

      # Change pane selection with prefix -- keep arrows also functional
      bind -r k select-pane -U
      bind -r j select-pane -D
      bind -r h select-pane -L
      bind -r l select-pane -R

      # Add other split options
      bind b split-window -h
      bind v split-window -v

      # Vi copy mode settings
      unbind -T copy-mode-vi Enter
      bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"

      # Refresh status line every 5 seconds
      set -g status-interval 5

      # Length of tmux status line
      set -g status-left-length 30
      set -g status-right-length 150

      set-option -g status "on"

      # Default statusbar color
      set-option -g status-style bg=colour237,fg=colour223 # bg=bg1, fg=fg1

      # Default window title colors
      set-window-option -g window-status-style bg=colour214,fg=colour237 # bg=yellow, fg=bg1

      # Default window with an activity alert
      set-window-option -g window-status-activity-style bg=colour237,fg=colour248 # bg=bg1, fg=fg3

      # Active window title colors
      set-window-option -g window-status-current-style bg=red,fg=colour237 # fg=bg1

      # Set active pane border color
      set-option -g pane-active-border-style fg=colour214

      # Set inactive pane border color
      set-option -g pane-border-style fg=colour239

      # Message info
      set-option -g message-style bg=colour239,fg=colour223 # bg=bg2, fg=fg1

      # Writing commands inactive
      set-option -g message-command-style bg=colour239,fg=colour223 # bg=fg3, fg=bg1

      # Pane number display
      set-option -g display-panes-active-colour colour1 #fg2
      set-option -g display-panes-colour colour237 #bg1

      # Clock
      set-window-option -g clock-mode-colour colour109 #blue

      # Bell
      set-window-option -g window-status-bell-style bg=colour167,fg=colour235

      set-option -g status-left "\
      #[fg=colour7, bg=colour241]#{?client_prefix,#[bg=colour167],} ❐ #S \
      #[fg=colour241, bg=colour237]#{?client_prefix,#[fg=colour167],}#{?window_zoomed_flag, 🔍,}"

      set-option -g status-right "\
      #[fg=colour214, bg=colour237] \
      #[fg=colour223, bg=colour237] #(~/tmux_scripts/echo.sh) \
      #[fg=colour246, bg=colour237]  %b %d '%y\
      #[fg=colour109]  %H:%M \
      #[fg=colour248, bg=colour239]"

      set-window-option -g window-status-current-format "\
      #[fg=colour237, bg=colour214]\
      #[fg=colour239, bg=colour214] #I* \
      #[fg=colour239, bg=colour214, bold] #W \
      #[fg=colour214, bg=colour237]"

      set-window-option -g window-status-format "\
      #[fg=colour237,bg=colour239,noitalics]\
      #[fg=colour223,bg=colour239] #I \
      #[fg=colour223, bg=colour239] #W \
      #[fg=colour239, bg=colour237]"
    '';
  };
}
