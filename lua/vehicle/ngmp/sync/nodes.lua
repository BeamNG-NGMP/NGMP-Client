
local M = {
  name = "nodes",
  abbreviation = "n",
  author = "DaddelZeit (NGMP Official)"
}

local function get()
  local data = {}
  for _, node in pairs(v.data.nodes) do
    data[tonumber(node.cid)] = obj:getNodePosition(node.cid):toTable()
  end
  return data
end

local receivedNodes
local function set(data)
  receivedNodes = data
end

local newNodePos = vec3()
local function onPhysicsStep(dt)
  -- there's a *lot* of iterations down below,
  -- we need to save as many table lookups as we can
  local lerp = ngmp_transformSync.stepSize
  local receiveTransform = ngmp_transformSync.received
  local currentTransform = ngmp_transformSync.current
  if not receivedNodes or not receiveTransform or not currentTransform then return end

  for nodeCid = 0, tableSizeC(receivedNodes) do
    local nodePos = receivedNodes[nodeCid]
    local prevNodePos = currentTransform.pos+obj:getNodePosition(nodeCid)

    newNodePos:set(nodePos[1], nodePos[2], nodePos[3])
    newNodePos = receiveTransform.pos+newNodePos

    obj:setNodePosition(nodeCid, (prevNodePos-newNodePos)*lerp)
  end
end

local function init(mode, vehFullId)
end

M.set = set
M.get = get
M.onPhysicsStep = onPhysicsStep
M.init = init

return M
