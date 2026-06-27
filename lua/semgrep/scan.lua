local config = require("semgrep.config")
local parser = require("semgrep.parser")
local store = require("semgrep.store")

local M = {}

local ns = vim.api.nvim_create_namespace("semgrep")

--- Build the semgrep argv for a given target (file or directory).
---@param target string
---@return string[]
local function build_cmd(target)
  local opts = config.options
  local cmd = { opts.cmd, "scan", "--json", "--quiet" }

  local cfg = opts.config
  if type(cfg) == "table" then
    for _, c in ipairs(cfg) do
      vim.list_extend(cmd, { "--config", c })
    end
  elseif type(cfg) == "string" then
    vim.list_extend(cmd, { "--config", cfg })
  end

  vim.list_extend(cmd, opts.extra_args or {})
  table.insert(cmd, target)
  return cmd
end

--- Push findings for a buffer into the diagnostic framework.
---@param bufnr integer
---@param findings SemgrepFinding[]
local function set_diagnostics(bufnr, findings)
  local diagnostics = {}
  for _, f in ipairs(findings) do
    table.insert(diagnostics, {
      lnum = f.start.line - 1,
      col = f.start.col - 1,
      end_lnum = f.finish.line - 1,
      end_col = math.max(f.finish.col - 1, 0),
      severity = f.severity,
      message = f.message,
      source = "semgrep",
      code = f.check_id,
    })
  end
  vim.diagnostic.set(ns, bufnr, diagnostics)
end

--- Refresh diagnostics for any loaded buffer that has findings.
local function refresh_loaded_buffers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name ~= "" then
        set_diagnostics(bufnr, store.for_path(name))
        require("semgrep.hover").refresh_virtual_text(bufnr)
      end
    end
  end
end

--- Run a scan against `target`, then invoke `on_done(findings)` on the main loop.
---@param target string
---@param on_done fun(findings: SemgrepFinding[])
local function run(target, on_done)
  local cmd = build_cmd(target)

  local ok, err = pcall(vim.system, cmd, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 and (obj.stdout == nil or obj.stdout == "") then
        vim.notify("semgrep failed: " .. (obj.stderr or "unknown error"), vim.log.levels.ERROR)
        return
      end

      local findings, perr = parser.parse(obj.stdout)
      if not findings then
        vim.notify("semgrep: " .. (perr or "parse error"), vim.log.levels.ERROR)
        return
      end

      on_done(findings)
    end)
  end)

  if not ok then
    vim.notify("semgrep: could not spawn `" .. config.options.cmd .. "` (" .. tostring(err) .. ")", vim.log.levels.ERROR)
  end
end

--- Scan the current file and set diagnostics on its buffer.
---@param bufnr integer|nil
function M.scan_current_file(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" or vim.bo[bufnr].buftype ~= "" then
    return
  end

  run(path, function(findings)
    store.set_file(path, findings)
    if vim.api.nvim_buf_is_valid(bufnr) then
      set_diagnostics(bufnr, findings)
      require("semgrep.hover").refresh_virtual_text(bufnr)
    end
    vim.notify(("semgrep: %d finding(s) in %s"):format(#findings, vim.fn.fnamemodify(path, ":t")))

    if config.options.autofix then
      require("semgrep.fix").fix_buffer(bufnr)
    end
  end)
end

--- Scan an entire project workspace (defaults to cwd).
---@param root string|nil
---@param on_done fun(findings: SemgrepFinding[])|nil
function M.scan_workspace(root, on_done)
  root = root or vim.fn.getcwd()
  vim.notify("semgrep: scanning " .. root .. " ...")

  run(root, function(findings)
    store.set_all(findings)
    refresh_loaded_buffers()
    vim.notify(("semgrep: %d finding(s) across workspace"):format(#findings))
    if on_done then
      on_done(findings)
    end
  end)
end

M.namespace = ns
M.set_diagnostics = set_diagnostics

return M
