local h = require("tests.helpers")
local search = require("semgrep.search")

h.describe("search.build_cmd", function()
  h.it("builds correct argv for pattern search", function()
    local cmd = search.build_cmd("$X = $Y", "python", "/tmp/project")
    h.eq({ "semgrep", "scan", "--json", "--quiet", "-l", "python", "-e", "$X = $Y", "/tmp/project" }, cmd)
  end)

  h.it("does not include --config flags", function()
    local cmd = search.build_cmd("$X", "lua", ".")
    for _, arg in ipairs(cmd) do
      h.neq("--config", arg, "should not contain --config")
    end
  end)

  h.it("uses the configured cmd from config", function()
    local config = require("semgrep.config")
    local original = config.options.cmd
    config.options.cmd = "/usr/local/bin/semgrep"
    local cmd = search.build_cmd("$X", "go", ".")
    h.eq("/usr/local/bin/semgrep", cmd[1])
    config.options.cmd = original
  end)

  h.it("preserves the pattern exactly", function()
    local pattern = "$FN($...ARGS)"
    local cmd = search.build_cmd(pattern, "javascript", ".")
    h.eq(pattern, cmd[8])
  end)
end)
