local h = require("tests.helpers")
local languages = require("semgrep.languages")

h.describe("languages.from_filetype", function()
  h.it("maps direct matches", function()
    h.eq("python", languages.from_filetype("python"))
    h.eq("lua", languages.from_filetype("lua"))
    h.eq("go", languages.from_filetype("go"))
    h.eq("rust", languages.from_filetype("rust"))
    h.eq("java", languages.from_filetype("java"))
    h.eq("ruby", languages.from_filetype("ruby"))
    h.eq("typescript", languages.from_filetype("typescript"))
    h.eq("javascript", languages.from_filetype("javascript"))
  end)

  h.it("maps neovim-specific mismatches", function()
    h.eq("bash", languages.from_filetype("sh"))
    h.eq("bash", languages.from_filetype("zsh"))
    h.eq("csharp", languages.from_filetype("cs"))
    h.eq("typescript", languages.from_filetype("typescriptreact"))
    h.eq("javascript", languages.from_filetype("javascriptreact"))
    h.eq("terraform", languages.from_filetype("tf"))
  end)

  h.it("returns nil for unknown filetypes", function()
    h.is_nil(languages.from_filetype("unknown_ft"))
    h.is_nil(languages.from_filetype("markdown"))
  end)

  h.it("returns nil for empty string", function()
    h.is_nil(languages.from_filetype(""))
  end)
end)

h.describe("languages.supported", function()
  h.it("returns a sorted list", function()
    local langs = languages.supported()
    for i = 2, #langs do
      h.ok(langs[i - 1] <= langs[i], "expected sorted: " .. langs[i - 1] .. " <= " .. langs[i])
    end
  end)

  h.it("has no duplicates", function()
    local langs = languages.supported()
    local seen = {}
    for _, lang in ipairs(langs) do
      h.is_nil(seen[lang], "duplicate: " .. lang)
      seen[lang] = true
    end
  end)

  h.it("includes common languages", function()
    local langs = languages.supported()
    local set = {}
    for _, l in ipairs(langs) do set[l] = true end
    h.ok(set["python"], "missing python")
    h.ok(set["javascript"], "missing javascript")
    h.ok(set["bash"], "missing bash")
    h.ok(set["csharp"], "missing csharp")
  end)
end)
