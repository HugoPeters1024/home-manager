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
    history.size = 100000;
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
