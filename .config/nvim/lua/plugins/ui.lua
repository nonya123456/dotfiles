-- Colorscheme and layout.
return {
  {
    'EdenEast/nightfox.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme('carbonfox')
    end,
  },

  {
    'shortcuts/no-neck-pain.nvim',
    version = '*',
    opts = { width = 120 },
    keys = {
      { '<leader>zz', '<cmd>NoNeckPain<cr>', desc = 'Toggle centered layout' },
    },
  },
}
