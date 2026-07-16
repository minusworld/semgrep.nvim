local M = {}

---@param lines string[]
---@return string|nil
function M.prepare_pattern(lines)
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines)
  end
  if #lines == 0 then
    return nil
  end
  return table.concat(lines, "\n")
end

---@param opts { lang: string, title: string }
---@param on_submit fun(pattern: string)
function M.open(opts, on_submit)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = opts.lang or ""

  local width = math.min(80, vim.o.columns - 4)
  local height = 8
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    title = opts.title or " Semgrep Pattern ",
    title_pos = "center",
    style = "minimal",
  })

  vim.cmd("startinsert")

  local closed = false
  local function close()
    if closed then
      return
    end
    closed = true
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  local function submit()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    close()
    local pattern = M.prepare_pattern(lines)
    if pattern then
      on_submit(pattern)
    end
  end

  vim.keymap.set("n", "<CR>", submit, { buffer = buf })
  vim.keymap.set("i", "<C-CR>", submit, { buffer = buf })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf })
  vim.keymap.set("n", "q", close, { buffer = buf })

  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = buf,
    once = true,
    callback = close,
  })
end

return M
