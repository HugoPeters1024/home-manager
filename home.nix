{ config, lib, pkgs, ... }:

let
  cmd-half-monitor-width = pkgs.writeShellScriptBin "cmd-half-monitor-width" ''
    swaymsg -t get_workspaces | jq -r ".[] | select(.focused==true).rect.width" | awk '{ print $1/2 }'
  '';
  cmd-half-monitor-height = pkgs.writeShellScriptBin "cmd-half-monitor-height" ''
    swaymsg -t get_workspaces | jq -r ".[] | select(.focused==true).rect.height" | awk '{ print $1/2 }'
  '';
in

{
  nixpkgs.config = {
    allowUnfreePredicate = pkg: true;
  };
  # Requires adding the nixgl channel:
  # nix-channel --add https://github.com/nix-community/nixGL/archive/main.tar.gz nixgl && nix-channel --update
  # nixGL.packages = import <nixgl> { inherit pkgs; };
  # nixGL.defaultWrapper = "mesa";
  # nixGL.offloadWrapper = "nvidiaPrime";
  # nixGL.installScripts = [ "mesa" "nvidiaPrime" ];


  imports = [
    ./sway
    ./nvim
    ./zsh
    (import ./foot { inherit pkgs lib config cmd-half-monitor-width cmd-half-monitor-height; })
    ./supercollider
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "hugo";
  home.homeDirectory = "/home/hugo";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    cmd-half-monitor-width
    cmd-half-monitor-height
    pkgs.foot
    pkgs.direnv
    pkgs.ripgrep
    pkgs.bottom
    pkgs.brightnessctl
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.font-awesome
    pkgs.xdg-desktop-portal-wlr
    pkgs.xdg-desktop-portal
    pkgs.wlr-randr
    pkgs.asciiquarium
    pkgs.nil
    pkgs.swaybg
    pkgs.qpwgraph

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  fonts.fontconfig.enable = true;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/hugo/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "vi";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userEmail = "hugopeters1024@gmail.com";
    userName = "HugoPeters1024";
  };
}
