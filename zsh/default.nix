{ pkgs, lib, ...}:

{
  programs.zsh = {
    enable = true;
    autocd = true;
    dotDir = ".config/zsh";
    enableCompletion = true;
    history.size = 100000;
    oh-my-zsh = {
      enable = true;
      plugins = ["git" "history-substring-search" "ssh-agent"];
      theme = "agnoster";
      custom = "$HOME/.oh-my-custom";
    };
    envExtra = ''
       # use whatever installed by rustup
       export PATH="/home/hugo/.cargo/bin:$PATH"

       # use direnv
       eval "$(${pkgs.direnv}/bin/direnv hook zsh)"

       alias with-cachix-key="vaultenv --secrets-file  <(echo \"cachix#signing-key\" ) -- "
    '';
  };

  # Enables fuzzy history search
  programs.fzf = {
    enable = true;
    historyWidgetOptions = ["--layout=reverse"];
  };
}
