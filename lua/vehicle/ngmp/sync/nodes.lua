
local M = {
  name = "nodes",
  abbreviation = "n",
  author = "DaddelZeit (NGMP Official)"
}

local function get()
  local data = {}
  for _, node in pairs(v.data.nodes) do
    local pos = obj:getNodePosition(node.cid)
    data[tonumber(node.cid)+1] = obj:getNodeVelocityVector(node.cid):toTable()
  end
  return data
end

local tempVec = vec3()
local function set(data)
  for nodeCid, nodePos in pairs(data) do
    tempVec:set(nodePos[1], nodePos[2], nodePos[3])

    --[[
    local setToPos = tempVec
    setToPos.x = round(setToPos.x*10000)/10000
    setToPos.y = round(setToPos.y*10000)/10000
    setToPos.z = round(setToPos.z*10000)/10000
    obj:setNodePosition(nodeCid-1, ngmp_transformSync.received.pos-ngmp_transformSync.current.pos+setToPos)
    ]]
  end
end

local function onExtensionLoaded()
end

M.set = set
M.get = get
M.onExtensionLoaded = onExtensionLoaded

return M
