local config = require("semgrep.config")
local store = require("semgrep.store")

local M = {}

local SEV_LABEL = {
  [vim.diagnostic.severity.ERROR] = "ERROR",
  [vim.diagnostic.severity.WARN] = "WARN",
  [vim.diagnostic.severity.INFO] = "INFO",
}

--- Send the current findings to the quickfix list and open it.
---@param findings SemgrepFinding[]|nil
function M.to_quickfix(findings)
  findings = findings or store.all
  local items = {}
  for _, f in ipairs(findings) do
    table.insert(items, {
      filename = f.path,
      lnum = f.start.line,
      col = f.start.col,
      text = ("[%s] %s: %s"):format(SEV_LABEL[f.severity] or "INFO", f.check_id, f.message),
      type = f.severity == vim.diagnostic.severity.ERROR and "E"
        or (f.severity == vim.diagnostic.severity.WARN and "W" or "I"),
    })
  end

  vim.fn.setqflist({}, " ", { title = "Semgrep", items = items })
  if #items > 0 then
    vim.cmd("copen")
  else
    vim.notify("semgrep: no findings", vim.log.levels.INFO)
  end
end

--- Open findings in a telescope picker, falling back to quickfix if unavailable.
---@param findings SemgrepFinding[]|nil
function M.to_telescope(findings)
  findings = findings or store.all

  local has_telescope, pickers = pcall(require, "telescope.pickers")
  if not (has_telescope and config.options.use_telescope) then
    return M.to_quickfix(findings)
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  pickers
    .new({}, {
      prompt_title = "Semgrep Findings",
      finder = finders.new_table({
        results = findings,
        entry_maker = function(f)
          local display = ("%-5s %s  %s"):format(SEV_LABEL[f.severity] or "INFO", f.check_id, f.message)
          return {
            value = f,
            display = display,
            ordinal = (SEV_LABEL[f.severity] or "") .. " " .. f.check_id .. " " .. f.message,
            filename = f.path,
            lnum = f.start.line,
            col = f.start.col,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = conf.qflist_previewer({}),
      attach_mappings = function(prompt_bufnr, map)
        -- <CR>: jump to the finding.
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local entry = action_state.get_selected_entry()
          if not entry then
            return
          end
          local f = entry.value
          vim.cmd("edit " .. vim.fn.fnameescape(f.path))
          vim.api.nvim_win_set_cursor(0, { f.start.line, math.max(f.start.col - 1, 0) })
        end)

        -- <C-f>: apply the data-driven autofix for the selected finding.
        local function apply_fix()
          local entry = action_state.get_selected_entry()
          if not entry then
            return
          end
          local f = entry.value
          if type(f.fix) ~= "string" then
            vim.notify("semgrep: no autofix for " .. f.check_id, vim.log.levels.INFO)
            return
          end
          actions.close(prompt_bufnr)
          vim.cmd("edit " .. vim.fn.fnameescape(f.path))
          local bufnr = vim.api.nvim_get_current_buf()
          vim.api.nvim_win_set_cursor(0, { f.start.line, math.max(f.start.col - 1, 0) })
          require("semgrep.fix").fix_at_cursor(bufnr)
        end
        map("i", "<C-f>", apply_fix)
        map("n", "<C-f>", apply_fix)
        return true
      end,
    })
    :find()
end

--- Open findings using the configured default sink.
---@param findings SemgrepFinding[]|nil
function M.open(findings)
  if config.options.use_telescope then
    M.to_telescope(findings)
  else
    M.to_quickfix(findings)
  end
end

return M
