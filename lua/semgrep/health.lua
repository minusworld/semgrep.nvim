local config = require("semgrep.config")

local M = {}

local function start(msg)
  (vim.health.start or vim.health.report_start)(msg)
end
local function ok(msg)
  (vim.health.ok or vim.health.report_ok)(msg)
end
local function warn(msg)
  (vim.health.warn or vim.health.report_warn)(msg)
end
local function err(msg)
  (vim.health.error or vim.health.report_error)(msg)
end

function M.check()
  start("semgrep.nvim")

  local cmd = config.options.cmd or "semgrep"
  if vim.fn.executable(cmd) == 1 then
    local out = vim.fn.system({ cmd, "--version" })
    ok(("`%s` found: %s"):format(cmd, vim.trim(out)))
  else
    err(("`%s` not found on PATH. Install: https://semgrep.dev/docs/getting-started/"):format(cmd))
  end

  if pcall(require, "telescope") then
    ok("telescope.nvim is available (rich picker enabled)")
  else
    warn("telescope.nvim not found — falling back to the quickfix list")
  end

  if vim.json and vim.json.decode then
    ok("vim.json available")
  else
    err("vim.json not available — Neovim 0.9+ required")
  end
end

return M
