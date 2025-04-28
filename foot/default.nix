{ pkgs, lib, config, cmd-half-monitor-width, cmd-half-monitor-height, ...}:
let
  foot-launcher = pkgs.writeShellScriptBin "foot-launcher" ''
      # Path to your default URL opener
      DEFAULT_OPENER="xdg-open"

      input="$1"

      # --- Enhanced Debugging ---
      echo "--- New Invocation ---" >> /tmp/test
      echo "Timestamp: $(date)" >> /tmp/test
      echo "Number of args (\$#): $#" >> /tmp/test       # How many arguments were passed?
      echo "All args (\$@): '$@'" >> /tmp/test         # What do all arguments look like?
      echo "Arg 1 (\$1): '$1'" >> /tmp/test             # What is specifically in $1?
      echo "Arg 2 (\$2): '$2'" >> /tmp/test             # Just in case, what's in $2?

      # Regex to match "path:line_number" format
      # This matches typical paths (allowing alphanumeric, ., /, _, -, ~) followed by : and digits.
      # It captures the path in \1 and the line number in \2 (using sed)
      if echo "$input" | grep -qE '^([a-zA-Z0-9./_~-]+):([0-9]+)$'; then
          echo "MATCH!" >> /tmp/test
          path=$(echo "$input" | sed -E 's@^([a-zA-Z0-9./_~-]+):([0-9]+)$@\1@')
          echo "path = $path" >> /tmp/test
          line=$(echo "$input" | sed -E 's@^([a-zA-Z0-9./_~-]+):([0-9]+)$@\2@')
          echo "line = $line" >> /tmp/test
          echo "width = $(${cmd-half-monitor-width}/bin/cmd-half-monitor-width)" >> /tmp/test


          # Check if the extracted path actually exists as a file or symlink
          if [ -f "$path" ] || [ -L "$path" ]; then
              echo "OPENING NVIM" >> /tmp/test
              # Open with Vim at the correct line.
              # Using footclient is good if you run foot --server
              # The --app-id helps manage windows if needed.
              # Fall back to running foot directly, then xterm as a last resort.
              # Run in background (&) so it doesn't block foot.
              ${pkgs.foot}/bin/foot --app-id=float_me_pls --window-size-pixels=$(${cmd-half-monitor-width}/bin/cmd-half-monitor-width)x$(${cmd-half-monitor-height}/bin/cmd-half-monitor-height) /home/hugo/.nix-profile/bin/nvim "+''${line}" "''${path}"
              exit 0 # Successfully handled
          else
            notify-send "File not found" "$path"
          fi
          # If the path doesn't exist, fall through to default handler
      fi

      # If it didn't match the file:line pattern or the file didn't exist,
      # treat it as a regular URL/URI and use the default opener.
      "$DEFAULT_OPENER" "$input" &

      exit 0
    '';
in
{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "JetBrains Mono Nerd Font:size=16";
        shell = "${pkgs.zsh}/bin/zsh";
      };
      url = {
        # launch = "/home/hugo/.local/bin/foot-launcher %s";
        launch = ''${foot-launcher}/bin/foot-launcher ''${url}'';
        regex = "<default-foot-regex>|([a-zA-Z0-9./_~-]+:[0-9]+)";
      };
      # gruvbox theme from https://codeberg.org/dnkl/foot/src/branch/master/themes/gruvbox-dark
      colors = {
        alpha = 0.88;
        background="282828";
        foreground="ebdbb2";
        regular0="282828";
        regular1="cc241d";
        regular2="98971a";
        regular3="d79921";
        regular4="458588";
        regular5="b16286";
        regular6="689d6a";
        regular7="a89984";
        bright0="928374";
        bright1="fb4934";
        bright2="b8bb26";
        bright3="fabd2f";
        bright4="83a598";
        bright5="d3869b";
        bright6="8ec07c";
        bright7="ebdbb2";
      };
    };
  };
}
