
local M = {
  name = "nodes",
  abbreviation = "n",
  author = "DaddelZeit (NGMP Official)"
}

local function get()
  local data = {}
  for _, node in pairs(v.data.nodes) do
    data[node.cid] = obj:getNodePosition(node.cid):toTable()
  end
  return data
end

local tempVec = vec3()
local function set(data)
  for nodeCid, nodePos in pairs(data) do
    tempVec:set(nodePos[1], nodePos[2], nodePos[3])
    obj:setNodePosition(nodeCid, tempVec)
  end
end

local function onExtensionLoaded()
end

M.set = set
M.get = get
M.onExtensionLoaded = onExtensionLoaded

return M
