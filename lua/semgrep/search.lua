local config = require("semgrep.config")
local parser = require("semgrep.parser")
local languages = require("semgrep.languages")

local M = {}

---@type SemgrepFinding[]
M.last_results = {}

---@type string|nil
M.last_pattern = nil

---@param pattern string
---@param lang string
---@param target string
---@return string[]
function M.build_cmd(pattern, lang, target)
  return { config.options.cmd, "scan", "--json", "--quiet", "-l", lang, "-e", pattern, target }
end

---@param pattern string
---@param lang string
---@param target string
---@param on_done fun(findings: SemgrepFinding[])
function M.run(pattern, lang, target, on_done)
  local cmd = M.build_cmd(pattern, lang, target)

  local ok, err = pcall(vim.system, cmd, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 and (obj.stdout == nil or obj.stdout == "") then
        vim.notify("semgrep search failed: " .. (obj.stderr or "unknown error"), vim.log.levels.ERROR)
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

---@param opts { pattern: string|nil, lang: string|nil, target: string|nil }|nil
function M.search(opts)
  opts = opts or {}

  local lang = opts.lang
  if not lang then
    local ft = vim.bo.filetype
    lang = languages.from_filetype(ft)
    if not lang then
      vim.notify(
        ("semgrep: unsupported filetype '%s'. Open a file with a supported language."):format(ft),
        vim.log.levels.ERROR
      )
      return
    end
  end

  local function do_search(pattern)
    if not pattern or pattern == "" then
      return
    end

    local target = opts.target or vim.fn.getcwd()
    vim.notify("semgrep: searching for pattern...")

    M.run(pattern, lang, target, function(findings)
      M.last_results = findings
      M.last_pattern = pattern
      vim.notify(("semgrep: %d match(es) found"):format(#findings))
      vim.schedule(function()
        require("semgrep.pickers").open_search(findings, pattern)
      end)
    end)
  end

  if opts.pattern then
    do_search(opts.pattern)
  else
    require("semgrep.input").open({
      lang = lang,
      title = " Semgrep Pattern (-l " .. lang .. ") ",
    }, do_search)
  end
end

function M.open_last()
  if #M.last_results == 0 then
    vim.notify("semgrep: no previous search results", vim.log.levels.INFO)
    return
  end
  require("semgrep.pickers").open_search(M.last_results, M.last_pattern or "")
end

return M
