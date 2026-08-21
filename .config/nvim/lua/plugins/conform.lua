-- Autoformat
return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>f',
      function()
        require('conform').format({ async = true, lsp_format = 'fallback' })
      end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  },
  ---@module 'conform'
  ---@type conform.setupOpts
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- Disable "format_on_save lsp_fallback" for languages that don't
      -- have a well standardized coding style.
      local disable_filetypes = { c = false, cpp = false }
      if disable_filetypes[vim.bo[bufnr].filetype] then
        return nil
      else
        return {
          timeout_ms = 500,
          lsp_format = 'fallback',
        }
      end
    end,
    formatters = {
      gdscript_formatter = {
        command = 'gdscript-formatter',
        args = { '--reorder-code' },
        stdin = true,
      },
    },
    formatters_by_ft = {
      lua = { 'stylua' },
      ruby = { 'rubyfmt' },
      cmake = { 'cmake_format' },
      gdscript = { 'gdscript_formatter' },
      odin = { 'odinfmt', 'trim_newlines' },
      toml = { 'taplo' },
    },
  },
}
