{ pkgs, lib, ...}:

let
  fromGitHub = import ../functions/fromGitHub.nix;
in

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      plenary-nvim
      nvim-treesitter.withAllGrammars
      nightfox-nvim
      mason-nvim
      telescope-nvim
      telescope-fzf-native-nvim
    ];

    extraLuaConfig = /* lua */ ''
      vim.opt.cursorline = true
      vim.opt.cursorlineopt = "number"
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.softtabstop = 2
      vim.opt.expandtab = true
      vim.opt.relativenumber = true
      vim.opt.nu = true
      vim.opt.scrolloff = 8
      vim.opt.smarttab = true

      vim.o.termguicolors = true
      vim.cmd('colorscheme nightfox')

      require("mason").setup()

      require('telescope').load_extension('fzf')
	    local telescope = require('telescope.builtin')
	    vim.keymap.set('n', 'ff', telescope.find_files, {})
	    vim.keymap.set('n', 'fg', telescope.live_grep, {})
	    vim.keymap.set('n', 'fe', telescope.diagnostics, {})
	    vim.keymap.set('n', 'fd', telescope.commands, {})
    '';
  };
}
