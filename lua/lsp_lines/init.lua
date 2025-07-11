local M = {}

local render = require("lsp_lines.render")

-- Keep latest diagnostics per buffer
local latest_diagnostics = {}
local virt_lines_ns_by_buf = {}

local function render_current_line(bufnr, ns, opts)
  local current_line_diag = {}
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diagnostics = latest_diagnostics[bufnr] or {}

  for _, diagnostic in ipairs(diagnostics) do
    local show = diagnostic.end_lnum and (lnum >= diagnostic.lnum and lnum <= diagnostic.end_lnum)
      or (lnum == diagnostic.lnum)
    if show then
      table.insert(current_line_diag, diagnostic)
    end
  end

  render.show(ns, bufnr, current_line_diag, opts)
end

M.setup = function()
  vim.api.nvim_create_augroup("LspLines", { clear = true })
  vim.diagnostic.handlers.virtual_lines = {
    show = function(namespace, bufnr, diagnostics, opts)
      -- Always use the same namespace for each buffer
      if not virt_lines_ns_by_buf[bufnr] then
        virt_lines_ns_by_buf[bufnr] = vim.api.nvim_create_namespace("lsp_lines_" .. tostring(bufnr))
      end
      local virt_ns = virt_lines_ns_by_buf[bufnr]
      latest_diagnostics[bufnr] = diagnostics

      if opts.virtual_lines and opts.virtual_lines.only_current_line then
        local autocmds = vim.api.nvim_get_autocmds({ group = "LspLines", buffer = bufnr })
        if #autocmds == 0 then
          vim.api.nvim_create_autocmd("CursorMoved", {
            buffer = bufnr,
            callback = function()
              render_current_line(bufnr, virt_ns, opts)
            end,
            group = "LspLines",
          })
        end
        render_current_line(bufnr, virt_ns, opts)
      else
        render.show(virt_ns, bufnr, diagnostics, opts)
      end
    end,
    hide = function(namespace, bufnr)
      local virt_ns = virt_lines_ns_by_buf[bufnr]
      if virt_ns then
        render.hide(virt_ns, bufnr)
        vim.api.nvim_clear_autocmds({ group = "LspLines" })
      end
      latest_diagnostics[bufnr] = nil
    end,
  }
end

M.toggle = function()
  local new_value = not vim.diagnostic.config().virtual_lines
  vim.diagnostic.config({ virtual_lines = new_value })
  return new_value
end

return M
