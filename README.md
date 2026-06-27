# semgrep.nvim

Run [Semgrep](https://semgrep.dev) inside Neovim. Scan files or the whole
workspace, browse findings in Telescope or the quickfix list, apply Semgrep's
data-driven autofixes, and surface rule documentation links on hover.

## Features

- **Diagnostics** — `:SemgrepScan` runs `semgrep scan --json` on the current
  file and publishes results through `vim.diagnostic`.
- **Workspace scan + Telescope/quickfix** — `:SemgrepScanWorkspace` scans the
  whole project and pipes every finding into a searchable Telescope picker
  (falls back to the quickfix list when Telescope is absent).
- **Toggled autofixes** — pulls the replacement string from `match.extra.fix`
  and applies it with `nvim_buf_set_text`. Run on command (`:SemgrepFix`,
  `:SemgrepFixCursor`, `<C-f>` in the picker) or automatically after each scan
  (`:SemgrepToggleAutofix`).
- **Doc links on hover** — `:SemgrepHover` shows the finding message plus the
  rule's `match.extra.metadata.links`. A virtual-text marker flags lines that
  carry documentation links.

## Prerequisites

| Requirement         | Notes                                                                                                                |
| ------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Neovim **0.9+**     | Needs `vim.system` and `vim.json`.                                                                                   |
| `semgrep` on `PATH` | `pip install semgrep`, `brew install semgrep`, or see the [install docs](https://semgrep.dev/docs/getting-started/). |
| `telescope.nvim`    | Optional. Without it the plugin uses the quickfix list.                                                              |

Verify your setup any time with:

```vim
:checkhealth semgrep
```

## Install

The plugin loads its commands lazily — call `require("semgrep").setup()` once.
`setup()` accepts an optional config table (see [Configuration](#configuration)).

<details open>
<summary><b>lazy.nvim</b></summary>

```lua
{
  "tumillanino/semgrep.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" }, -- optional
  cmd = { "SemgrepScan", "SemgrepScanWorkspace", "SemgrepFindings", "SemgrepFix" },
  opts = {}, -- same as require("semgrep").setup({})
}
```

</details>

<details>
<summary><b>packer.nvim</b></summary>

```lua
use({
  "tumillanino/semgrep.nvim",
  requires = { "nvim-telescope/telescope.nvim" }, -- optional
  config = function()
    require("semgrep").setup()
  end,
})
```

</details>

<details>
<summary><b>vim-plug</b></summary>

```vim
Plug 'nvim-telescope/telescope.nvim'  " optional
Plug 'tumillanino/semgrep.nvim'
```

Then in your `init.lua` (or a `lua << EOF` block in `init.vim`):

```lua
require("semgrep").setup()
```

</details>

<details>
<summary><b>mini.deps</b></summary>

```lua
require("mini.deps").add({
  source = "tumillanino/semgrep.nvim",
  depends = { "nvim-telescope/telescope.nvim" }, -- optional
})
require("semgrep").setup()
```

</details>

### LazyVim

Drop a file in `~/.config/nvim/lua/plugins/semgrep.lua`:

```lua
return {
  {
    "tumillanino/semgrep.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    cmd = { "SemgrepScan", "SemgrepScanWorkspace", "SemgrepFindings", "SemgrepFix" },
    opts = {
      scan_on_save = true,
    },
    keys = {
      { "<leader>ss", "<cmd>SemgrepScan<cr>",          desc = "Semgrep: scan file" },
      { "<leader>sw", "<cmd>SemgrepScanWorkspace<cr>", desc = "Semgrep: scan workspace" },
      { "<leader>sf", "<cmd>SemgrepFix<cr>",           desc = "Semgrep: apply fixes" },
      { "<leader>sh", "<cmd>SemgrepHover<cr>",         desc = "Semgrep: hover docs" },
    },
  },
}
```

LazyVim already ships Telescope, so no extra dependency is needed in practice.

### NvChad

NvChad uses lazy.nvim under the hood. Add a spec in
`~/.config/nvim/lua/plugins/init.lua` (or any file the NvChad plugin loader
imports):

```lua
return {
  {
    "tumillanino/semgrep.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" }, -- ships with NvChad
    cmd = { "SemgrepScan", "SemgrepScanWorkspace", "SemgrepFindings", "SemgrepFix" },
    config = function()
      require("semgrep").setup()
    end,
  },
}
```

Add mappings the NvChad way in `lua/mappings.lua`:

```lua
local map = vim.keymap.set
map("n", "<leader>ss", "<cmd>SemgrepScan<cr>",          { desc = "Semgrep scan file" })
map("n", "<leader>sw", "<cmd>SemgrepScanWorkspace<cr>", { desc = "Semgrep scan workspace" })
map("n", "<leader>sf", "<cmd>SemgrepFix<cr>",           { desc = "Semgrep apply fixes" })
```

## Configuration

`setup()` defaults — pass only the keys you want to override:

```lua
require("semgrep").setup({
  cmd = "semgrep",            -- executable
  config = "auto",            -- --config value(s); string or string[] e.g. {"p/ci","auto"}
  extra_args = {},            -- extra CLI args appended to every scan
  scan_on_save = false,       -- re-scan the current file on BufWritePost
  autofix = false,            -- apply available fixes automatically after a scan
  virtual_text_links = true,  -- show a doc-link marker as virtual text
  use_telescope = true,       -- prefer telescope; falls back to quickfix
})
```

## Usage

| Command                       | Description                                |
| ----------------------------- | ------------------------------------------ |
| `:SemgrepScan`                | Scan the current file → diagnostics        |
| `:SemgrepScanWorkspace [dir]` | Scan workspace (default cwd) → picker      |
| `:SemgrepFindings`            | Reopen last findings in telescope/quickfix |
| `:SemgrepQuickfix`            | Send last findings to the quickfix list    |
| `:SemgrepFix`                 | Apply all autofixes in the current buffer  |
| `:SemgrepFixCursor`           | Apply the autofix under the cursor         |
| `:SemgrepHover`               | Show finding details + doc links at cursor |
| `:SemgrepToggleAutofix`       | Toggle autofix-on-scan                     |
| `:SemgrepToggleLinks`         | Toggle doc-link virtual text               |

In the Telescope picker: `<CR>` jumps to the finding, `<C-f>` applies its autofix.

## Contributing

Contributions welcome — issues, feature requests, and PRs.

1. Fork and branch off `main`.
2. Keep the module layout: `config`, `parser`, `store`, `scan`, `fix`,
   `hover`, `pickers`, `health`.
3. Sanity-check Lua before pushing:

   ```sh
   # parse-check every file
   for f in lua/semgrep/*.lua plugin/semgrep.lua; do
     luajit -e "assert(loadfile('$f'))" && echo "OK $f"
   done
   ```

4. For behaviour changes, run a quick headless check:

   ```sh
   nvim --headless -u NONE -l your_test.lua
   ```

5. Open a PR describing the change and how you tested it.

Please keep style consistent with the surrounding code (2-space indent,
`---@` annotations on public functions).

## License

See [LICENSE](LICENSE).
