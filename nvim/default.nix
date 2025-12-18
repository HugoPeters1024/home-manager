{ pkgs, lib, ...}:

let
  strudel-nvim =
    {
      plugin = pkgs.buildNpmPackage {
        pname = "strudel.nvim";
        version = "unstable-2025-09-17";

        src = pkgs.fetchFromGitHub {
          owner = "gruvw";
          repo = "strudel.nvim";
          rev = "3b83511d08f3b79bb7d6beb0d6f27fd375638604";
          sha256 = "sha256-86TlGElsIdpWZT3yUy7W7LoBeBqEgGHCm9nKuo/8zLo=";
        };

        npmDepsHash = "sha256-K016bVIMjO3972O67N3os/o3wryMyo5D244RhBNCvkY=";

        # Skip puppeteer's chrome download during build
        npmFlags = [ "--ignore-scripts" ];

        # Don't run npm install during build, just prepare the package
        dontNpmBuild = true;

        # Install the plugin files
        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -r * $out/
          runHook postInstall
        '';

        meta = with lib; {
          description = "A strudel.cc Neovim based controller, live coding using Strudel from Neovim";
          homepage = "https://github.com/gruvw/strudel.nvim";
          license = licenses.agpl3Only;
          maintainers = [ ];
          platforms = platforms.all;
        };
      };
      type = "nvim-lua";
    };
