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
    };
  easypick-nvim =
    {
      plugin = pkgs.fetchFromGitHub {
        owner = "axkirillov";
        repo = "easypick.nvim";
        rev = "a8772f39519574df1ed49110b4fe02456a240530"; # Replace with a specific commit for stability
        sha256 = "sha256:19bhvy97xp4qjq0kcfxjivnjrs0vbbqkhdps3jd68xmhzks32337"; # Get this using nix-prefetch-git
      };
      type = "nvim-lua";
    };
  strudel-nvim =
    {
      plugin = pkgs.buildNpmPackage {
        pname = "strudel.nvim";
        version = "unstable-2025-09-17";

        src = pkgs.fetchFromGitHub {
          owner = "gruvw";
          repo = "strudel.nvim";
          rev = "5a8e6db66502f55a988025e7f081c84843021c76";
          sha256 = "sha256-2n6SL/AUqHEAMNFsxE3UmfSyXUBsE4fnWfg2qsBfjNQ=";
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
  avante-nvim = pkgs.callPackage ./avante.nix {};
in
{
  home.packages = [
    pkgs.nil
    pkgs.typescript-language-server
    pkgs.nodejs # Required for strudel.nvim to work

    pkgs.ripgrep
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
      easypick-nvim
      emmet-vim
      gitlinker-nvim
      toggleterm-nvim
      tidal-nvim
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
      vim.g.gitblame_enabled = 0

      vim.cmd('colorscheme gruvbox-material')

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
          lualine_b = {'filename'},
          lualine_c = {},
          lualine_x = {'branch', 'encoding', 'fileformat', 'filetype'},
          lualine_y = {},
          lualine_z = {}
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {'filename'},
          lualine_x = {'location'},
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
          bindings = {
            ["<C-j>"] = false, -- disable default <C-j>
            ["<C-k>"] = false, -- disable default <C-k>
            ["<C-h>"] = false, -- disable default <C-h>
            ["<C-l>"] = false, -- disable default <C-l>
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
      require('telescope').load_extension('fzf')
	    local telescope = require('telescope.builtin')
	    vim.keymap.set('n', 'ff', telescope.find_files, {})
	    vim.keymap.set('n', 'fg', telescope.live_grep, {})
      vim.keymap.set('n', 'fe', function() telescope.diagnostics({ initial_mode = 'normal'}) end, {})
	    vim.keymap.set('n', 'fd', telescope.commands, {})
      vim.keymap.set('n', 'fh', function() telescope.command_history({ initial_mode = 'insert' }) end, {})
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
      vim.keymap.set('n', '<leader>gd', ":DiffviewOpen<CR>", bufopts)
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
      require('mason').setup({
        PATH = "append",
      })
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


      -- --------
      -- Easypick
      -- --------

      -- Stupid hack to get the right search path to find the module
      local plugin_path = "${easypick-nvim.plugin}"
      vim.opt.rtp:append(plugin_path)
      package.path = package.path .. ";$" .. plugin_path .. "/lua/?.lua;$" .. plugin_path .. "/lua/?/init.lua"

      easypick = require('easypick')
      local actions = require "telescope.actions"
      local action_state = require "telescope.actions.state"

      local function write_selected_value(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection and selection[1] then
            local sample_name = selection[1]
            -- Keep only everyting before the first space
            local space_index = string.find(sample_name, " ")
            if space_index then
              sample_name = string.sub(sample_name, 1, space_index - 1)
            end

            local current_bufnr = vim.api.nvim_get_current_buf()
            local cursor_pos = vim.api.nvim_win_get_cursor(0) -- [row, col] (1-based row, 0-based col)
            local row = cursor_pos[1]
            local col = cursor_pos[2]

            local current_line = vim.api.nvim_buf_get_lines(current_bufnr, row - 1, row, false)[1]
            local new_line = current_line:sub(1, col+1) .. sample_name .. current_line:sub(col)

            vim.api.nvim_buf_set_lines(current_bufnr, row - 1, row, false, {new_line})
          end
        end)
        return true
      end

      local function play_selected_value(note)
        if note == nil then
          note = 0
        end
        local selection = action_state.get_selected_entry()
        if selection and selection[1] then
          local sample_name = selection[1]
          local space_index = string.find(sample_name, " ")
          if space_index then
            sample_name = string.sub(sample_name, 1, space_index - 1)
          end
          vim.cmd('TidalSend1 once $ note "' .. note .. '" # sound "' .. sample_name ..'"')
        end
      end

      easypick.setup({
        pickers = {
          -- add your custom pickers here
          -- below you can find some examples of what those can look like

          -- list files inside current folder with default previewer
          {
            -- name for your custom picker, that can be invoked using :Easypick <name> (supports tab completion)
            name = "tidal_samples",
            -- the command to execute, output has to be a list of plain text entries
            --command = "cd /home/hugo/repos/tidal-scratchpad && find samples-extra -maxdepth 1 -type d -print",
            command = "cat ~/.config/SuperCollider/dirt_samples.txt | sort",
            -- specify your custom previwer, or use one of the easypick.previewers
            previewer = easypick.previewers.default(),
            action = write_selected_value,
          },
          {
            -- name for your custom picker, that can be invoked using :Easypick <name> (supports tab completion)
            name = "tidal_instruments",
            -- the command to execute, output has to be a list of plain text entries
            --command = "cd /home/hugo/repos/tidal-scratchpad && find samples-extra -maxdepth 1 -type d -print",
            command = "cat ~/.config/SuperCollider/dirt_samples.txt | sed 's/:.*//' | sort --unique ",
            -- specify your custom previwer, or use one of the easypick.previewers
            previewer = easypick.previewers.default(),
            action = write_selected_value,
          },
        }
      })

      -- ------------
      -- Tidal Cycles
      -- ------------

      -- Setup a way to flash a highlight
      namespace_id = vim.api.nvim_create_namespace('HighlightLineNamespace')
      vim.api.nvim_command('highlight default HighlightLineActive guibg=#4c566a gui=bold ctermfg=198 cterm=bold ctermbg=darkgreen')
      vim.api.nvim_command('highlight default HighlightLineHush guifg=#ff0018 gui=bold ctermfg=198 cterm=bold ctermbg=darkgreen')
      function flash_highlight(start_line, start_col, end_line, end_col, bufnr, hl_group)
        -- Use the current buffer if no buffer number is provided.
        bufnr = bufnr or vim.api.nvim_get_current_buf()

        -- Check if the buffer number is valid.
        if not vim.api.nvim_buf_is_valid(bufnr) then
          vim.notify("Invalid buffer number", vim.log.levels.ERROR)
          return
        end

        -- Validate input parameters.
        if not (start_line and start_col and end_line and end_col and hl_group) then
          vim.notify("Missing arguments to flash_highlight", vim.log.levels.ERROR)
          return
        end

        if start_line < 1 or start_col < 1 or end_line < 1 or end_col < 1 then
          vim.notify("Line and column numbers must be >= 1", vim.log.levels.ERROR)
          return
        end

        -- Use nvim_buf_set_extmark to add the highlight.
        local extmark_id = vim.api.nvim_buf_set_extmark(
          bufnr,
          namespace_id,
          start_line - 1, -- nvim_buf_set_extmark uses 0-based indexing.
          start_col - 1, -- nvim_buf_set_extmark uses 0-based indexing.
          {
            end_line = end_line - 1, -- nvim_buf_set_extmark uses 0-based indexing.
            end_col = end_col,     -- nvim_buf_set_extmark uses 0-based indexing for end_col too.
            hl_group = hl_group,
            --buffer = bufnr, -- Not needed, the bufnr argument to the function is sufficient.
          }
        )
        -- Function to clear the highlight after the specified duration
        local function clear_highlight()
          vim.api.nvim_buf_del_extmark(bufnr, namespace_id, extmark_id)
        end

        -- Use a timer to call the clear_highlight function after the duration
        vim.defer_fn(clear_highlight, 250)
        return extmark_id
      end

      local ts_utils = require('nvim-treesitter.ts_utils')
      local vim_treesitter = require('vim.treesitter')
      --- Checks if a node represents a function call with the pattern 'd<n>`
      ---@param node TSNode The node to check
      ---@return boolean, TSNode? True if it's a matching function call, and the node itself
      local function is_d_function_call(node)
        if not node then
          return false, nil, nil
        end

        if node:type() == 'apply' then
          local func_node = node:child(0) -- The 'function' child in an 'apply' node
          if func_node and func_node:type() == 'variable' then
            local func_name = vim_treesitter.get_node_text(func_node, vim.api.nvim_get_current_buf())
            if func_name:match('^d%d+$') then
              return true, node, func_name
            end
          end
        elseif node:type() == "infix" then
          local func_node = node:child(0) -- The 'function' child in an 'apply' node
          if func_node and func_node:type() == 'variable' then
            local func_name = vim_treesitter.get_node_text(func_node, vim.api.nvim_get_current_buf())
            if func_name:match('^d%d+$') then
              return true, node, func_name
            end
          end
        end
        return false, nil, nil
      end

      --- Goes up from the cursor to find a function call named 'd<n>`
      ---@return TSNode? The node representing the function call, or nil if not found
      local function find_d_function_call_at_cursor()
        local winid = 0 -- Current window
        local pos = vim.api.nvim_win_get_cursor(winid)
        local row, col = pos[1] - 1, pos[2]

        local current_node = ts_utils.get_node_at_cursor()
        -- print(current_node)
        -- print(current_node:parent())
        -- print(current_node:parent():type())
        -- print(current_node:parent():child(0):type())
        -- print(vim_treesitter.get_node_text(current_node:parent():child(0), vim.api.nvim_get_current_buf()))
        -- print(is_d_function_call(current_node:parent()))
        if not current_node then
          return nil, nil
        end

        -- Check the current node first
        local found, node, track = is_d_function_call(current_node)
        if found then
          return node, track
        end

        -- Traverse upwards
        local parent = current_node:parent()
        while parent do
          local found_parent, parent_node, track = is_d_function_call(parent)
          if found_parent then
            return parent_node, track
          end
          parent = parent:parent()
        end

        return nil, nil
      end

      local function select_node_text_api(node)
        if not node then
          return
        end

        local bufnr = vim.api.nvim_get_current_buf()
        local start_row, start_col, end_row, end_col = vim_treesitter.get_node_range(node)

        vim.api.nvim_buf_set_mark(bufnr, '<', start_row + 1, start_col, {})
        vim.api.nvim_buf_set_mark(bufnr, '>', end_row + 1, end_col, {})

        vim.cmd("normal! gv") -- Go to the first mark and select until the last mark
      end

      local function select_around_current_tidal_track()
        local found_node, _ = find_d_function_call_at_cursor()
        if found_node then
          select_node_text_api(found_node)
        else
         vim.notify('Warning: No tidal track function found above the cursor.', vim.log.levels.WARN)
        end
      end

      local function play_current_tidal_track()
        local found_node, _ = find_d_function_call_at_cursor()
        if found_node then
          local bufnr = vim.api.nvim_get_current_buf()
          local node_text = vim_treesitter.get_node_text(found_node, bufnr)

          local start_row, start_col, end_row, end_col = vim_treesitter.get_node_range(found_node)
          flash_highlight(start_row+1, start_col+1, end_row+1, end_col, bufnr, "HighlightLineActive")

          local lines = vim.split(node_text, "\n", { plain = true })
          vim.cmd("TidalSend1 :{")
          for _, line in ipairs(lines) do
            vim.cmd("TidalSend1 " .. line)
          end
          vim.cmd("TidalSend1 :}")
        else
         vim.notify('Warning: No tidal track function found above the cursor.', vim.log.levels.WARN)
        end
      end

      local function hush_current_tidal_track()
        local found_node, track = find_d_function_call_at_cursor()
        if found_node then
          local bufnr = vim.api.nvim_get_current_buf()
          local start_row, start_col, end_row, end_col = vim_treesitter.get_node_range(found_node)
          flash_highlight(start_row+1, start_col, end_row+1, end_col, bufnr, "HighlightLineHush")
          vim.cmd("TidalSend1 " .. track .. ' $ sound ""')
        else
         vim.notify('Warning: No tidal track function found above the cursor.', vim.log.levels.WARN)
        end
      end

      vim.api.nvim_create_user_command('TidalSelectTrack', select_around_current_tidal_track, {})
      vim.api.nvim_create_user_command('TidalSendNode', play_current_tidal_track, {})
      vim.api.nvim_create_user_command('TidalHushNode', hush_current_tidal_track, {})

      -- If a haskell file starts with the magic string on the first line, enable tidal mode
      local tidal_magic_string = "-- nvim: enable tidalmode"
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
              vim.keymap.set('n', '<S-l>', ':TidalSendNode<CR>', opts)
              vim.keymap.set('n', '<S-h>', ':TidalHushNode<CR>', opts)
              vim.keymap.set('n', 'vt', ':TidalSelectTrack<CR>', opts)
              vim.keymap.set('v', '<S-l>', ':TidalSend<CR>', opts)
              vim.keymap.set('n', '<S-y>', ':TidalHush<CR>', opts)
              vim.keymap.set('n', 'fi', '<ESC>:Easypick tidal_instruments<CR>', opts)
              vim.keymap.set('n', 'fs', '<ESC>:Easypick tidal_samples<CR>', opts)
              vim.keymap.set('n', '<F2>', play_selected_value, opts)
              vim.keymap.set('i', '<F2>', play_selected_value, opts)
              -- Higher note is useful for some midi synths
              vim.keymap.set('n', '<F3>', (function()play_selected_value(42)end), opts)
              vim.keymap.set('i', '<F3>', (function()play_selected_value(42)end), opts)
            end
          end
        end,
      })


    '';
  };
}
