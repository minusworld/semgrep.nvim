local config = require("semgrep.config")

local M = {}

-- Re-exported submodules for programmatic use.
M.scan = require("semgrep.scan")
M.fix = require("semgrep.fix")
M.hover = require("semgrep.hover")
M.pickers = require("semgrep.pickers")
M.store = require("semgrep.store")
M.search = require("semgrep.search")

--- Toggle the autofix-on-scan behaviour at runtime.
---@param enabled boolean|nil When nil, flips current value.
function M.toggle_autofix(enabled)
  if enabled == nil then
    enabled = not config.options.autofix
  end
  config.options.autofix = enabled
  vim.notify("semgrep: autofix " .. (enabled and "enabled" or "disabled"))
end

--- Toggle documentation-link virtual text and redraw the current buffer.
---@param enabled boolean|nil
function M.toggle_virtual_text(enabled)
  if enabled == nil then
    enabled = not config.options.virtual_text_links
  end
  config.options.virtual_text_links = enabled
  M.hover.refresh_virtual_text()
  vim.notify("semgrep: doc-link virtual text " .. (enabled and "enabled" or "disabled"))
end

local function create_commands()
  vim.api.nvim_create_user_command("SemgrepScan", function()
    M.scan.scan_current_file()
  end, { desc = "Semgrep: scan the current file" })

  vim.api.nvim_create_user_command("SemgrepScanWorkspace", function(args)
    local root = args.args ~= "" and args.args or nil
    M.scan.scan_workspace(root, function(findings)
      M.pickers.open(findings)
    end)
  end, { nargs = "?", complete = "dir", desc = "Semgrep: scan the workspace and open the picker" })

  vim.api.nvim_create_user_command("SemgrepFindings", function()
    M.pickers.open()
  end, { desc = "Semgrep: open the last findings in telescope/quickfix" })

  vim.api.nvim_create_user_command("SemgrepQuickfix", function()
    M.pickers.to_quickfix()
  end, { desc = "Semgrep: send findings to the quickfix list" })

  vim.api.nvim_create_user_command("SemgrepFix", function()
    M.fix.fix_buffer()
  end, { desc = "Semgrep: apply all autofixes in the current buffer" })

  vim.api.nvim_create_user_command("SemgrepFixCursor", function()
    M.fix.fix_at_cursor()
  end, { desc = "Semgrep: apply the autofix under the cursor" })

  vim.api.nvim_create_user_command("SemgrepHover", function()
    M.hover.hover()
  end, { desc = "Semgrep: show finding details + doc links under the cursor" })

  vim.api.nvim_create_user_command("SemgrepToggleAutofix", function()
    M.toggle_autofix()
  end, { desc = "Semgrep: toggle autofix-on-scan" })

  vim.api.nvim_create_user_command("SemgrepToggleLinks", function()
    M.toggle_virtual_text()
  end, { desc = "Semgrep: toggle doc-link virtual text" })

  vim.api.nvim_create_user_command("SemgrepSearch", function(args)
    local pattern = args.args ~= "" and args.args or nil
    require("semgrep.search").search({ pattern = pattern })
  end, { nargs = "?", desc = "Semgrep: search for a code pattern in the workspace" })
end

local function create_autocmds()
  local group = vim.api.nvim_create_augroup("SemgrepNvim", { clear = true })

  if config.options.scan_on_save then
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = group,
      callback = function(ev)
        M.scan.scan_current_file(ev.buf)
      end,
      desc = "Semgrep: scan on save",
    })
  end

  -- Keep doc-link virtual text in sync when a scanned file is shown.
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    group = group,
    callback = function(ev)
      M.hover.refresh_virtual_text(ev.buf)
    end,
    desc = "Semgrep: refresh doc-link virtual text",
  })
end

---@param opts SemgrepConfig|nil
function M.setup(opts)
  config.setup(opts)
  create_commands()
  create_autocmds()
end

return M
