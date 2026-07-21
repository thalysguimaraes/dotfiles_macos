-- All plugins + setup via Lazy.nvim
require('lazy').setup({
  -- Core libs/UI
  { 'nvim-lua/plenary.nvim', lazy = true },
  { 'nvim-tree/nvim-web-devicons', lazy = true },
  { 'stevearc/dressing.nvim', event = 'VeryLazy' }, -- nicer input/select
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      spec = {
        { '<leader>b', group = 'Buffer' },
        { '<leader>f', group = 'Find' },
        { '<leader>g', group = 'Git' },
        { '<leader>o', group = 'Obsidian / Notes' },
        { '<leader>s', group = 'Search' },
        { '<leader>t', group = 'Terminal / Toggle' },
        { '<leader>d', group = 'Debug' },
      },
    },
  },

  -- Theme & statusline/buffers (using terminal colors)
  -- Tokyonight disabled - inheriting from Ghostty
  -- {
  --   'folke/tokyonight.nvim',
  --   priority = 1000,
  --   config = function()
  --     require('tokyonight').setup({ style = 'storm', transparent = false })
  --     vim.cmd.colorscheme('tokyonight')
  --   end
  -- },
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    config = function()
      require('lualine').setup({ options = { theme = 'auto', globalstatus = true } })
    end
  },
  {
    'akinsho/bufferline.nvim',
    event = 'VeryLazy',
    opts = { options = { diagnostics = 'nvim_lsp', show_close_icon = false } }
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = 'BufReadPre',
    opts = {}
  },

  -- File explorer & outline & problems panel
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-tree/nvim-web-devicons', 'MunifTanjim/nui.nvim' },
    cmd = { 'Neotree' },
    keys = { { '<C-b>', '<cmd>Neotree toggle left reveal=true<CR>', desc = 'Toggle Explorer' } },
    opts = {
      filesystem = { follow_current_file = { enabled = true }, filtered_items = { hide_dotfiles = false } }
    }
  },
  { 'stevearc/aerial.nvim', cmd = { 'AerialToggle', 'AerialOpen' }, opts = {} },
  {
    'folke/trouble.nvim',
    cmd = { 'Trouble' },
    opts = { auto_close = false, use_diagnostic_signs = true }
  },

  -- Telescope (files, search, palette)
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = 'Telescope',
    keys = {
      { '<C-p>', function() require('telescope.builtin').find_files() end, desc = 'Find Files' },
      { '<leader><leader>', function() require('telescope.builtin').commands() end, desc = 'Command Palette' },
      { '<leader>sf', function() require('telescope.builtin').live_grep() end, desc = 'Search in Workspace' },
    },
    opts = function()
      local actions = require('telescope.actions')
      return {
        defaults = {
          mappings = { i = { ['<C-j>'] = actions.move_selection_next, ['<C-k>'] = actions.move_selection_previous } },
        }
      }
    end
  },
  { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make', cond = function() return vim.fn.executable('make') == 1 end,
    config = function() pcall(function() require('telescope').load_extension('fzf') end) end
  },

  -- Treesitter (syntax/semantics)
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',         -- pin to legacy branch (main branch dropped `configs` module)
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      ensure_installed = { 'bash','lua','vim','vimdoc','json','yaml','toml','regex','markdown','markdown_inline','html','css','javascript','typescript','tsx','python','go','rust','c','cpp' },
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts) require('nvim-treesitter.configs').setup(opts) end
  },

  -- Comments / pairs / surround
  { 'numToStr/Comment.nvim', event = 'VeryLazy', opts = {} },
  { 'windwp/nvim-autopairs', event = 'InsertEnter', opts = {} },
  { 'kylechui/nvim-surround', event = 'VeryLazy', opts = {} },

  -- Terminal
  { 'akinsho/toggleterm.nvim', version = '*', opts = { open_mapping = [[<C-\>]], shade_terminals = true } },

  -- Git
  { 'lewis6991/gitsigns.nvim', event = 'BufReadPre', opts = {} },
  { 'kdheepak/lazygit.nvim', cmd = { 'LazyGit' } },

  -- Notifications / UX polish (disabled for stability)
  -- { 'rcarriga/nvim-notify', lazy = true },
  -- {
  --   'folke/noice.nvim',
  --   event = 'VeryLazy',
  --   dependencies = { 'rcarriga/nvim-notify', 'MunifTanjim/nui.nvim' },
  --   opts = { presets = { bottom_search = true, command_palette = true } }
  -- },

  -- Minimap (disabled for stability)
  -- { 'echasnovski/mini.map', version = false, config = function() require('mini.map').setup() end },

  -- LSP + completion + format + lint
  { 'neovim/nvim-lspconfig' },
  { 'williamboman/mason.nvim', build = ':MasonUpdate', config = function() require('mason').setup({}) end },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim', 'neovim/nvim-lspconfig', 'hrsh7th/cmp-nvim-lsp' },
    config = function()
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      local servers = {
        lua_ls = {
          settings = { Lua = { diagnostics = { globals = { 'vim' } }, workspace = { checkThirdParty = false } } }
        },
        ts_ls = {
          settings = { typescript = { format = { enable = false } }, javascript = { format = { enable = false } } }
        },
      }

      require('mason-lspconfig').setup({
        ensure_installed = {
          'lua_ls','ts_ls','html','cssls','jsonls','yamlls',
          'pyright','bashls'
        },
        handlers = {
          -- Default handler for all servers
          function(server_name)
            lspconfig[server_name].setup({
              capabilities = capabilities,
              settings = servers[server_name] and servers[server_name].settings or nil
            })
          end,
        }
      })
    end
  },
  { 'folke/neodev.nvim', opts = {} },

  -- Completion stack
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'saadparwaiz1/cmp_luasnip',
      'L3MON4D3/LuaSnip',
      'onsails/lspkind.nvim',
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      require('luasnip.loaders.from_vscode').lazy_load()
      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { 'i','s' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { 'i','s' }),
        }),
        sources = {
          { name = 'nvim_lsp' }, { name = 'path' }, { name = 'buffer' }, { name = 'luasnip' },
        },
        formatting = {
          format = function(entry, vim_item)
            local lspkind = require('lspkind')
            vim_item.kind = lspkind.symbolic(vim_item.kind) or vim_item.kind
            return vim_item
          end
        }
      })
    end
  },
  { 'hrsh7th/cmp-nvim-lsp', lazy = true },
  { 'hrsh7th/cmp-buffer', lazy = true },
  { 'hrsh7th/cmp-path', lazy = true },
  { 'saadparwaiz1/cmp_luasnip', lazy = true },
  { 'L3MON4D3/LuaSnip', lazy = true, dependencies = { 'rafamadriz/friendly-snippets' } },
  { 'rafamadriz/friendly-snippets', lazy = true },
  { 'onsails/lspkind.nvim', lazy = true },

  -- Formatting / Linting
  {
    'stevearc/conform.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('conform').setup({
        notify_on_error = true,
        formatters_by_ft = {
          lua = { 'stylua' },
          javascript = { 'prettierd', 'prettier' },
          typescript = { 'prettierd', 'prettier' },
          javascriptreact = { 'prettierd', 'prettier' },
          typescriptreact = { 'prettierd', 'prettier' },
          json = { 'prettierd', 'prettier' },
          yaml = { 'prettierd', 'prettier' },
          html = { 'prettierd', 'prettier' },
          css = { 'prettierd', 'prettier' },
          scss = { 'prettierd', 'prettier' },
          markdown = { 'prettierd', 'prettier' },
          python = { 'ruff_format', 'black' },
          go = { 'goimports', 'gofmt' },
          rust = { 'rustfmt' },
          sh = { 'shfmt' },
          c = { 'clang_format' },
          cpp = { 'clang_format' },
        },
      })
    end
  },
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require('lint')
      lint.linters_by_ft = {
        python = { 'ruff' },
        javascript = { 'eslint_d', 'eslint' },
        typescript = { 'eslint_d', 'eslint' },
        javascriptreact = { 'eslint_d', 'eslint' },
        typescriptreact = { 'eslint_d', 'eslint' },
        dockerfile = { 'hadolint' },
        go = { 'golangcilint' },
      }
    end
  },

  -- Debugging
  { 'mfussenegger/nvim-dap' },
  {
    'rcarriga/nvim-dap-ui',
    dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' },
    config = function()
      local dap, dapui = require('dap'), require('dapui')
      dapui.setup()
      dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
      dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
      dap.listeners.before.event_exited['dapui_config'] = function() dapui.close() end
    end
  },
  { 'nvim-neotest/nvim-nio', lazy = true },
  { 'theHamsta/nvim-dap-virtual-text', dependencies = { 'mfussenegger/nvim-dap' }, opts = {} },
  {
    'jay-babu/mason-nvim-dap.nvim',
    dependencies = { 'williamboman/mason.nvim', 'mfussenegger/nvim-dap' },
    config = function()
      require('mason-nvim-dap').setup({
        ensure_installed = { 'node2','python','delve' },
        automatic_setup = true,
      })
    end
  },

  -- Quick buffer delete (keeps window layout) — used by <leader>w
  { 'echasnovski/mini.bufremove', lazy = true, opts = {} },

  -- ── Markdown rendering inside Neovim (markview.nvim) ───────────────────
  {
    'OXY2DEV/markview.nvim',
    lazy = false, -- recommended by the plugin
    ft = { 'markdown', 'codecompanion', 'Avante', 'quarto', 'rmd' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    opts = {
      preview = {
        modes = { 'n', 'no', 'c' },          -- decorate in normal, don't fight insert
        hybrid_modes = { 'n' },              -- keep raw markdown around the cursor line
        filetypes = { 'markdown', 'quarto', 'rmd', 'codecompanion', 'Avante' },
        ignore_buftypes = {},
      },
      markdown = {
        headings = { shift_width = 0 },      -- don't indent headings
      },
    },
  },

  -- ── Obsidian.nvim — vault at ~/source-of-truth ─────────────────────────
  {
    'epwalsh/obsidian.nvim',
    version = '*',
    ft = 'markdown',
    cmd = {
      'ObsidianOpen', 'ObsidianNew', 'ObsidianQuickSwitch',
      'ObsidianSearch', 'ObsidianToday', 'ObsidianYesterday',
      'ObsidianTomorrow', 'ObsidianBacklinks', 'ObsidianTags',
      'ObsidianTemplate', 'ObsidianWorkspace', 'ObsidianRename',
      'ObsidianFollowLink', 'ObsidianPasteImg',
    },
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      { '<leader>oo', '<cmd>ObsidianQuickSwitch<CR>',  desc = 'Obsidian: quick switch' },
      { '<leader>os', '<cmd>ObsidianSearch<CR>',        desc = 'Obsidian: search vault' },
      { '<leader>od', '<cmd>ObsidianToday<CR>',         desc = 'Obsidian: today' },
      { '<leader>oy', '<cmd>ObsidianYesterday<CR>',     desc = 'Obsidian: yesterday' },
      { '<leader>on', '<cmd>ObsidianNew<CR>',           desc = 'Obsidian: new note' },
      { '<leader>ob', '<cmd>ObsidianBacklinks<CR>',     desc = 'Obsidian: backlinks' },
      { '<leader>ot', '<cmd>ObsidianTags<CR>',          desc = 'Obsidian: tags' },
      { '<leader>op', '<cmd>ObsidianPasteImg<CR>',      desc = 'Obsidian: paste image' },
      { '<leader>or', '<cmd>ObsidianRename<CR>',        desc = 'Obsidian: rename note' },
      { '<leader>ol', '<cmd>ObsidianLink<CR>', mode = 'v', desc = 'Obsidian: link selection' },
    },
    opts = {
      workspaces = {
        { name = 'source-of-truth', path = '~/source-of-truth' },
      },
      notes_subdir = 'Notes',
      new_notes_location = 'notes_subdir',
      daily_notes = {
        folder = 'Notes/Daily Notes',
        date_format = '%Y-%m-%d',
        default_tags = { 'daily' },
      },
      completion = { nvim_cmp = true, min_chars = 2 },
      mappings = {
        -- gf-like jump to link under cursor in markdown
        ['gf'] = {
          action = function() return require('obsidian').util.gf_passthrough() end,
          opts = { noremap = false, expr = true, buffer = true },
        },
        -- Toggle checkbox state
        ['<leader>ch'] = {
          action = function() return require('obsidian').util.toggle_checkbox() end,
          opts = { buffer = true },
        },
        -- Smart action: follow link / toggle checkbox / open URL
        ['<CR>'] = {
          action = function() return require('obsidian').util.smart_action() end,
          opts = { buffer = true, expr = true },
        },
      },
      picker = { name = 'telescope.nvim' },
      ui = { enable = false }, -- let markview.nvim handle rendering
      attachments = { img_folder = '_media' },
      templates = {
        folder = 'Templates',
        date_format = '%Y-%m-%d',
        time_format = '%H:%M',
      },
      -- Don't auto-add frontmatter to existing notes
      disable_frontmatter = true,
    },
  },

  -- Project root detection
  { 'ahmedkhalf/project.nvim',
    opts = {
      detection_methods = { 'pattern', 'lsp' },
      patterns = { '.git', 'package.json', 'pyproject.toml', 'go.mod', 'Cargo.toml', 'Makefile' },
    },
    config = function(_, opts)
      require('project_nvim').setup(opts)
      require('telescope').load_extension('projects')
    end
  },
}, {
  ui = { border = 'rounded' }
})

-- LSP keybindings (set when LSP attaches to a buffer)
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local bufnr = args.buf
    local bufmap = function(m, lhs, rhs) vim.keymap.set(m, lhs, rhs, { buffer = bufnr, silent = true }) end
    bufmap('n', 'gd', vim.lsp.buf.definition)
    bufmap('n', 'gr', vim.lsp.buf.references)
    bufmap('n', 'gD', vim.lsp.buf.declaration)
    bufmap('n', 'gi', vim.lsp.buf.implementation)
    bufmap('n', 'K',  vim.lsp.buf.hover)
    bufmap('n', '<leader>sd', vim.diagnostic.open_float)
    bufmap('n', '[d', vim.diagnostic.goto_prev)
    bufmap('n', ']d', vim.diagnostic.goto_next)
  end
})
