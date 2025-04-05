{ pkgs, lib, ...}:

let
  tidal-nvim =
    {
      plugin = pkgs.fetchFromGitHub {
        owner = "tidalcycles";
        repo = "vim-tidal";
        rev = "e440fe5bdfe07f805e21e6872099685d38e8b761"; # Replace with a specific commit for stability
        sha256 = "sha256:102j93zygjkrxgdxcsv4nqhnrfn1cbf4djrxlx5sly0bnvbs837j"; # Get this using nix-prefetch-git
      };
      type = "vim";
      config = ''
      '';
    };
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
      toggleterm-nvim
      tidal-nvim
    ];

    extraLuaConfig = /* lua */ ''
      -- --------------
      -- Basic settings
      -- --------------
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
      vim.opt.signcolumn = "yes"
      vim.o.termguicolors = true
      vim.g.gitblame_enabled = 0

      vim.cmd('colorscheme nordfox')

      -- Use gj/gk for j/k when no count is provided (visual line movement)
      -- Otherwise, use regular j/k (logical line movement)

      -- Mapping for 'j'
      vim.keymap.set({'n', 'v', 'o'}, 'j', function()
        if vim.v.count == 0 then return 'gj' else return 'j' end
      end, { expr = true, silent = true, noremap = true, desc = "Move down visual line (gj) if no count" })

      -- Mapping for 'k'
      vim.keymap.set({'n', 'v', 'o'}, 'k', function()
        if vim.v.count == 0 then return 'gk' else return 'k' end
      end, { expr = true, silent = true, noremap = true, desc = "Move up visual line (gk) if no count" })

      -- ----------------------
      -- Easy buffer navigation
      -- ----------------------
      vim.keymap.set('n', '<C-h>', '<C-w>h', {noremap=true})
      vim.keymap.set('n', '<C-j>', '<C-w>j', {noremap=true})
      vim.keymap.set('n', '<C-k>', '<C-w>k', {noremap=false})
      vim.keymap.set('n', '<C-l>', '<C-w>l', {noremap=true})

      local bufopts = { noremap=true, silent=true }

      -- --------------
      -- Simple plugins
      -- --------------
      require("gitlinker").setup()       -- GBrowse & friends
      vim.keymap.set('n', 'gb', ':Git blame<CR>', {noremap=true})

      -- ------------
      -- Tidal Cycles
      -- ------------

      -- If a haskell file starts with the magic string on the first line, enable tidal mode
      local tidal_magic_string = "-- enable tidalmode"
      local tidal_marker_augroup = vim.api.nvim_create_augroup('TidalMagicMarkerSetup', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        group = tidal_marker_augroup,
        pattern = 'haskell', -- Trigger *only* when filetype is set to haskell
        desc = "Check for Tidal magic marker in Haskell files",
        callback = function(args)
          local bufnr = args.buf
          -- Ensure buffer is valid and still exists
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return
          end

          -- Read the first line of the buffer
          local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false) -- Get line 0 (the first line)

          if #lines > 0 then
            -- Trim leading/trailing whitespace for robustness
            local first_line = vim.trim(lines[1])

            -- Check if the first line matches the magic string
            if first_line == tidal_magic_string then
              -- If it matches, apply the buffer-local Tidal settings
              vim.b.tidal_no_mappings = 1
              vim.keymap.set('n', '<S-l>', ':TidalSend<CR>', opts)
              vim.keymap.set('v', '<S-l>', ':TidalSend<CR>', opts)
              vim.keymap.set('n', '<S-o>', ':TidalHush<CR>', opts)
            end
            -- Optional: If the line *doesn't* match, you could potentially *remove*
            -- Tidal settings here if needed, but that adds complexity. Usually,
            -- just applying them when the marker is present is sufficient.
          end
        end,
      })


      -- --------
      -- Terminal
      -- --------
      require("toggleterm").setup()
      function _G.set_terminal_keymaps()
        local opts = {buffer = 0}
        vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
        vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
        vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
        vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
        vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
        vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
      end
      -- if you only want these mappings for toggle term use term://*toggleterm#* instead
      vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
      vim.keymap.set('n', '`', ':ToggleTerm direction=horizontal<CR>', bufopts)
      vim.keymap.set('n', '~', ':ToggleTerm direction=float<CR>', bufopts)


      -- ---------------
      -- Floating errors
      -- ---------------
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

      -- -----------------------------
      -- autoremove whitespace on save
      -- ----------------------------
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


      -- ---------------
      -- Persistent undo
      -- ---------------
      if vim.fn.has('persistent_undo') == 1 then
        vim.opt.undofile = true
        local undo_dir = vim.fn.expand('~/.vim/undo')
        vim.opt.undodir = undo_dir

        -- Optional but recommended: Create the directory if it doesn't exist
        -- vim.fn.isdirectory returns 0 for false, 1 for true
        if vim.fn.isdirectory(undo_dir) == 0 then
          vim.fn.mkdir(undo_dir, 'p')
          vim.notify('Created undo directory: ' .. undo_dir, vim.log.levels.INFO)
        end
      end

      -- ---------
      -- Telescope
      -- ---------
      require('telescope').load_extension('fzf')
	    local telescope = require('telescope.builtin')
	    vim.keymap.set('n', 'ff', telescope.find_files, {})
	    vim.keymap.set('n', 'fg', telescope.live_grep, {})
	    vim.keymap.set('n', 'fe', telescope.diagnostics, {})
	    vim.keymap.set('n', 'fd', telescope.commands, {})
      vim.keymap.set('n', 'fh', telescope.current_buffer_fuzzy_find, {})

      -- ----------------
      -- LSP
      -- ----------------
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

      lspconfig.hls.setup {
        capabilities = capabilities,
        -- Server-specific settings. See `:help lspconfig-setup`
        settings = {
          ['hls'] = {
            manageHLS = "PATH"
          },
        },
      }

      lspconfig.pyright.setup {
        capabilities = capabilities,
        -- Server-specific settings. See `:help lspconfig-setup`
        settings = {
          ['pyright'] = {
          },
        },
      }

      require("fidget").setup{}
      require("trouble").setup{}
      require('nvim-treesitter.configs').setup { highlight = { enable = true }, ... }

      vim.keymap.set('n', 'qf', vim.lsp.buf.code_action, bufopts)
      vim.keymap.set('n', 'qr', vim.lsp.buf.format, bufopts)
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
      vim.keymap.set('n', 'go', vim.lsp.buf.type_definition, bufopts)
      vim.keymap.set('n', 'gr', telescope.lsp_references, bufopts)
      vim.keymap.set('n', 'gr', function() telescope.lsp_references({ initial_mode = 'normal'}) end, bufopts)
      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, bufopts)
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next, bufopts)
      vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, bufopts)

      -- ------------------
      -- LSP Autocompletion
      -- ------------------
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
    '';
  };
}
