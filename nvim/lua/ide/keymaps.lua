-- IDE-like keymaps (with fallbacks if terminals swallow Ctrl+Shift combos)
local map = vim.keymap.set
local silent = { silent = true, noremap = true }

-- SAFETY: Save/Quit
map({'n','v'},'<C-s>', '<cmd>w<CR>', silent)         -- Ctrl+S save
map('i','<C-s>', '<Esc><cmd>w<CR>a', silent)
map('n','<C-q>', ':bd<CR>', silent)                  -- Ctrl+Q close buffer (like close tab)
map('n','<leader>w', function()
  local ok, mini = pcall(require, 'mini.bufremove')
  if ok then mini.delete() else vim.cmd('bd') end
end, silent)                                          -- ␣ w close buffer (keep window)
map('n','<leader>qq', ':qa!<CR>', silent)            -- Force quit session

-- VSCode-style editing (Ctrl+Z / Ctrl+Y / Ctrl+A)
map('n','<C-z>', 'u', silent)
map('i','<C-z>', '<C-o>u', silent)
map('v','<C-z>', '<Esc>u', silent)
map('n','<C-y>', '<C-r>', silent)
map('i','<C-y>', '<C-o><C-r>', silent)
map('n','<C-a>', 'ggVG', silent)                     -- Select all (normal)
map('i','<C-a>', '<Esc>ggVG', silent)

-- Clear search highlight on Esc
map('n','<Esc>', '<cmd>noh<CR><Esc>', silent)

-- Move lines (VSCode: Alt+↑/↓) — both Alt+j/k and Alt+Arrow
local function alt_move(modes, lhs_a, lhs_b, dir_n, dir_v)
  map(modes, lhs_a, dir_n, silent)
  map(modes, lhs_b, dir_n, silent)
end
map('n','<A-j>',     '<cmd>m .+1<CR>==', silent)
map('n','<A-Down>',  '<cmd>m .+1<CR>==', silent)
map('n','<A-k>',     '<cmd>m .-2<CR>==', silent)
map('n','<A-Up>',    '<cmd>m .-2<CR>==', silent)
map('i','<A-j>',     '<Esc><cmd>m .+1<CR>==gi', silent)
map('i','<A-Down>',  '<Esc><cmd>m .+1<CR>==gi', silent)
map('i','<A-k>',     '<Esc><cmd>m .-2<CR>==gi', silent)
map('i','<A-Up>',    '<Esc><cmd>m .-2<CR>==gi', silent)
map('v','<A-j>',     ":m '>+1<CR>gv=gv", silent)
map('v','<A-Down>',  ":m '>+1<CR>gv=gv", silent)
map('v','<A-k>',     ":m '<-2<CR>gv=gv", silent)
map('v','<A-Up>',    ":m '<-2<CR>gv=gv", silent)

-- Duplicate line (VSCode: Shift+Alt+↑/↓)
map('n','<S-A-j>',    '<cmd>t.<CR>', silent)
map('n','<S-A-Down>', '<cmd>t.<CR>', silent)
map('n','<S-A-k>',    '<cmd>t.-1<CR>', silent)
map('n','<S-A-Up>',   '<cmd>t.-1<CR>', silent)
map('v','<S-A-j>',    ":t '><CR>gv", silent)
map('v','<S-A-Down>', ":t '><CR>gv", silent)

-- Delete line (Ctrl+Shift+K)
pcall(function() map('n','<C-S-k>', '"_dd', silent) end)

-- Stay in visual mode after indent (so >>, << can be repeated easily)
map('v','<', '<gv', silent)
map('v','>', '>gv', silent)

-- Window navigation (Ctrl+hjkl)
map('n','<C-h>', '<C-w>h', silent)
map('n','<C-j>', '<C-w>j', silent)
map('n','<C-k>', '<C-w>k', silent)
map('n','<C-l>', '<C-w>l', silent)

-- Resize windows (Ctrl+Arrow)
map('n','<C-Up>',    '<cmd>resize +2<CR>', silent)
map('n','<C-Down>',  '<cmd>resize -2<CR>', silent)
map('n','<C-Left>',  '<cmd>vertical resize -2<CR>', silent)
map('n','<C-Right>', '<cmd>vertical resize +2<CR>', silent)

