-- Format on save (fast formatters recommended)
vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function()
    local ok, conform = pcall(require, 'conform')
    if ok then conform.format({ async = false, lsp_fallback = true }) end
  end
})

-- Lint on write & on buffer enter
vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufEnter' }, {
  callback = function()
    local ok, lint = pcall(require, 'lint')
    if ok then lint.try_lint() end
  end
})
