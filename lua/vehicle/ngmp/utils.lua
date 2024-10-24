
local M = {}

local function switchKeysAndValues(inputTable)
  local switchedTable = {}
  for key, value in pairs(inputTable) do
    switchedTable[value] = key
  end
  return switchedTable
end

M.switchKeysAndValues = switchKeysAndValues

return M