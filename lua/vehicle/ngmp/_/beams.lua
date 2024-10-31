
local M = {
  name = "beams",
  abbreviation = "b",
  author = "DaddelZeit (NGMP Official)"
}

local breakBeamCache = {}
local breakGroupCache = {}
local deformBeamCache = {}

local function doubleToBytes(num)
  if not num then return end
  return ffi.string(ffi.new("double[1]", num), 8)
end

local tmpDouble = ffi.new("double[1]")
local function bytesToDouble(str)
  ffi.copy(tmpDouble, str, 4)
  return tmpDouble[0]
end

local function onBeamBroke(id, energy)
  -- only 1 beam for each break group
  local breakGroup = v.data.beams[id].breakGroup
  if breakGroup and breakGroupCache[breakGroup] then return end
  breakBeamCache[#breakBeamCache+1] = id
  breakGroupCache[breakGroup or ""] = true
end

local function onBeamDeformed(id, ratio)
  deformBeamCache[#deformBeamCache+1] = {id, ratio}
end

local function get()
  local targetBreakBeamTbl = table.move(breakBeamCache, 1, 51, 1, {})
  local targetDeformBeamTbl = table.move(deformBeamCache, 1, 51, 1, {})
  breakGroupCache = {}

  local deformTbl = {}
  for i = 1, #targetBreakBeamTbl do
    deformTbl[targetBreakBeamTbl[i]] = 0
    table.remove(breakBeamCache, 1)
  end

  local insert = false
  for i = 1, math.min(50, #targetDeformBeamTbl) do
    table.remove(deformBeamCache, 1)

    local ratio = targetDeformBeamTbl[i][2]
    if math.abs(ratio) > 0.002 then
      insert = true
      deformTbl[targetDeformBeamTbl[i][1]] = doubleToBytes(ratio)
    end
  end

  return insert and deformTbl or nil
end

local function set(data)
  --local beam = v.data.beams[node]
  --local beamPrecompression = beam.beamPrecompression or 1
  --local deformLimit = type(beam.deformLimit) == 'number' and beam.deformLimit or math.huge
  --obj:setBeam(-1, beam.id1, beam.id2, beam.beamStrength, beam.beamSpring,
  --            beam.beamDamp, type(beam.dampCutoffHz) == 'number' and beam.dampCutoffHz or 0,
  --            beam.beamDeform, deformLimit, type(beam.deformLimitExpansion) == 'number' and beam.deformLimitExpansion or deformLimit,
  --            beamPrecompression
  --)

  --for id,ratio in pairs(data) do
  --  if ratio == 0 then
  --    obj:breakBeam(id)
  --  else
  --    --data
  --    obj:setBeamLengthRefRatio(id, bytesToDouble(ratio))
  --  end
  --end
end

local function onReset()
  table.clear(breakBeamCache)
  table.clear(breakGroupCache)
  table.clear(deformBeamCache)
end

M.get = get
M.set = set
M.onBeamBroke = onBeamBroke
M.onBeamDeformed = onBeamDeformed
M.onExtensionLoaded = onReset
M.onReset = onReset

return M