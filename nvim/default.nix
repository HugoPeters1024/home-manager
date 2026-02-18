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
      solarized-nvim

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
      vim-tmux-navigator

      # AI
      avante-nvim

      # Status line
      lualine-nvim
    ];

    initLua = /* lua */ ''
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

      -- Treat .maxj files as Java files
      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = "*.maxj",
        callback = function()
          vim.bo.filetype = "java"
        end,
      })

      -- Register .str files as JavaScript for filetype detection and treesitter
      vim.filetype.add({
        extension = {
          str = "javascript",
        },
      })

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
      -- Easy buffer navigation (vim-tmux-navigator handles this)
      -- ----------------------
      -- vim-tmux-navigator provides seamless navigation between vim splits and tmux panes
      -- using Ctrl+h/j/k/l. The plugin handles the keymaps automatically.
      -- vim.keymap.set('n', '<C-h>', '<C-w>h', {noremap=true})
      -- vim.keymap.set('n', '<C-j>', '<C-w>j', {noremap=true})
      -- vim.keymap.set('n', '<C-k>', '<C-w>k', {noremap=false})
      -- vim.keymap.set('n', '<C-l>', '<C-w>l', {noremap=true})

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

        if vim.tbl_contains({'test', 'r', 'run', 'run-on', 'rebuild-on', 'build'}, first_arg) then
          -- Use Overseer for test and run commands
          local command = 'bake ' .. expanded_args
          vim.cmd('OverseerShell ' .. command)
        else
          -- Use terminal instead of read for other commands
          local command = 'bake ' .. expanded_args
          if first_arg == 'log' then
            command = 'brake ' .. expanded_args
          end
          vim.cmd('tabnew')
          vim.cmd('terminal ' .. command)
        end
      end, { nargs = '*', complete = 'shellcmd' })

      vim.api.nvim_create_user_command('Cargo', function(opts)
        local args = vim.split(opts.args, '%s+')

        local expanded_args = opts.args:gsub('%%', vim.fn.expand('%'))
        local command = 'cargo ' .. expanded_args
        vim.cmd('OverseerShell ' .. command)
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
          notify = {
            position = {
              row = "50%",
              col = "50%",
            },
            size = {
              width = nil,  -- Fit content width
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
          max_width = nil,  -- No width limit, will fit text content
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

      vim.lsp.config("clangd", {
        capabilities = capabilities,
        cmd = { "clangd", "-j=8", "--malloc-trim", "--background-index", "--pch-storage=memory" },
      })
      vim.lsp.enable("clangd")


      vim.lsp.config("jdtls", {
        capabilities = capabilities,
        cmd = { "jdtls" },
      });
      vim.lsp.enable("jdtls")

      require("fidget").setup{}
      require("trouble").setup{}

      -- Treesitter: just configure the install directory
      -- Queries and parsers are already provided by nixpkgs
      require('nvim-treesitter.config').setup {}

      -- Enable treesitter highlighting for buffers with available parsers
      -- In Neovim 0.10+, this needs to be explicitly started
      vim.api.nvim_create_autocmd({'FileType', 'BufEnter'}, {
        callback = function(args)
          local buf = args.buf
          local ft = vim.bo[buf].filetype

          -- Skip if already active or no filetype
          if vim.treesitter.highlighter.active[buf] or ft == "" then
            return
          end

          -- Only start if a parser is available for this filetype
          local lang = vim.treesitter.language.get_lang(ft) or ft
          if pcall(vim.treesitter.language.add, lang) then
            pcall(vim.treesitter.start, buf, lang)
          end
        end,
      })

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
        provider = "nvidia",
        behaviour = {
          auto_set_keymaps = false,
        },
        vendors = {
          nvidia = {
            __inherited_from = "openai",
            endpoint = "https://inference-api.nvidia.com/v1",
            model = "aws/anthropic/bedrock-claude-sonnet-4-6",
            api_key_name = "NVIDIA_API_KEY",
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

      -- Strudel Telescope Pickers
      -- Queries available sounds/functions from the active Strudel browser session
      -- via Chrome DevTools Protocol and presents them in a Telescope picker.
      local strudel_query_script = "${./strudel-sounds.js}"

      -- Helper: insert text at cursor position
      local function insert_at_cursor(text)
        local cursor = vim.api.nvim_win_get_cursor(0)
        local line = vim.api.nvim_get_current_line()
        local col = cursor[2]
        local before = line:sub(1, col)
        local after = line:sub(col + 1)
        vim.api.nvim_set_current_line(before .. text .. after)
        vim.api.nvim_win_set_cursor(0, { cursor[1], col + #text })
      end

      -- Helper: preview a sound by triggering a one-shot in the Strudel browser
      -- Accepts optional sample index n (0-based)
      local function strudel_preview_sound(name, n)
        local cmd = { "node", strudel_query_script, "preview", name }
        if n then table.insert(cmd, tostring(n)) end
        vim.fn.jobstart(cmd, {
          stdout_buffered = true,
          on_stderr = function(_, data)
            if data and data[1] and data[1] ~= "" then
              vim.schedule(function()
                vim.notify("Preview: " .. table.concat(data, "\n"), vim.log.levels.WARN)
              end)
            end
          end,
        })
      end

      -- Helper: run the query script and open a picker with the results
      -- opts.preview_fn: optional function(entry) called on <C-z> to preview
      local function strudel_picker(mode, title, entry_maker_fn, opts)
        opts = opts or {}
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        vim.fn.jobstart({ "node", strudel_query_script, mode }, {
          stdout_buffered = true,
          on_stdout = function(_, data)
            if not data or not data[1] or data[1] == "" then return end
            local ok, items = pcall(vim.json.decode, data[1])
            if not ok or not items then
              vim.schedule(function()
                vim.notify("Failed to parse Strudel " .. mode, vim.log.levels.ERROR)
              end)
              return
            end

            vim.schedule(function()
              pickers.new({}, {
                prompt_title = title .. " (" .. #items .. ")",
                finder = finders.new_table({
                  results = items,
                  entry_maker = entry_maker_fn,
                }),
                sorter = conf.generic_sorter({}),
                attach_mappings = function(prompt_bufnr, map)
                  actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    if selection then
                      insert_at_cursor(selection.value.name)
                    end
                  end)
                  if opts.preview_fn then
                    map({ "i", "n" }, "<Tab>", function()
                      local selection = action_state.get_selected_entry()
                      if selection then
                        opts.preview_fn(selection)
                      end
                    end)
                  end
                  return true
                end,
              }):find()
            end)
          end,
          on_stderr = function(_, data)
            if data and data[1] and data[1] ~= "" then
              vim.schedule(function()
                vim.notify("Strudel: " .. table.concat(data, "\n"), vim.log.levels.WARN)
              end)
            end
          end,
        })
      end

      -- Sounds picker with drill-down into sample variants
      local function strudel_pick_sound()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local entry_display = require("telescope.pickers.entry_display")

        -- Forward-declare for mutual recursion between main and variant pickers
        local open_main_picker

        -- Sub-picker for individual sample variants (name:0, name:1, ...)
        local function open_variant_picker(sound, parent_prompt_text, cached_sounds)
          local count = sound.count or 0
          if count < 1 then count = 1 end
          local variants = {}
          for i = 0, count - 1 do
            table.insert(variants, { name = sound.name, n = i, label = sound.name .. ":" .. i })
          end

          local vdisplayer = entry_display.create({
            separator = " ",
            items = {
              { width = 30 },
              { remaining = true },
            },
          })

          pickers.new({}, {
            prompt_title = sound.name .. " variants (" .. count .. ") [< back, Tab preview]",
            finder = finders.new_table({
              results = variants,
              entry_maker = function(v)
                return {
                  value = v,
                  display = function()
                    return vdisplayer({
                      v.label,
                      { ":" .. v.n, "Number" },
                    })
                  end,
                  ordinal = v.label,
                }
              end,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
              actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local sel = action_state.get_selected_entry()
                if sel then
                  insert_at_cursor(sel.value.label)
                end
              end)
              -- Tab to preview variant
              map({ "i", "n" }, "<Tab>", function()
                local sel = action_state.get_selected_entry()
                if sel then
                  strudel_preview_sound(sel.value.name, sel.value.n)
                end
              end)
              -- < to go back to parent picker, restoring prompt text
              map({ "i", "n" }, "<", function()
                actions.close(prompt_bufnr)
                vim.schedule(function()
                  open_main_picker(cached_sounds, parent_prompt_text)
                end)
              end)
              return true
            end,
          }):find()
        end

        -- Main sounds picker (can be re-opened with restored prompt text)
        open_main_picker = function(sounds, initial_prompt)
          local displayer = entry_display.create({
            separator = " ",
            items = {
              { width = 30 },
              { width = 10 },
              { remaining = true },
            },
          })

          pickers.new({
            default_text = initial_prompt or "",
          }, {
            prompt_title = "Strudel Sounds (" .. #sounds .. ") [Tab preview, > expand]",
            finder = finders.new_table({
              results = sounds,
              entry_maker = function(sound)
                local count_str = (sound.count or 0) > 0 and ("(" .. sound.count .. ")") or ""
                return {
                  value = sound,
                  display = function()
                    return displayer({
                      sound.name,
                      { sound.type or "unknown", "Comment" },
                      { count_str, "Number" },
                    })
                  end,
                  ordinal = sound.name .. " " .. (sound.type or "") .. " " .. (sound.tag or ""),
                }
              end,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
              actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local sel = action_state.get_selected_entry()
                if sel then
                  insert_at_cursor(sel.value.name)
                end
              end)
              -- Tab to preview
              map({ "i", "n" }, "<Tab>", function()
                local sel = action_state.get_selected_entry()
                if sel then
                  strudel_preview_sound(sel.value.name)
                end
              end)
              -- > to drill into variants
              map({ "i", "n" }, ">", function()
                local sel = action_state.get_selected_entry()
                if sel and (sel.value.count or 0) > 1 then
                  -- Capture current prompt text before closing
                  local picker = action_state.get_current_picker(prompt_bufnr)
                  local prompt_text = picker:_get_prompt()
                  actions.close(prompt_bufnr)
                  vim.schedule(function()
                    open_variant_picker(sel.value, prompt_text, sounds)
                  end)
                end
              end)
              return true
            end,
          }):find()
        end

        -- Fetch sounds then open main picker
        vim.fn.jobstart({ "node", strudel_query_script, "sounds" }, {
          stdout_buffered = true,
          on_stdout = function(_, data)
            if not data or not data[1] or data[1] == "" then return end
            local ok, sounds = pcall(vim.json.decode, data[1])
            if not ok or not sounds then
              vim.schedule(function()
                vim.notify("Failed to parse Strudel sounds", vim.log.levels.ERROR)
              end)
              return
            end
            vim.schedule(function()
              open_main_picker(sounds)
            end)
          end,
          on_stderr = function(_, data)
            if data and data[1] and data[1] ~= "" then
              vim.schedule(function()
                vim.notify("Strudel: " .. table.concat(data, "\n"), vim.log.levels.WARN)
              end)
            end
          end,
        })
      end

      -- Functions picker
      local function strudel_pick_function()
        local entry_display = require("telescope.pickers.entry_display")
        local displayer = entry_display.create({
          separator = " ",
          items = {
            { width = 30 },
            { remaining = true },
          },
        })

        local kind_hl = {
          control = "String",
          method = "Function",
          ["function"] = "Keyword",
        }

        strudel_picker("functions", "Strudel Functions", function(fn)
          return {
            value = fn,
            display = function()
              return displayer({
                fn.name,
                { fn.kind, kind_hl[fn.kind] or "Comment" },
              })
            end,
            ordinal = fn.name .. " " .. fn.kind,
          }
        end)
      end

      vim.api.nvim_create_user_command("StrudelSounds", strudel_pick_sound, {})
      vim.api.nvim_create_user_command("StrudelFunctions", strudel_pick_function, {})

      -- Setup keybindings for Strudel files (*.str extension)
      local strudel_marker_augroup = vim.api.nvim_create_augroup('StrudelFileSetup', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
        group = strudel_marker_augroup,
        pattern = { '*.str', },
        desc = "Setup Strudel keybindings and JavaScript filetype for .str/.agent files",
        callback = function(args)
          local bufnr = args.buf
          -- Ensure buffer is valid and still exists
          if not vim.api.nvim_buf_is_valid(bufnr) then
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
          vim.keymap.set("n", "fi", strudel_pick_sound, { desc = "Pick Strudel sound/instrument", buffer = bufnr })
          vim.keymap.set("n", "fp", strudel_pick_function, { desc = "Pick Strudel function", buffer = bufnr })
          vim.keymap.set("i", "<C-s>", strudel_pick_sound, { desc = "Pick Strudel sound/instrument", buffer = bufnr })
          vim.keymap.set("i", "<C-f>", strudel_pick_function, { desc = "Pick Strudel function", buffer = bufnr })
        end,
      })
    '';
  };
}
