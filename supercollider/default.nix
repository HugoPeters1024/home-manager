{ pkgs, lib, ...}:

{
  home.file.".config/SuperCollider/startup.scd".source = ./startup.scd;
}
