{
  pkgs,
  lib,
  config,
  ...
}:
let
  colossusEnabled = config.programs.colossus.enable or false;
  colossusCompletionInit = lib.optionalString colossusEnabled ''
    # Colossus CLI completion setup (pre-generated)
    autoload -Uz bashcompinit
    bashcompinit
    source ${config.programs.colossus.completionScript}
  '';
  sshAgentEnabled = config.programs.zsh.sshAgentPlugin.enable or false;
  basePlugins = [
    "git"
    "history-substring-search"
  ];
  plugins = if sshAgentEnabled then basePlugins ++ [ "ssh-agent" ] else basePlugins;
in
{
  options.programs.zsh.sshAgentPlugin.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable the oh-my-zsh ssh-agent plugin";
  };

  config.programs.zsh = {
    enable = true;
    autocd = true;
    dotDir = "${config.home.homeDirectory}/.config/zsh";
    enableCompletion = true;
    history.size = 1000000;
    oh-my-zsh = {
      enable = true;
      plugins = plugins;
      theme = "agnoster";
      custom = "$HOME/.oh-my-custom";
    };
    envExtra = ''
      # use whatever installed by rustup
      export PATH="${config.home.homeDirectory}/.cargo/bin:$PATH"

      # local bin is fine too
      export PATH="${config.home.homeDirectory}/.local/bin:$PATH"

      # use direnv
      eval "$(${pkgs.direnv}/bin/direnv hook zsh)"

      source ${config.home.homeDirectory}/.config/zsh/.zshextra.env

      # Ensure vim and vi are aliased to nvim for all terminals
      alias vim='nvim'
      alias vi='nvim'

      # Auto-attach to tmux session when connected over SSH
      if [[ -n $SSH_CONNECTION || -n $SSH_TTY || -n $SSH_CLIENT ]] && [[ -z $TMUX ]]; then
        # Check if tmux is available
        if command -v tmux >/dev/null 2>&1; then
          # Try to attach to existing session or create new one
          tmux attach-session -t tmux 2>/dev/null || tmux new-session -s tmux
        fi
      fi
    '';

    initContent = ''
      # If connected over SSH, prepend a yellow "REMOTE" badge to the prompt
      if [[ -n $SSH_CONNECTION || -n $SSH_TTY || -n $SSH_CLIENT ]]; then
        PROMPT="%K{red}%F{white} REMOTE %f%k $PROMPT"
      fi

      ${colossusCompletionInit}
    '';
  };

  config.programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Enables fuzzy history search
  config.programs.fzf = {
    enable = true;
    historyWidgetOptions = [ "--layout=reverse" ];
  };
}
