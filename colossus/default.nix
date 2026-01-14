{
  pkgs,
  lib,
  config,
  ...
}:
let
  python = pkgs.python311;

  colossus-cli = python.pkgs.buildPythonPackage rec {
    pname = "colossus-cli";
    version = "2.2.47";
    format = "setuptools";

    src = pkgs.fetchurl {
      url = "https://urm.nvidia.com/artifactory/api/pypi/sw-colossus-pypi/colossus-cli/${version}/colossus-cli-${version}.tar.gz";
      sha256 = "d3fdf8cfd502a02344d69688a22d7a7b39a0e1dd2e6405d8188188b69dc35829";
    };

    propagatedBuildInputs = with python.pkgs; [
      configparser
      python-dateutil
      prettytable
      requests
      six
      urllib3
      pyjwt
      argcomplete
    ];

    # No tests in the package
    doCheck = false;

    pythonImportsCheck = [ "colossus" ];
  };

  pythonWithColossus = python.withPackages (ps: [
    colossus-cli
    ps.argcomplete
    ps.chardet
    ps.packaging
    ps.pyyaml
    ps.tqdm
  ]);
in
{
  options.programs.colossus = {
    enable = lib.mkEnableOption "Colossus CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pythonWithColossus;
      description = "The colossus package to use (includes Python with colossus-cli and argcomplete)";
    };
  };

  config = lib.mkIf config.programs.colossus.enable {
    home.packages = [ config.programs.colossus.package ];
  };
}
