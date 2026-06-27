-- In-memory store of the most recent scan findings.
local M = {}

---@type SemgrepFinding[]
M.all = {}

---@type table<string, SemgrepFinding[]>
M.by_path = {}

--- Replace findings for a single file (used by single-file scans).
---@param path string
---@param findings SemgrepFinding[]
function M.set_file(path, findings)
  M.by_path[path] = findings
  -- Rebuild the flat list from the per-path map.
  M.all = {}
  for _, list in pairs(M.by_path) do
    vim.list_extend(M.all, list)
  end
end

--- Replace the entire store (used by workspace scans).
---@param findings SemgrepFinding[]
function M.set_all(findings)
  M.all = findings
  M.by_path = {}
  for _, f in ipairs(findings) do
    M.by_path[f.path] = M.by_path[f.path] or {}
    table.insert(M.by_path[f.path], f)
  end
end

--- Findings for a path, sorted top-to-bottom (so column shifts stay predictable).
---@param path string
---@return SemgrepFinding[]
function M.for_path(path)
  return M.by_path[path] or {}
end

function M.clear()
  M.all = {}
  M.by_path = {}
end

return M
