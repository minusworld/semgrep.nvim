local h = require("tests.helpers")
local parser = require("semgrep.parser")

h.describe("parser.parse lines and metavars", function()
  h.it("captures extra.lines when present", function()
    local json = vim.json.encode({
      results = { {
        path = "/tmp/test.py",
        check_id = "-",
        start = { line = 1, col = 1, offset = 0 },
        ["end"] = { line = 1, col = 10, offset = 9 },
        extra = {
          message = "x = 42",
          severity = "ERROR",
          metadata = {},
          lines = "x = 42",
        },
      } },
    })
    local findings = parser.parse(json)
    h.eq(1, #findings)
    h.eq("x = 42", findings[1].lines)
  end)

  h.it("captures extra.metavars when present", function()
    local metavars = {
      ["$X"] = {
        start = { line = 1, col = 1, offset = 0 },
        ["end"] = { line = 1, col = 2, offset = 1 },
        abstract_content = "x",
      },
    }
    local json = vim.json.encode({
      results = { {
        path = "/tmp/test.py",
        check_id = "-",
        start = { line = 1, col = 1, offset = 0 },
        ["end"] = { line = 1, col = 10, offset = 9 },
        extra = {
          message = "x = 42",
          severity = "ERROR",
          metadata = {},
          metavars = metavars,
        },
      } },
    })
    local findings = parser.parse(json)
    h.eq(1, #findings)
    h.ok(findings[1].metavars, "metavars should be present")
    h.eq("x", findings[1].metavars["$X"].abstract_content)
  end)

  h.it("sets lines to nil when absent", function()
    local json = vim.json.encode({
      results = { {
        path = "/tmp/test.py",
        check_id = "some.rule",
        start = { line = 1, col = 1, offset = 0 },
        ["end"] = { line = 1, col = 10, offset = 9 },
        extra = {
          message = "a message",
          severity = "WARNING",
          metadata = {},
        },
      } },
    })
    local findings = parser.parse(json)
    h.eq(1, #findings)
    h.is_nil(findings[1].lines)
    h.is_nil(findings[1].metavars)
  end)

  h.it("preserves existing fields unchanged", function()
    local json = vim.json.encode({
      results = { {
        path = "/tmp/test.py",
        check_id = "my.rule",
        start = { line = 5, col = 3, offset = 40 },
        ["end"] = { line = 5, col = 20, offset = 57 },
        extra = {
          message = "found something",
          severity = "WARNING",
          fix = "replacement",
          metadata = { links = { "https://example.com" } },
          lines = "  the source line",
        },
      } },
    })
    local findings = parser.parse(json)
    h.eq("my.rule", findings[1].check_id)
    h.eq("found something", findings[1].message)
    h.eq(vim.diagnostic.severity.WARN, findings[1].severity)
    h.eq("replacement", findings[1].fix)
    h.eq({ "https://example.com" }, findings[1].links)
    h.eq("  the source line", findings[1].lines)
  end)
end)
