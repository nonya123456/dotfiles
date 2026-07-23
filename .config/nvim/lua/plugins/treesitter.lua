-- Highlight, edit, and navigate code
return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  branch = 'main',
  config = function()
    -- ensure basic parsers are installed
    local parsers = {
      'bash',
      'c',
      'diff',
      'gdscript',
      'html',
      'lua',
      'luadoc',
      'markdown',
      'markdown_inline',
      'query',
      'vim',
      'vimdoc',
    }
    require('nvim-treesitter').install(parsers)

    ---@param buf integer
    ---@param language string
    local function treesitter_try_attach(buf, language)
      if not vim.treesitter.language.add(language) then
        return
      end
      -- enables syntax highlighting and other treesitter features
      vim.treesitter.start(buf, language)
      -- enables treesitter based indentation
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end

    local available_parsers = require('nvim-treesitter').get_available()
    vim.api.nvim_create_autocmd('FileType', {
      callback = function(args)
        local buf, filetype = args.buf, args.match

        local language = vim.treesitter.language.get_lang(filetype)
        if not language then
          return
        end

        local installed_parsers = require('nvim-treesitter').get_installed('parsers')

        if vim.tbl_contains(installed_parsers, language) then
          treesitter_try_attach(buf, language)
        elseif vim.tbl_contains(available_parsers, language) then
          -- auto install the parser, then enable it once installed
          require('nvim-treesitter').install(language):await(function()
            treesitter_try_attach(buf, language)
          end)
        else
          treesitter_try_attach(buf, language)
        end
      end,
    })
  end,
}
