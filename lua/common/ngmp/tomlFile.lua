local M = {}

local toml = require("ngmp/toml")

function M.readFile(filename)
  local f = io.open(filename, "r")
  if f == nil then
    return nil
  end
  local content = toml.parse(f:read("*all"))
  f:close()
  return content
end

-- writes text to a file
function M.writeFile(filename, data)
  local file, err = io.open(filename, 'w')
  if file == nil then
    log('W', "writeFile", "Error opening file for writing: "..filename..": "..err)
    return nil
  end
  file:write(toml.encode(data))
  file:close()
  return true
end

return M