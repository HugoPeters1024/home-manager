{
  pkgs,
  lib,
  config,
  ...
}:
let
  python = pkgs.python312;

  colossus-cli = python.pkgs.buildPythonPackage rec {
    pname = "colossus-cli";
    version = "2.2.53";
    format = "setuptools";

    src = pkgs.fetchurl {
      url = "https://urm.nvidia.com/artifactory/api/pypi/sw-colossus-pypi/colossus-cli/${version}/colossus-cli-${version}.tar.gz";
      sha256 = "c71caf8ed4e21d51e5a4d615b7691a5c6bb9ab56f427fdfaf6a3ef1740a9dc3e";
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

  # Pre-generate the argcomplete script at build time
  colossusCompletion = pkgs.runCommand "colossus-completion" {
    nativeBuildInputs = [ pythonWithColossus ];
  } ''
    register-python-argcomplete colossus > $out
  '';
in
{
  options.programs.colossus = {
    enable = lib.mkEnableOption "Colossus CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pythonWithColossus;
      description = "The colossus package to use (includes Python with colossus-cli and argcomplete)";
    };

    completionScript = lib.mkOption {
      type = lib.types.path;
      default = colossusCompletion;
      description = "Pre-generated argcomplete script for colossus";
      readOnly = true;
    };
  };

  config = lib.mkIf config.programs.colossus.enable {
    home.packages = [ config.programs.colossus.package ];
  };
}
