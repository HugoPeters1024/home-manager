{ pkgs, lib, ...}:

{
  programs.foot = {
    settings = {
      font = "JetBrains Mono Nerd Font:size=16";
      shelll = "${pkgs.zsh}/bin/zsh";
    };
  };
}
