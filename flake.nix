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

    # NixGL (if you still need it)
    nixGL = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs"; # Make nixGL use the same nixpkgs
    };
  };

  # Define outputs (what this flake provides)
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixGL,
      ...
    }@inputs:
    let
      # Define system architecture(s) you use
      # Find yours with: nix eval --raw '(builtins.currentSystem)'
      system = "x86_64-linux"; # <--- ADJUST THIS (e.g., "aarch64-linux", "x86_64-darwin", "aarch64-darwin")

      # Define username and hostname for configuration key
      # Find hostname with: hostname
      username = "hugo";
      hostname = "dev-lt-82"; # <--- ADJUST THIS

      # Define pkgs with overlays (if needed)
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nixGL.overlay ]; # Remove this line if you don't need nixGL
        config = {
          allowUnfree = true;
        }; # Example
      };

      m1pkgs = import nixpkgs {
        system = "aarch64-darwin";
        overlays = [ ];
        config = {
          allowUnfree = true;
        }; # Example
      };
    in
    {
      homeConfigurations = {
        "hugo@dev-lt-82" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix ];
        };

        "hugo@legion" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home.nix
            {
              home.packages = with pkgs; [
                (writeShellScriptBin "fix-displays.sh" ''
                  #!/usr/bin/env sh
                  # Set the refresh rate and orientation
                  ${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --mode 2560x1600@165.018997 --pos 0,560
                  ${pkgs.wlr-randr}/bin/wlr-randr --output HDMI-A-1 --pos 2560,0
                '')
              ];
            }
          ];
        };

        "hpeters@Hugos-MacBook-Pro" = home-manager.lib.homeManagerConfiguration {
          pkgs = m1pkgs;
          modules = [
            ./nvim/default.nix
            ./zsh/default.nix
            ./kitty/default.nix
            {
              home.packages = [ m1pkgs.home-manager ];
              home.username = "hpeters";
              home.homeDirectory = "/Users/hpeters";
              home.sessionVariables = {
                EDITOR = "nvim";
                TERMINAL = "kitty";
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

      devShells.x86_64-linux.default = pkgs.mkShell {
        name = "home-manager-config-shell";
        packages = [
          pkgs.home-manager
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
