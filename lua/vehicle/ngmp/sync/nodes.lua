
local M = {
  name = "nodes",
  abbreviation = "n",
  author = "DaddelZeit (NGMP Official)"
}

local function get()
  local data = {}
  for _, node in pairs(v.data.nodes) do
    data[tonumber(node.cid)+1] = obj:getNodePosition(node.cid):toTable()
  end
  dump("A")
  return data
end

local tempVec = vec3()
local function set(data)
  for nodeCid, nodePos in pairs(data) do
    tempVec:set(nodePos[1], nodePos[2], nodePos[3])
    obj:setNodePosition(nodeCid-1, tempVec)

    --[[
    local beam = v.data.beams[nodeCid]
    local beamPrecompression = beam.beamPrecompression or 1
    local deformLimit = type(beam.deformLimit) == 'number' and beam.deformLimit or math.huge
    obj:setBeam(-1, beam.id1, beam.id2, beam.beamStrength, beam.beamSpring,
                beam.beamDamp, type(beam.dampCutoffHz) == 'number' and beam.dampCutoffHz or 0,
                beam.beamDeform, deformLimit, type(beam.deformLimitExpansion) == 'number' and beam.deformLimitExpansion or deformLimit,
                beamPrecompression
    )
    ]]
  end
end

local function onExtensionLoaded()
end

M.set = set
M.get = get
M.onExtensionLoaded = onExtensionLoaded

return M