-- Better paste in visual: don't overwrite the unnamed register
map('v','p', '"_dP', silent)

-- Bufferline cycle (also Shift+h/l — terminal-safe)
pcall(function()
  map('n','<S-h>', '<cmd>BufferLineCyclePrev<CR>', silent)
  map('n','<S-l>', '<cmd>BufferLineCycleNext<CR>', silent)
end)

-- FILE NAV: Explorer / Find / Command Palette
map('n','<C-b>', ':Neotree toggle left reveal=true<CR>', silent) -- Ctrl+B: sidebar
map('n','<C-p>', function() require('telescope.builtin').find_files() end, silent) -- Ctrl+P: files
map('n','<leader><leader>', function() require('telescope.builtin').commands() end, silent) -- ␣␣ command palette
-- If your terminal supports it, Ctrl+Shift+P also as palette:
pcall(function() map('n','<C-S-p>', function() require('telescope.builtin').commands() end, silent) end)

-- SEARCH: in project / in file
map('n','<leader>sf', function() require('telescope.builtin').live_grep() end, silent) -- ␣ s f: search project
pcall(function() map('n','<C-S-f>', function() require('telescope.builtin').live_grep() end, silent) end) -- try Ctrl+Shift+F
map('n','<C-f>', function() require('telescope.builtin').current_buffer_fuzzy_find() end, silent) -- Ctrl+F: in-file

-- BUFFERS / TABS (IDE-like)
map('n','<leader>bn', ':bnext<CR>', silent)
map('n','<leader>bp', ':bprevious<CR>', silent)
-- Try Ctrl+Tab / Ctrl+Shift+Tab (may not work on all terminals)
pcall(function()
  map('n','<C-Tab>', ':bnext<CR>', silent)
  map('n','<C-S-Tab>', ':bprevious<CR>', silent)
end)

-- TERMINAL
-- ToggleTerm default at <C-\> (Ctrl+\). Also provide ␣ t t
map('n','<leader>tt', ':ToggleTerm<CR>', silent)

-- LSP UX (rename, actions, format, outline, problems)
map('n','<F2>', vim.lsp.buf.rename, silent)                  -- F2 rename
map({'n','v'},'<leader>.', vim.lsp.buf.code_action, silent)  -- ␣ . code action
map('n','<leader>=', function() require('conform').format({lsp_fallback = true}) end, silent) -- format
pcall(function() map({'n','v'},'<S-A-f>', function() require('conform').format({async = true, lsp_fallback = true}) end, silent) end)
map('n','<leader>O', ':AerialToggle<CR>', silent)            -- outline panel (like Cmd+Shift+O)
pcall(function() map('n','<C-S-o>', ':AerialToggle<CR>', silent) end)
map('n','<leader>x', ':Trouble diagnostics toggle<CR>', silent)  -- Problems panel
pcall(function() map('n','<C-S-m>', ':Trouble diagnostics toggle<CR>', silent) end)

-- GIT
map('n','<leader>gg', ':LazyGit<CR>', silent)     -- LazyGit if installed
map('n',']g', function() require('gitsigns').next_hunk() end, silent)
map('n','[g', function() require('gitsigns').prev_hunk() end, silent)
map('n','<leader>gp', function() require('gitsigns').preview_hunk() end, silent)

-- COMMENTS (Ctrl+/ if terminal allows; always has gcc fallback)
pcall(function()
  map({'n','v'}, '<C-/>', function() require('Comment.api').toggle.linewise.current() end, silent)
end)

-- DAP (Debugging)
map('n','<F5>', function() require('dap').continue() end, silent)
map('n','<F10>', function() require('dap').step_over() end, silent)
map('n','<F11>', function() require('dap').step_into() end, silent)
map('n','<S-F11>', function() require('dap').step_out() end, silent)
map('n','<F9>', function() require('dap').toggle_breakpoint() end, silent)
map('n','<leader>du', function() require('dapui').toggle() end, silent)
