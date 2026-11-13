-- The builtin indent defers to autoindent, which copies the indent of the line `o`/`O` was pressed
-- on, so opening a line from a blank line inside a block lands at column 0. When autoindent copied
-- nothing, take the shallower indent of the surrounding code instead.
local base = vim.bo.indentexpr

function _G.gdscript_indent()
  local ind = vim.fn.eval(base)
  local lnum = vim.v.lnum
  if ind ~= -1 or vim.fn.getline(lnum) ~= '' then
    return ind
  end
  local prev, next = vim.fn.prevnonblank(lnum - 1), vim.fn.nextnonblank(lnum + 1)
  if prev == 0 or next == 0 then
    return 0
  end
  return math.min(vim.fn.indent(prev), vim.fn.indent(next))
end

vim.bo.indentexpr = 'v:lua.gdscript_indent()'