in
{
  home.packages = [
    pkgs.nil
    pkgs.typescript-language-server
    pkgs.nodejs # Required for strudel.nvim to work

    pkgs.ripgrep
    pkgs.fd # Fast file finder for Telescope
    pkgs.font-awesome
    pkgs.nerd-fonts.jetbrains-mono
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      plenary-nvim
      nightfox-nvim
      nvim-web-devicons
      overseer-nvim
      diffview-nvim
      neogit
      noice-nvim

      # Colorschemes
      gruvbox-nvim
      gruvbox-material-nvim
      everforest

      # LSP
      nvim-treesitter.withAllGrammars
      mason-nvim
      mason-lspconfig-nvim
      nvim-lspconfig
      fidget-nvim
      trouble-nvim

      # Git integration
      vim-fugitive
      vim-rhubarb
      fugitive-gitlab-vim

      # Autocompletion
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path

      smartyank-nvim
      whitespace-nvim
      telescope-nvim
      telescope-fzf-native-nvim
      emmet-vim
      gitlinker-nvim
      toggleterm-nvim
      strudel-nvim
      neo-tree-nvim
      transparent-nvim
      flatten-nvim

      # AI
      avante-nvim

      # Status line
      lualine-nvim
    ];

    extraLuaConfig = /* lua */ ''
      -- --------------
      -- Basic settings
      -- --------------
      vim.opt.wrap = false
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
      vim.o.scrollback = 100000
      vim.o.history = 10000
      vim.g.gitblame_enabled = 0

      vim.g.everforest_background = "hard"
      vim.cmd('colorscheme gruvbox')



      vim.g.fugitive_gitlab_domains = {'https://git.groq.io/'}

      -- --------------
      -- Status line
      -- --------------
      require('lualine').setup({
        options = {
          theme = 'gruvbox-material',
          component_separators = { left = "", right = ""},
          section_separators = { left = "", right = ""},
          disabled_filetypes = {
            statusline = {},
            winbar = {}
          },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = false,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
          }
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = { {'filename', path = 1 } },
          lualine_c = {},
          lualine_x = {'branch', 'encoding', 'filetype'},
          lualine_y = {},
          lualine_z = {}
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {'filename'},
          lualine_x = {},
          lualine_y = {},
          lualine_z = {}
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {}
      })

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

      -- ----------------------
      -- Tab navigation
      -- ----------------------
      vim.keymap.set('n', '<S-t>', ':tabnew<CR>', {noremap=true, silent=true})
      vim.keymap.set('n', '<S-h>', ':tabprevious<CR>', {noremap=true, silent=true})
      vim.keymap.set('n', '<S-l>', ':tabnext<CR>', {noremap=true, silent=true})

      local bufopts = { noremap=true, silent=true }

      -- --------------
      -- Custom Commands
      -- --------------
      vim.api.nvim_create_user_command('Bake', function(opts)
        local args = vim.split(opts.args, '%s+')
        local first_arg = args[1] or ""

        -- Expand % to current buffer filepath
        local expanded_args = opts.args:gsub('%%', vim.fn.expand('%'))

        if vim.tbl_contains({'test', 'r', 'run', 'run-on', 'build'}, first_arg) then
          -- Use Overseer for test and run commands
          local command = 'bake ' .. expanded_args
          vim.cmd('OverseerShell ' .. command)
        else
          -- Use terminal instead of read for other commands
          local command = 'bake ' .. expanded_args
          vim.cmd('tabnew')
          vim.cmd('terminal ' .. command)
        end
      end, { nargs = '*', complete = 'shellcmd' })

      vim.api.nvim_create_user_command('BakeBench', function(opts)
        local args = vim.split(opts.args, '%s+')
        local instances = args[1] or "20"
        local test = args[2] or ""

        if test == "" then
          vim.notify('BakeBench requires two arguments: instances and test name', vim.log.levels.ERROR)
          return
        end

        local command = '.buildkite/bin/flake-run-test-batch ' .. instances .. ' ' .. test
        vim.cmd('OverseerShell ' .. command)
      end, { nargs = '*', complete = 'shellcmd' })

      -- --------------
      -- Simple plugins
      -- --------------
      require("gitlinker").setup({
        opts = {
          -- Copy URL to clipboard instead of opening in browser (better for SSH)
          action_callback = require("gitlinker.actions").copy_to_clipboard,
          -- Print URL to command line as well
          print_url = true,
        },
        callbacks = {
          ["git.groq.io"] = require"gitlinker.hosts".get_gitlab_type_url,
        },
      })       -- GBrowse & friends
      require('transparent').setup()
      require('smartyank').setup({
        highlight = { timeout = 200 }
      })

      require("overseer").setup({
        task_list = {
          keymaps = {
            ["<C-j>"] = false, -- disable default <C-j>
            ["<C-k>"] = false, -- disable default <C-k>
            ["<C-h>"] = false, -- disable default <C-h>
            ["<C-l>"] = false, -- disable default <C-l>
          },
        },
        -- Override default component alias to remove automatic disposal
        component_aliases = {
          default = {
            "on_exit_set_status",
            "on_complete_notify",
            -- Removed "on_complete_dispose" to prevent automatic task disposal
          },
        },
      })

      vim.keymap.set('n', '<leader>t', ":OverseerToggle<CR>", bufopts)
      vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', bufopts)

      -- Git URL copying (works over SSH with smartyank)
      vim.keymap.set({'n', 'x', 'v'}, 'gy', '<cmd>lua require("gitlinker").get_buf_range_url("n")<cr><ESC>', { silent = true, desc = "Copy git URL to clipboard" })

      require("flatten").setup({
        window = {
          open = "tab", -- "alternate" or "current" or "vsplit" or "hsplit" or "tab"
        },
      })

      -- -------------
      -- Noice
      -- -------------

      require("noice").setup({
        lsp = {
          progress = {
            enabled = false,
          },
          -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
          },
        },
        -- you can enable a preset for easier configuration
        presets = {
          bottom_search = true, -- use a classic bottom cmdline for search
          command_palette = false, -- position the cmdline and popupmenu together
          long_message_to_split = true, -- long messages will be sent to a split
          inc_rename = false, -- enables an input dialog for inc-rename.nvim
          lsp_doc_border = true, -- add a border to hover docs and signature help
        },
        cmdline = {
          view = "cmdline_popup",
        },
        messages = {
          -- Disable search count hover (e.g., "abc 3/6")
          view_search = false,
        },
        views = {
          cmdline_popup = {
            position = {
              row = "80%",
              col = "50%",
            },
          },
          popupmenu = {
            relative = "editor",
            position = {
              row = "50%",
              col = "50%",
            },
            size = {
              width = 60,
              height = 10,
            },
            border = {
              style = "rounded",
              padding = { 0, 1 },
            },
            win_options = {
              winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
            },
          },
          confirm = {
            position = {
              row = "80%",
              col = "50%",
            },
          },
        },
      })

      -- --------
      -- Terminal
      -- --------
      require("toggleterm").setup({
        shell = "${pkgs.zsh}/bin/zsh",
      })
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
          format = function(diagnostic)
            -- Wrap long messages
            local message = diagnostic.message
            if #message > 80 then
              return message:sub(1, 77) .. "..."
            end
            return message
          end,
        },
        severity_sort = true,
        float = {
          source = "always",  -- Or "if_many"
          wrap = true,
          max_width = 80,
          border = "rounded",
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
      require('telescope').setup({
        defaults = {
          -- Performance optimizations for large monorepos
          file_ignore_patterns = {
            "node_modules",
            ".git/",
            "%.lock",
            "%.png",
            "%.jpg",
            "%.jpeg",
            "%.gif",
            "%.webp",
            "%.svg",
            "%.ico",
            "%.pdf",
            "%.zip",
            "%.tar.gz",
            "%.DS_Store",
            "__pycache__",
            "%.pyc",
            "%.o",
            "%.a",
            "%.so",
            "%.dylib",
            "target/",        -- Rust build artifacts
            "build/",         -- Common build directory
            "dist/",          -- Common dist directory
            "%.egg%-info/",   -- Python egg info
            "%.tox/",         -- Python tox
            ".venv/",         -- Python venv
            "venv/",          -- Python venv
          },
          -- Performance: only show first N results initially
          cache_picker = {
            num_pickers = 10,
          },
          -- Faster file preview
          preview = {
            timeout = 200,
            filesize_limit = 1, -- MB
          },
          -- Better performance with many results
          scroll_strategy = "limit",
        },
        pickers = {
          command_history = {
            -- Use fuzzy_with_index_bias to maintain chronological order
            -- This sorter considers when items were added, perfect for command history
            sorter = require('telescope.sorters').fuzzy_with_index_bias(),
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          }
        }
      })

      require('telescope').load_extension('fzf')
	    local telescope = require('telescope.builtin')
      -- Smart file finder: use git_files in git repos (much faster in monorepos),
      -- fallback to find_files if not in a git repo
      vim.keymap.set('n', 'ff', function()
        local ok, _ = pcall(telescope.git_files, { show_untracked = true })
        if not ok then
          telescope.find_files()
        end
      end, { desc = "Find files (git-aware)" })
      -- Keep find_files available for searching all files including untracked
      vim.keymap.set('n', 'fF', telescope.find_files, { desc = "Find all files" })
	    vim.keymap.set('n', 'fg', telescope.live_grep, {})
      vim.keymap.set('n', 'fe', function() telescope.diagnostics({ initial_mode = 'normal'}) end, {})
	    vim.keymap.set('n', 'fd', telescope.commands, {})
      vim.keymap.set('n', 'fh', function() 
        telescope.command_history({ initial_mode = 'insert' }) 
      end, {})
      vim.keymap.set('n', 'fc', function() telescope.commands ({ initial_mode = 'insert' }) end, {})
      vim.keymap.set('n', 'fs', function() telescope.buffers({ initial_mode = 'normal'}) end, {})
      vim.keymap.set('n', 'gs', function() telescope.git_status({ initial_mode = 'normal'}) end, {})
      vim.keymap.set('n', 'f<space>', telescope.resume, {})

      -- ---------------
      -- Neogit
      -- ---------------
      require("neogit").setup({
        integrations = {
          diffview = true,
        }
      })

      vim.keymap.set('n', '<leader>gg', ":Neogit<CR>", bufopts)
      vim.keymap.set('n', '<leader>gd', function()
        local view = require('diffview.lib').get_current_view()
        if view then
          vim.cmd('DiffviewClose')
        else
          vim.cmd('DiffviewOpen')
        end
      end, bufopts)
      vim.keymap.set('n', '<leader>gb', function() telescope.git_branches({ initial_mode = 'normal'}) end, {})

      -- ---------------
      -- Neotree
      -- ---------------
      require("neo-tree").setup({
        window = {
          mappings = {
            ["f"] = "none", -- Disable 'f' to allow 'ff' for telescope
          },
        },
        filesystem = {
          follow_current_file = {
            enabled = true
          },
        },
      })


      -- ----------------
      -- LSP
      -- ----------------
      require('mason').setup({ PATH = "append" })
      require("mason-lspconfig").setup()

      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      vim.lsp.config("rust_analyzer", {
        capabilities = capabilities,
        -- Server-specific settings. See `:help lspconfig-setup`
        settings = {
          ['rust-analyzer'] = {},
        },
      })
      vim.lsp.enable("rust_analyzer")

      vim.lsp.config("hls", {
        capabilities = capabilities,
        -- Server-specific settings. See `:help lspconfig-setup`
        settings = {
          ['hls'] = {
            manageHLS = "PATH"
          },
        },
      })
      vim.lsp.enable("hls")

      vim.lsp.config("pyright", {
        capabilities = capabilities,
        -- Server-specific settings. See `:help lspconfig-setup`
        settings = {
          ['pyright'] = {
          },
        },
      })
      vim.lsp.enable("pyright")

      vim.lsp.config("ruff", {
        capabilities = capabilities,
        init_options = {
          settings = {
            -- Server settings should go here
          }
        }
      })
      vim.lsp.enable("ruff")

      vim.lsp.config("nil_ls", { capabilities = capabilities, })
      vim.lsp.enable("nil_ls")

      vim.lsp.config("ts_ls", { capabilities = capabilities, })
      vim.lsp.enable("ts_ls")

      vim.lsp.config("clangd", { capabilities = capabilities, })
      vim.lsp.enable("clangd")

      require("fidget").setup{}
      require("trouble").setup{}
      require('nvim-treesitter.configs').setup { highlight = { enable = true } }

      vim.keymap.set('n', 'qf', vim.lsp.buf.code_action, bufopts)
      vim.keymap.set('n', 'qr', vim.lsp.buf.format, bufopts)
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
      vim.keymap.set('n', 'go', vim.lsp.buf.type_definition, bufopts)
      vim.keymap.set('n', 'gr', function() telescope.lsp_references({ initial_mode = 'normal'}) end, bufopts)
      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, bufopts)
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next, bufopts)
      vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, bufopts)
      vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, bufopts)

      -- --------
      -- AI
      -- --------
      require("avante").setup({
        provider = "claude",
        behaviour = {
          auto_set_keymaps = false, -- Disable automatic keymaps to avoid conflicts
        },
        providers = {
          claude = {
            endpoint = "https://api.anthropic.com",
            model = "claude-sonnet-4-5-20250929",
            timeout = 30000,
            extra_request_body = {
              temperature = 0.75,
              max_tokens = 64000,
            },
          },
        },
      })
      -- Set only the keymaps you want
      vim.keymap.set('n', '<leader>a', ':AvanteToggle<CR>', {noremap=true, silent=true, desc="Avante: Toggle"})
      vim.keymap.set('v', '<C-a>', ':AvanteEdit<CR>', {noremap=true, silent=true, desc="Avante: Edit"})

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

      -- -------
      -- Strudel
      -- -------
      local strudel = require("strudel")
      strudel.setup({
        -- Configure to use system Brave
        browser_exec_path = "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
      })

      -- Setup keybindings for Strudel files (*.str extension)
      local strudel_marker_augroup = vim.api.nvim_create_augroup('StrudelFileSetup', { clear = true })
      vim.api.nvim_create_autocmd('BufRead', {
        group = strudel_marker_augroup,
        pattern = '*',
        desc = "Setup Strudel keybindings for .str files",
        callback = function(args)
          local bufnr = args.buf
          -- Ensure buffer is valid and still exists
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return
          end

          -- Check if the file actually has .str extension
          local filename = vim.api.nvim_buf_get_name(bufnr)
          if not filename:match("%.str$") then
            return
          end

          vim.keymap.set("n", "<C-0>", strudel.launch, { desc = "Launch Strudel", buffer = bufnr })
          --vim.keymap.set("n", "<leader>sq", strudel.quit, { desc = "Quit Strudel", buffer = bufnr })
          vim.keymap.set("n", "<C-y>", strudel.toggle, { desc = "Strudel Toggle Play/Stop", buffer = bufnr })
          --vim.keymap.set("n", "<leader>su", strudel.update, { desc = "Strudel Update", buffer = bufnr })
          --vim.keymap.set("n", "<leader>ss", strudel.stop, { desc = "Strudel Stop Playback", buffer = bufnr })
          --vim.keymap.set("n", "<leader>sb", strudel.set_buffer, { desc = "Strudel set current buffer", buffer = bufnr })
          vim.keymap.set("n", "<C-CR>", strudel.execute, { desc = "Strudel set current buffer and update", buffer = bufnr })
          vim.keymap.set("n", "<S-CR>", strudel.execute, { desc = "Strudel set current buffer and update", buffer = bufnr })
        end,
      })
    '';
  };
}
