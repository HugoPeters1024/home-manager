{ pkgs, lib, ...}:

{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "JetBrains Mono Nerd Font:size=16";
        shell = "${pkgs.zsh}/bin/zsh";
      };
    };
  };
}
