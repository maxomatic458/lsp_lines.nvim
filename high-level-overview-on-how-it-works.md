# High-Level Overview of lsp_lines.nvim
This plugin replaces standard inline virtual text diagnostics with multiline virtual text that appears below code, making it easier to read error messages.

How It Works
	1.	Neovim’s LSP sends diagnostics.
	2.	The plugin intercepts diagnostics via vim.diagnostic.handlers.virtual_lines.show.
	3.	It formats the diagnostics as virtual text (displayed beneath the code).
	4.	The virtual lines are drawn using vim.api.nvim_buf_set_extmark.


# Deep Dive into How It Works

## init.lua: The Entry Point

This module registers the custom diagnostic handler and controls how the plugin behaves.

Key Parts
- Registers the custom show function for LSP diagnostics:

```lua
vim.diagnostic.handlers.virtual_lines = {
  show = function(namespace, bufnr, diagnostics, opts)
```
This overrides Neovim’s default diagnostic display and uses lsp_lines.render.show() instead.

- Handles per-line diagnostics (only showing errors on the current line if configured):

```lua
if opts.virtual_lines.only_current_line then
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = bufnr,
    callback = function()
      render_current_line(diagnostics, ns.user_data.virt_lines_ns, bufnr, opts)
    end,
  })
```


## render.lua: The Renderer
This module actually draws the diagnostic messages as virtual text.

Key Functions
1. M.show(namespace, bufnr, diagnostics, opts, source)
    This is where diagnostics are converted into fancy multi-line virtual text.
Steps:
	1.	Sort diagnostics by line/column.
	2.	Clear previous virtual text (vim.api.nvim_buf_clear_namespace).
	3.	Build the visual layout:
	•	Each diagnostic gets processed and broken into symbols + message.
	•	Uses characters like "│", "└", "──── " for a nice visual hierarchy.
	4.	Insert the formatted text as virtual lines using vim.api.nvim_buf_set_extmark.

How it aligns messages properly:

```lua
local function distance_between_cols(bufnr, lnum, start_col, end_col)
  local lines = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)
  local sub = string.sub(lines[1], start_col, end_col)

  return vim.fn.strdisplaywidth(sub, 0)
```
