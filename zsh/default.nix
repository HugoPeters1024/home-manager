{
  pkgs,
  config,
  ...
}:
{
  programs.zsh = {
    enable = true;
    autocd = true;
    dotDir = "${config.home.homeDirectory}/.config/zsh";
    enableCompletion = true;
    history.size = 1000000;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "history-substring-search"
        "ssh-agent"
      ];
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

      # Auto-attach to tmux session when connected over SSH
      if [[ -n $SSH_CONNECTION || -n $SSH_TTY || -n $SSH_CLIENT ]] && [[ -z $TMUX ]]; then
        # Check if tmux is available
        if command -v tmux >/dev/null 2>&1; then
          # Try to attach to existing session or create new one
          tmux attach-session -t main 2>/dev/null || tmux new-session -s main
        fi
      fi
    '';

    initContent = ''
      # If connected over SSH, prepend a yellow "REMOTE" badge to the prompt
      if [[ -n $SSH_CONNECTION || -n $SSH_TTY || -n $SSH_CLIENT ]]; then
        PROMPT="%K{red}%F{white} REMOTE %f%k $PROMPT"
      fi
    '';
  };

  programs.direnv = {
    enable = true;
  };

  # Enables fuzzy history search
  programs.fzf = {
    enable = true;
    historyWidgetOptions = [ "--layout=reverse" ];
  };
}
