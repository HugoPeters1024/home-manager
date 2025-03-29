{ pkgs, lib, ...}:

{
  programs.zsh = {
    enable = true;
    autocd = true;
    dotDir = ".config/zsh";
    enableCompletion = true;
    oh-my-zsh = {
      enable = true;
      plugins = ["git" "history-substring-search" "fzf-zsh-plugin" "ssh-agent"];
      theme = "agnoster";
      custom = "$HOME/.oh-my-custom";
    };
  };
}
