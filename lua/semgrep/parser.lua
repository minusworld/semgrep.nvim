local M = {}

---@class SemgrepFinding
---@field path string Absolute file path of the match.
---@field check_id string Rule id.
---@field message string Human readable finding message.
---@field severity integer A `vim.diagnostic.severity` value.
---@field semgrep_severity string Raw semgrep severity ("ERROR"/"WARNING"/"INFO").
---@field lnum integer 0-based start line (diagnostic/quickfix friendly is 1-based; see fields).
---@field start { line: integer, col: integer } 1-based line, 1-based col.
---@field finish { line: integer, col: integer } 1-based line, 1-based col (exclusive col).
---@field fix string|nil Replacement text from `match.extra.fix`.
---@field lines string|nil Full source text of matched lines.
---@field metavars table|nil Captured metavariable names, positions, and content.
---@field links string[] Documentation links from `match.extra.metadata.links`.
---@field metadata table Raw `match.extra.metadata`.

---@param semgrep_sev string
---@return integer
local function to_diag_severity(semgrep_sev)
  if semgrep_sev == "ERROR" then
    return vim.diagnostic.severity.ERROR
  elseif semgrep_sev == "WARNING" then
    return vim.diagnostic.severity.WARN
  end
  return vim.diagnostic.severity.INFO
end

--- Decode raw semgrep `--json` stdout into a normalized finding list.
---@param stdout string
---@return SemgrepFinding[]|nil findings, string|nil err
function M.parse(stdout)
  if not stdout or stdout == "" then
    return {}
  end

  local ok, decoded = pcall(vim.json.decode, stdout)
  if not ok or type(decoded) ~= "table" or type(decoded.results) ~= "table" then
    return nil, "failed to decode semgrep json output"
  end

  local findings = {}
  for _, match in ipairs(decoded.results) do
    local extra = match.extra or {}
    local metadata = extra.metadata or {}

    local links = {}
    if type(metadata.links) == "table" then
      for _, link in ipairs(metadata.links) do
        if type(link) == "string" then
          table.insert(links, link)
        end
      end
    end

    table.insert(findings, {
      path = match.path,
      check_id = match.check_id or "semgrep",
      message = extra.message or "",
      severity = to_diag_severity(extra.severity),
      semgrep_severity = extra.severity or "INFO",
      lnum = (match.start and match.start.line or 1) - 1,
      start = {
        line = match.start and match.start.line or 1,
        col = match.start and match.start.col or 1,
      },
      finish = {
        line = match["end"] and match["end"].line or 1,
        col = match["end"] and match["end"].col or 1,
      },
      fix = extra.fix,
      lines = extra.lines,
      metavars = extra.metavars,
      links = links,
      metadata = metadata,
    })
  end

  return findings
end

return M
