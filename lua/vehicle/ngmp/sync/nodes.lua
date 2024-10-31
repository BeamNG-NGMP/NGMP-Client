
local M = {
  name = "nodes",
  abbreviation = "n",
  author = "DaddelZeit (NGMP Official)"
}

local function get()
  local data = {}
  for _, node in pairs(v.data.nodes) do
    data[#data + 1] = obj:getNodePosition(node.cid):toTable()
  end
  return next(data) and data or nil
end

local tempVec = vec3()
local function set(data)
  local i = 1
  for _, node in pairs(v.data.nodes) do
    tempVec:set(data[i][1], data[i][2], data[i][3])
    obj:setNodePosition(node.cid, tempVec)
    i = i + 1
  end
end

local function onExtensionLoaded()
end

M.set = set
M.get = get
M.onExtensionLoaded = onExtensionLoaded

return M