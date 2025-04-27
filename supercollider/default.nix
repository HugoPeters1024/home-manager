{ pkgs, lib, ...}:

{
  home.file.".config/SuperCollider/startup.scd".source = ./startup.scd;
  home.file.".config/SuperCollider/synths" = {
    source = ./synths;
    recursive = true;
  };
}
