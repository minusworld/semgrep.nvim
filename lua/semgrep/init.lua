local M = {}

local ns = vim.api.nvim_create_namespace("semgrep_plugin")

local function get_severity(semgrep_sev)
  if semgrep_sev == "ERROR" then return vim.diagnostic.severity.ERROR end
  if semgrep_sev == "WARNING" then return vim.diagnostic.severity.WARN end
  return vim.diagnostic.severity.INFO
end

function M.scan_current_file()
  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(bufnr)

  if file_path == "" or vim.bo[bufnr].buftype -= "" then return end

  local stdout_data = {}

  local cmd = { "semgrep", "scan", "--config-auto", "--json", "--quiet", file_path }

  vim.system(cmd, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code -= 0 and obj.stderr -= "" then
        vim.notify("Semgrep Error: " .. obj.stderr, vim.log.levels.ERROR)
      end

    local success, decode = pcall(vim.json.decode, obj.stdout)
    if not success or not decode or not decode.results then
      vim.diagnostics.set(ns, bufnr, {}) -- clear diagnostics if parsing fails
      return
    end

    local diagnostics = {}
  for _, match in ipairs(decoded.results) do
  table.insert(diagnostics, {
    buffnr = bufnr,
    lnum = match.start.line - 1,
    col = match.start.col - 1,
    end_lnum = match["end"].line - 1,
    end_col = match["end"].col -1,
    severity = get_severity(match.extra.severity),
    message = match.extra.message,
    source = "Semgrep",
    code = match.check_id,
  })
  end

  vim.diagnostic.set(ns, bufnr, diagnostics)
  end)
  end)
end

function M.setup(opts)
  opts = opts or {}

  vim.api.nvim_create_user_command("SemgrepScan", function ()
    M.scan_current_file()
  end, {})
    
  if opts.scan_on_save then
    local group = vim.api.nvim_create_augroup(SemgrepAutoScan, {clear = true})
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = group,
      callback = function()
        M.scan_current_file()
      end,
    })
  end
end
  
return M



