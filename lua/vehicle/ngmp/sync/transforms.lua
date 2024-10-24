
local M = {
  name = "transforms",
  abbreviation = "t",
  author = "DaddelZeit (NGMP Official)"
}

local function doubleToBytes(num)
  if not num then return end
  return ffi.string(ffi.new("double[1]", num), 8)
end

local function doubleTableToBytes(tbl)
  for i=1, #tbl do
    tbl[i] = doubleToBytes(tbl[i])
  end
end

local tmpDouble = ffi.new("double[1]")
local function bytesToDouble(str)
  ffi.copy(tmpDouble, str, 4)
  return tmpDouble[0]
end

local function byteTableToDouble(tbl)
  for i=1, #tbl do
    tbl[i] = bytesToDouble(tbl[i])
  end
end

local function get()
  -- this is the REF NODE TRANSFORM
  local transform = {
    doubleTableToBytes(obj:getPosition():toTable()),
    doubleTableToBytes({obj:getRotation()}),
    doubleTableToBytes(obj:getVelocity():toTable()),
    doubleTableToBytes({
      obj:getRollAngularVelocity(),
      obj:getPitchAngularVelocity(),
      obj:getYawAngularVelocity()
    })
  }

  return transform
end

local received
local current
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
end

local function set(data)
  received = {
    pos = vec3(byteTableToDouble(data[1])),
    rot = vec3(byteTableToDouble(data[1])),
    vel = vec3(byteTableToDouble(data[1])),
    velAng = vec3(byteTableToDouble(data[1]))
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