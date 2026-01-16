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
      self,
      nixpkgs,
      home-manager,
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
        overlays = [ ];
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

        "hugop@JT7RVG63RY" = home-manager.lib.homeManagerConfiguration {
          pkgs = m1pkgs;
          modules = [
            ./nvim/default.nix
            ./zsh/default.nix
            ./tmux/default.nix
            ./kitty/default.nix
            ./wezterm/default.nix
            ./colossus/default.nix
            {
              programs.colossus.enable = true;

              home.packages = [
                m1pkgs.home-manager
                m1pkgs.wezterm
                m1pkgs.bottom
                m1pkgs.nerd-fonts.jetbrains-mono
                m1pkgs.direnv
                m1pkgs.nix-output-monitor
                m1pkgs.tree
                m1pkgs.nix-tree
                m1pkgs.nix-direnv
                m1pkgs.vscode
                m1pkgs.google-cloud-sdk
              ];
              home.username = "hugop";
              home.homeDirectory = "/Users/hugop";
              home.sessionVariables = {
                EDITOR = "nvim";
                TERMINAL = "wezterm";
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

              programs.git = {
                enable = true;
                settings = {
                  user.email = "hugop@nvidia.com";
                  user.name = "HugoPeters1024";
                };
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

        "hpeters@hpeters" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs;
          modules = [
            ./nvim/default.nix
            ./zsh/default.nix
            {
              home.packages = [
                pkgs.home-manager
                pkgs.nerd-fonts.jetbrains-mono
              ];
              home.username = "hpeters";
              home.homeDirectory = "/home/hpeters";
              home.sessionVariables = {
                EDITOR = "nvim";
                TERMINAL = "wezterm";
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
