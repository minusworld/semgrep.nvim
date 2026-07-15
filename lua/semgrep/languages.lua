local M = {}

local ft_to_lang = {
  apex = "apex",
  bash = "bash",
  c = "c",
  cairo = "cairo",
  clojure = "clojure",
  cpp = "cpp",
  cs = "csharp",
  dart = "dart",
  dockerfile = "dockerfile",
  elixir = "elixir",
  go = "go",
  hack = "hack",
  hcl = "hcl",
  html = "html",
  java = "java",
  javascript = "javascript",
  javascriptreact = "javascript",
  json = "json",
  jsonnet = "jsonnet",
  julia = "julia",
  kotlin = "kotlin",
  lisp = "lisp",
  lua = "lua",
  ocaml = "ocaml",
  php = "php",
  powershell = "powershell",
  promql = "promql",
  proto = "proto",
  python = "python",
  r = "r",
  ruby = "ruby",
  rust = "rust",
  scala = "scala",
  scheme = "scheme",
  sh = "bash",
  solidity = "solidity",
  swift = "swift",
  terraform = "terraform",
  tf = "terraform",
  typescript = "typescript",
  typescriptreact = "typescript",
  vue = "vue",
  xml = "xml",
  yaml = "yaml",
  zsh = "bash",
}

---@param filetype string Neovim filetype (vim.bo.filetype)
---@return string|nil Semgrep language identifier, or nil if unsupported
function M.from_filetype(filetype)
  if not filetype or filetype == "" then
    return nil
  end
  return ft_to_lang[filetype]
end

---@return string[] Sorted list of unique semgrep language names
function M.supported()
  local seen = {}
  local list = {}
  for _, lang in pairs(ft_to_lang) do
    if not seen[lang] then
      seen[lang] = true
      table.insert(list, lang)
    end
  end
  table.sort(list)
  return list
end

return M
