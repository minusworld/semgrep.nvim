local M = {}

---@class SemgrepConfig
---@field cmd string Executable used to invoke semgrep.
---@field config string|string[] Value(s) passed to `--config` (e.g. "auto", "p/ci").
---@field extra_args string[] Additional CLI args appended to every scan.
---@field scan_on_save boolean Re-scan the current file on `BufWritePost`.
---@field autofix boolean When true, applying a fix happens automatically after scan.
---@field virtual_text_links boolean Show documentation links as virtual text on the finding line.
---@field use_telescope boolean Prefer the telescope picker when available; else quickfix.
---@field diagnostic_namespace string Name of the diagnostic namespace.
local defaults = {
  cmd = "semgrep",
  config = "auto",
  extra_args = {},
  scan_on_save = false,
  autofix = false,
  virtual_text_links = true,
  use_telescope = true,
  diagnostic_namespace = "semgrep",
}

M.options = vim.deepcopy(defaults)

---@param opts SemgrepConfig|nil
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  -- tbl_deep_extend merges list-like tables key-by-key; replace wholesale instead.
  if opts and opts.config ~= nil then
    M.options.config = opts.config
  end
  if opts and opts.extra_args ~= nil then
    M.options.extra_args = opts.extra_args
  end
  return M.options
end

return M
