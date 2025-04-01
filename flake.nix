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
  outputs = { self, nixpkgs, home-manager, nixGL, ... }@inputs:
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
        # Apply nixGL overlay if needed
        overlays = [ nixGL.overlay ]; # Remove this line if you don't need nixGL
        # Add other configurations if needed
        config = { allowUnfree = true; }; # Example
      };

    in {
      # Define the Home Manager configuration output
      homeConfigurations."${username}@${hostname}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # List your Home Manager modules here
        # The primary one is usually home.nix
        modules = [
          ./home.nix
          # Add paths to other custom modules if you have them:
          # ./modules/my-custom-settings.nix
        ];

        # Optionally pass extra arguments to your modules
        # extraSpecialArgs = { inherit inputs; }; # If modules need access to flake inputs
      };

      # You could add other outputs here like packages, apps, etc.
      devShells.x86_64-linux.default = pkgs.mkShell {
        name = "home-manager-config-shell";
        packages = [
          # Use the pkgs defined above, which comes from the flake's nixpkgs input
          pkgs.home-manager
          # You could add other useful tools here, like git, vim, etc.
          # pkgs.git
        ];
      };
    };
}
