# How to use

first follow the basic home manager instructions, which including adding its nix channel

install the following packages, which won't work well through nix, we'll still configure
them using home manager though.

Currently works with sway version 1.9.
Newer versions don't seem to work at the moment :/

```
sudo apt install sway, swaylock, fonts-font-awesome, pavucontrol, wdisplays, xdg-desktop-portal-wlr
```

create /etc/nix/configuration:

```
security.polkit.enable = true
```

add the nixgl channel (double check the home manager installation guide for this step)

```
nix-channel --add https://github.com/nix-community/nixGL/archive/main.tar.gz nixgl && nix-channel --update
```

enable the config by running

```
home-manager switch
```


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
