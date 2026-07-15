local M = {}

local pass_count = 0
local fail_count = 0
local current_describe = ""

function M.describe(name, fn)
  current_describe = name
  fn()
  current_describe = ""
end

function M.it(name, fn)
  local label = current_describe ~= "" and (current_describe .. " > " .. name) or name
  local ok, err = pcall(fn)
  if ok then
    pass_count = pass_count + 1
    io.write("  PASS  " .. label .. "\n")
  else
    fail_count = fail_count + 1
    io.write("  FAIL  " .. label .. "\n")
    io.write("        " .. tostring(err) .. "\n")
  end
end

function M.eq(expected, actual, msg)
  if type(expected) == "table" and type(actual) == "table" then
    local exp_str = vim.inspect(expected)
    local act_str = vim.inspect(actual)
    if exp_str ~= act_str then
      error((msg or "eq") .. "\n  expected: " .. exp_str .. "\n  actual:   " .. act_str, 2)
    end
  elseif expected ~= actual then
    error((msg or "eq") .. "\n  expected: " .. tostring(expected) .. "\n  actual:   " .. tostring(actual), 2)
  end
end

function M.neq(a, b, msg)
  if a == b then
    error((msg or "neq") .. ": values should differ, both are " .. tostring(a), 2)
  end
end

function M.ok(val, msg)
  if not val then
    error((msg or "ok") .. ": expected truthy, got " .. tostring(val), 2)
  end
end

function M.is_nil(val, msg)
  if val ~= nil then
    error((msg or "is_nil") .. ": expected nil, got " .. tostring(val), 2)
  end
end

function M.summary()
  io.write("\n" .. pass_count .. " passed, " .. fail_count .. " failed\n")
  if fail_count > 0 then
    os.exit(1)
  end
end

return M
