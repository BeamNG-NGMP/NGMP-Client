
local M = {
  name = "transforms",
  abbreviation = "t",
  author = "DaddelZeit (NGMP Official)"
}

local step = 0
local stepSize = 1/50

local received
local current
local function get()
  -- this is the REF NODE TRANSFORM
  local transform = {
    obj:getPosition():toTable(),
    {obj:getRotation()},
    obj:getVelocity():toTable(),
    {
      obj:getRollAngularVelocity(),
      obj:getPitchAngularVelocity(),
      obj:getYawAngularVelocity()
    }
  }

  return transform
end

local function onPhysicsStep(dtPhys)
  current = {
    pos = obj:getPosition(),
    rot = quat(obj:getRotation()),
    vel = obj:getVelocity(),
    velAng = vec3(
      obj:getRollAngularVelocity(),
      obj:getPitchAngularVelocity(),
      obj:getYawAngularVelocity()
    )
  }

  -- fortune telling is supposed to be done in launcher

  -- TODO: APPLY


  step = step + dtPhys
  if step > stepSize then
    step = 0
    current.vehId = ngmp_sync.vehId
    obj:queueGameEngineLua(string.format("ngmp_vehicleMgr.sendVehicleData(%q, %q)", ngmp_sync.vehId, jsonEncode(get())))
  end
end

local function set(data)
  received = {
    pos = vec3(data[1]),
    rot = quat(data[2]),
    vel = vec3(data[3]),
    velAng = vec3(data[4])
  }
end

local function onReset()
end

M.onPhysicsStep = onPhysicsStep
M.get = get
M.set = set

M.onExtensionLoaded = onReset
M.onReset = onReset

return M