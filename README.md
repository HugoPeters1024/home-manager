# How to use

first follow the basic home manager instructions, which including adding its nix channel

install the following packages, which won't work well through nix, we'll still configure
them using home manager though.

Currently works with sway version 1.9.
Newer versions don't seem to work at the moment :/

```
sudo apt install sway, swaylock, fonts-font-awesome, pavucontrol, wdisplays, xdg-desktop-portal-wlr, blueman, pipewire-jack
```

create /etc/nix/configuration:

```
security.polkit.enable = true
```

enable the config by running (might have to `nix develop` the first time)

```
home-manager switch
```

### I'm trying flakes

maybe this works? (replace hostname)

```
home-manager switch --flake '.#hugo@<hostname>'


### Nuggets:

sway wrapper script to make it work on my laptop with an RTX 3070 and the 570 driver:

```sh
#!/bin/sh
export WLR_RENDERER=vulkan
export WLR_NO_HARDWARE_CURSORS=1
export WLR_NO_GLAMOR=1
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __GL_GSYNC_ALLOWED=0
export __GL_VRR_ALLOWED=0
export MOZ_ENABLED_WAYLAND=1
export XDG_SESSION=wayland
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export MOZ_USE_XINPUT2=1

exec sway --unsupported-gpu
```

to be called from /usr/share/wayland-sessions/sway.desktop
