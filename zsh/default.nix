{
  pkgs,
  lib,
  username,
  ...
}:
{
  programs.zsh = {
    enable = true;
    autocd = true;
    dotDir = ".config/zsh";
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
      export PATH="/home/hugo/.cargo/bin:$PATH"
      export PATH="/Users/hpeters/.cargo/bin:$PATH"
      export SHELL=${pkgs.zsh}/bin/zsh

      # local bin is fine too
      export PATH="/Users/hpeters/.local/bin:$PATH"

      # use direnv
      eval "$(${pkgs.direnv}/bin/direnv hook zsh)"

      alias with-cachix-key="vaultenv --secrets-file  <(echo \"cachix#signing-key\" ) -- "
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
