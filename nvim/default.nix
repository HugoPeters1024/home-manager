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
      nvim-web-devicons

      # LSP
      mason-nvim
      mason-lspconfig-nvim
      nvim-lspconfig
      fidget-nvim
      trouble-nvim

      # Autocompletion
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-path

      whitespace-nvim
      telescope-nvim
      telescope-fzf-native-nvim
      emmet-vim
      gitlinker-nvim
    ];

    extraLuaConfig = /* lua */ ''
      -- Basic settings
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
      vim.g.gitblame_enabled = 0

      -- Easy buffer navigation
      vim.keymap.set('n', '<C-h>', '<C-w>h', {noremap=true})
      vim.keymap.set('n', '<C-j>', '<C-w>j', {noremap=true})
      vim.keymap.set('n', '<C-k>', '<C-w>k', {noremap=false})
      vim.keymap.set('n', '<C-l>', '<C-w>l', {noremap=true})

      require("gitlinker").setup()

      vim.cmd('colorscheme nordfox')

      -- floating errors
      vim.diagnostic.config({
        virtual_text = {
          -- source = "always",  -- Or "if_many"
          prefix = '●', -- Could be '■', '▎', 'x'
        },
        severity_sort = true,
        float = {
          source = "always",  -- Or "if_many"
        },
      })

      -- autoremove whitespace on save
      local whitespace_nvim = require('whitespace-nvim')
      whitespace_nvim.setup({
        highlight = 'DiffDelete',
        ignored_filetypes = { 'TelescopePrompt', 'Trouble', 'help' },
      })
      vim.api.nvim_create_autocmd('BufWritePre', {
        pattern = '*',
        callback = function()
          whitespace_nvim.trim()
        end,
      })


      -- Persistent undo
      vim.api.nvim_exec([[
        if has('persistent_undo')
          set undofile
          set undodir=$HOME/.vim/undo
          endif
      ]], false)

      require('mason').setup({
        PATH = "append",
      })
      require("mason-lspconfig").setup()

      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local lspconfig = require('lspconfig')
      lspconfig.rust_analyzer.setup {
        capabilities = capabilities,
        -- Server-specific settings. See `:help lspconfig-setup`
        settings = {
          ['rust-analyzer'] = {},
        },
      }
      require("fidget").setup{}
      require("trouble").setup{}

      local bufopts = { noremap=true, silent=true }
      vim.keymap.set('n', 'qf', vim.lsp.buf.code_action, bufopts)
      vim.keymap.set('n', 'qr', vim.lsp.buf.format, bufopts)
      vim.keymap.set('n', 'gd', vim.lsp.buf.declaration, bufopts)
      vim.keymap.set('n', 'go', vim.lsp.buf.definition, bufopts)
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, bufopts)
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next, bufopts)
      vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, bufopts)


      -- nvim-cmp setup
      local cmp = require 'cmp'
      cmp.setup {
        mapping = cmp.mapping.preset.insert({
          ['<C-u>'] = cmp.mapping.scroll_docs(-4), -- Up
          ['<C-d>'] = cmp.mapping.scroll_docs(4), -- Down
          -- C-b (back) C-f (forward) for snippet placeholder navigation.
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          },
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = {
          { name = 'nvim_lsp' },
          { name = 'path' },
          { name = 'buffer' },
        },
      }

      require('telescope').load_extension('fzf')
	    local telescope = require('telescope.builtin')
	    vim.keymap.set('n', 'ff', telescope.find_files, {})
	    vim.keymap.set('n', 'fg', telescope.live_grep, {})
	    vim.keymap.set('n', 'fe', telescope.diagnostics, {})
	    vim.keymap.set('n', 'fd', telescope.commands, {})
    '';
  };
}
