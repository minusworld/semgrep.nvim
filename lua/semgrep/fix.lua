local store = require("semgrep.store")

local M = {}

--- Apply a single finding's `match.extra.fix` to a buffer via nvim_buf_set_text.
--- Semgrep ranges are 1-based with an exclusive end column; nvim_buf_set_text
--- wants 0-based rows/cols with an exclusive end — so we subtract 1 throughout.
---@param bufnr integer
---@param f SemgrepFinding
---@return boolean applied
local function apply_one(bufnr, f)
  if type(f.fix) ~= "string" then
    return false
  end

  local start_row = f.start.line - 1
  local start_col = f.start.col - 1
  local end_row = f.finish.line - 1
  local end_col = math.max(f.finish.col - 1, 0)

  local lines = vim.split(f.fix, "\n", { plain = true })

  local ok, err = pcall(vim.api.nvim_buf_set_text, bufnr, start_row, start_col, end_row, end_col, lines)
  if not ok then
    vim.notify("semgrep: failed to apply fix for " .. f.check_id .. " (" .. tostring(err) .. ")", vim.log.levels.WARN)
    return false
  end
  return true
end

--- Apply every available autofix in a buffer, bottom-to-top so earlier edits
--- don't invalidate the ranges of later ones.
---@param bufnr integer|nil
---@return integer applied_count
function M.fix_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  local findings = vim.deepcopy(store.for_path(path))

  -- Only fixable findings, ordered last-occurrence-first.
  local fixable = vim.tbl_filter(function(f)
    return type(f.fix) == "string"
  end, findings)

  table.sort(fixable, function(a, b)
    if a.start.line ~= b.start.line then
      return a.start.line > b.start.line
    end
    return a.start.col > b.start.col
  end)

  local count = 0
  for _, f in ipairs(fixable) do
    if apply_one(bufnr, f) then
      count = count + 1
    end
  end

  if count > 0 then
    vim.notify(("semgrep: applied %d fix(es)"):format(count))
    -- Ranges are now stale; re-scan to refresh diagnostics/store.
    require("semgrep.scan").scan_current_file(bufnr)
  else
    vim.notify("semgrep: no autofixes available for this buffer", vim.log.levels.INFO)
  end
  return count
end

--- Apply the autofix for the finding under the cursor, if any.
---@param bufnr integer|nil
function M.fix_at_cursor(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] -- 1-based

  for _, f in ipairs(store.for_path(path)) do
    if f.start.line <= line and line <= f.finish.line and type(f.fix) == "string" then
      if apply_one(bufnr, f) then
        vim.notify("semgrep: applied fix for " .. f.check_id)
        require("semgrep.scan").scan_current_file(bufnr)
      end
      return
    end
  end
  vim.notify("semgrep: no autofix at cursor", vim.log.levels.INFO)
end

return M
