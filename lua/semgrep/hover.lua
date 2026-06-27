local config = require("semgrep.config")
local store = require("semgrep.store")

local M = {}

local vt_ns = vim.api.nvim_create_namespace("semgrep_links")

--- Draw documentation links as virtual text at the end of each finding's line.
---@param bufnr integer|nil
function M.refresh_virtual_text(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, vt_ns, 0, -1)

  if not config.options.virtual_text_links then
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  for _, f in ipairs(store.for_path(path)) do
    if #f.links > 0 then
      local row = f.start.line - 1
      if row >= 0 and row < line_count then
        local label = (" 󰌹 %d doc link%s"):format(#f.links, #f.links > 1 and "s" or "")
        vim.api.nvim_buf_set_extmark(bufnr, vt_ns, row, 0, {
          virt_text = { { label, "Comment" } },
          virt_text_pos = "eol",
        })
      end
    end
  end
end

--- Open a floating window with the finding(s) under the cursor: message + links.
---@param bufnr integer|nil
function M.hover(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  local line = vim.api.nvim_win_get_cursor(0)[1] -- 1-based

  local matched = {}
  for _, f in ipairs(store.for_path(path)) do
    if f.start.line <= line and line <= f.finish.line then
      table.insert(matched, f)
    end
  end

  if #matched == 0 then
    vim.notify("semgrep: no finding at cursor", vim.log.levels.INFO)
    return
  end

  local lines = {}
  for i, f in ipairs(matched) do
    if i > 1 then
      table.insert(lines, "")
    end
    table.insert(lines, "# " .. f.check_id)
    table.insert(lines, "")
    for _, mline in ipairs(vim.split(f.message, "\n", { plain = true })) do
      table.insert(lines, mline)
    end
    if f.fix then
      table.insert(lines, "")
      table.insert(lines, "_Autofix available — :SemgrepFix_")
    end
    if #f.links > 0 then
      table.insert(lines, "")
      table.insert(lines, "## Documentation")
      for _, link in ipairs(f.links) do
        table.insert(lines, "- " .. link)
      end
    end
  end

  -- Reuse the built-in markdown float helper from lsp.util.
  vim.lsp.util.open_floating_preview(lines, "markdown", {
    border = "rounded",
    focus_id = "semgrep_hover",
    wrap = true,
  })
end

M.namespace = vt_ns

return M
