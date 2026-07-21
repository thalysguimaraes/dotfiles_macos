-- Neovim IDE-like setup (beginner-friendly)
-- Entry point: minimal logic here, everything lives under lua/ide
vim.g.mapleader = ' '         -- Space as <leader>
vim.g.maplocalleader = ' '

-- Bootstrap Lazy.nvim (plugin manager)
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git','clone','--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git','--branch=stable', lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load our config (ordered)
require('ide.options')   -- Neovim options
require('ide.plugins')   -- Plugins via Lazy
require('ide.keymaps')   -- Keybindings (IDE-like)
require('ide.autocmds')  -- Autocommands
