local h = require("tests.helpers")
local input = require("semgrep.input")

h.describe("input.prepare_pattern", function()
  h.it("joins lines with newlines", function()
    local result = input.prepare_pattern({ "class $X:", "    def $M():", "        ..." })
    h.eq("class $X:\n    def $M():\n        ...", result)
  end)

  h.it("strips trailing empty lines", function()
    local result = input.prepare_pattern({ "foo($X)", "", "" })
    h.eq("foo($X)", result)
  end)

  h.it("preserves internal empty lines", function()
    local result = input.prepare_pattern({ "line1", "", "line3" })
    h.eq("line1\n\nline3", result)
  end)

  h.it("returns nil for all-empty input", function()
    local result = input.prepare_pattern({ "", "", "" })
    h.is_nil(result)
  end)

  h.it("returns nil for empty table", function()
    local result = input.prepare_pattern({})
    h.is_nil(result)
  end)

  h.it("handles single line", function()
    local result = input.prepare_pattern({ "$X = $Y" })
    h.eq("$X = $Y", result)
  end)

  h.it("preserves indentation", function()
    local result = input.prepare_pattern({ "if $X:", "\t$Y" })
    h.eq("if $X:\n\t$Y", result)
  end)
end)
