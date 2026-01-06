{
  description = "Hugo's Home Manager Flake";

  # Define dependencies (inputs)
  inputs = {
    # Nixpkgs (main package set) - Choose your branch!
    # Example: nixos-24.11 (once available), release-24.05, or nixos-unstable
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # <-- ADJUST THIS BRANCH!

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/master"; # <-- ADJUST THIS BRANCH!
      # Make HM use the same nixpkgs we defined above
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Define outputs (what this flake provides)
  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }:
    let
      x86pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ ];
      };

      m1pkgs = import nixpkgs {
        system = "aarch64-darwin";
        overlays = [ ];
      };
    in
    {
      homeConfigurations = {
        "hpeters@Mac" = home-manager.lib.homeManagerConfiguration {
          pkgs = m1pkgs;
          modules = [
            ./zsh/default.nix
            ./nvim/default.nix
            {
              home.packages = [
                m1pkgs.home-manager
                m1pkgs.bottom
                m1pkgs.nerd-fonts.jetbrains-mono
              ];
              home.username = "hpeters";
              home.homeDirectory = "/Users/hpeters";
              home.sessionVariables = {
                EDITOR = "nvim";
                SHELL = "/bin/zsh";
              };

              # Set the default shell to /bin/zsh
              programs.bash.enable = false;
              programs.zsh.enable = true;
              programs.zsh.shellAliases = {
                ll = "ls -la";
                la = "ls -A";
                l = "ls -CF";
              };

              # This value determines the Home Manager release that your configuration is
              # compatible with. This helps avoid breakage when a new Home Manager release
              # introduces backwards incompatible changes.
              #
              # You should not change this value, even if you update Home Manager. If you do
              # want to update the value, then make sure to first check the Home Manager
              # release notes.
              home.stateVersion = "24.11"; # Please read the comment before changing.
            }
          ];
        };

      };

      devShells.x86_64-linux.default = x86pkgs.mkShell {
        name = "home-manager-config-shell";
        packages = [
          x86pkgs.home-manager
        ];
      };

      devShells.aarch64-darwin.default = m1pkgs.mkShell {
        name = "home-manager-config-shell-mac";
        packages = [
          m1pkgs.home-manager
        ];
      };
    };
}
