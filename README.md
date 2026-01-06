# My Home Manager Setup

Clone this repo to `~/.config/home-manager`, it has to be there

The only thing you need beforehand is nix itself. The very first time you will have to run

```sh
nix develop
```

to drop into a nix shell with home-manager installed. Then run

```sh
home-manager switch
```

to install all applications and apply the configurations you have defined. This will also install home-manager itself system wide,
so next time you don't even have to run `nix develop` anymore.


