-- Guard against double-loading. The plugin does nothing until require("semgrep").setup() is called.
if vim.g.loaded_semgrep_nvim then
  return
end
vim.g.loaded_semgrep_nvim = true

if vim.fn.has("nvim-0.9") ~= 1 then
  vim.notify("semgrep.nvim requires Neovim 0.9+", vim.log.levels.ERROR)
  return
end
