-- Basic, newcomer-friendly defaults
local o, wo, bo = vim.o, vim.wo, vim.bo

o.termguicolors = true
o.number = true
o.relativenumber = false
o.signcolumn = 'yes'
o.cursorline = true
o.scrolloff = 8
o.sidescrolloff = 8
o.wrap = false
o.breakindent = true
o.splitbelow = true
o.splitright = true
o.clipboard = 'unnamedplus'
o.updatetime = 200
o.timeoutlen = 300
o.completeopt = 'menuone,noselect'
o.mouse = 'a'
o.showmode = false

-- Search behavior (VSCode-like: case-insensitive unless you use caps)
o.ignorecase = true
o.smartcase = true
o.inccommand = 'split'   -- live preview of :substitute

-- Persistent undo across sessions
o.undofile = true
o.smartindent = true

-- Visible whitespace, like VSCode "render whitespace" (boundary)
o.list = true
o.listchars = 'tab:» ,trail:·,nbsp:␣'

-- Indentation defaults (overridden per-language by LSP/EditorConfig/ftplugin)
o.tabstop = 2
o.shiftwidth = 2
o.expandtab = true

-- Markdown: soft-wrap long prose
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'text' },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = false
    vim.opt_local.conceallevel = 2 -- needed by markview/obsidian
  end,
})

-- Reduce noise of EOB ~ markers
wo.fillchars = 'eob: '

-- Transparent background — inherit from Ghostty
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    local groups = {
      'Normal', 'NormalNC', 'NormalFloat', 'SignColumn', 'EndOfBuffer',
      'NeoTreeNormal', 'NeoTreeNormalNC', 'NeoTreeEndOfBuffer',
      'BufferLineFill', 'StatusLine', 'StatusLineNC',
    }
    for _, g in ipairs(groups) do
      vim.api.nvim_set_hl(0, g, { bg = 'NONE' })
    end
  end
})
