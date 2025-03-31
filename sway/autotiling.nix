{ config, pkgs, ... }:

let
  myPythonEnv = pkgs.python3.withPackages (ps: with ps; [
    i3ipc
  ]);
in
{
  home.packages = [
    myPythonEnv
  ];

  home.file.".config/sway/autotiling" = {
    text = ''
      #!${myPythonEnv}/bin/python
      ${builtins.readFile ./autotiling.py}
    '';
    executable = true;
  };
}
