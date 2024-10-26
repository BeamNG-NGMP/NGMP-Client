
local M = {
  name = "transforms",
  abbreviation = "t",
  author = "DaddelZeit (NGMP Official)"
}

M.debugDraw = true

M.applyForce = 10
M.applyForceAng = 37.5
M.timeFac = 6
local maxForce = 15
local maxForceSqr = maxForce*maxForce

local step = 0
local stepSize = 1/50

local refNodeID = 0
local applyForceNodes = {}

local received
local current
local function get()
  -- this is the REF NODE TRANSFORM
  local linearVel, angularVel = obj:getClusterVelocityAngVelWithoutWheels(refNodeID)
  local transform = {
    pos = obj:getPosition():toTable(),
    rot = {obj:getRotation()},
    vel = linearVel:toTable(),
    velAng = angularVel:toTable()
  }

  return transform
end

local function forceSet(localVelDiff)
  -- this is kinda really fucking ugly
  -- but it does work, and it works surprisingly well
  local cmd = string.format([[
    local veh = be:getObjectByID(%d);
    local refNodeId = %d;
    local rot = quat(veh:getClusterRotationSlow(refNodeId));
    rot = rot:inversed() * quat(%s);
    veh:setClusterPosRelRot(refNodeId, %s, rot.x, rot.y, rot.z, rot.w);
    veh:applyClusterVelocityScaleAdd(refNodeId, 0.5, %s)
  ]], objectId, refNodeID,
  table.concat(received.rot:toTable(), ","),
  table.concat(received.pos:toTable(), ","),
  table.concat(localVelDiff:toTable(), ","))

  obj:queueGameEngineLua(cmd)
end

-- genuinely everything has to be taken *dt, otherwise we get fucked by the physics
local function calculateVelocities(dt)
  local velDiff = received.vel-current.vel
  --local posDiff = received.pos-current.pos

  local linearMove = (velDiff * M.applyForce) * dt * M.timeFac
  if linearMove:squaredLength() > maxForceSqr then
    linearMove = linearMove:normalized() * maxForce
  end

  -- this needs to be global to apply forces
  local angularDiff = (received.velAng - current.velAng) * M.applyForceAng * dt * M.timeFac

  return linearMove, -angularDiff
end

local function drawDebug()
  if received then
    obj.debugDrawProxy:drawSphere(1, received.pos, color(255,0,255,255))
  end

  if target then
    obj.debugDrawProxy:drawSphere(1, target.pos, color(0,255,0,255))
  end

  if current then
    obj.debugDrawProxy:drawSphere(1, current.pos, color(0,0,255,255))
  end
end

local function updateGFX(dt)
  if not received then return end
  if M.debugDraw then
    drawDebug()
    return
  end

  local linearVel, angularVel = obj:getClusterVelocityAngVelWithoutWheels(refNodeID)
  current = {
    pos = obj:getPosition(),
    rot = quat(obj:getRotation()),
    vel = linearVel,
    velAng = angularVel
  }

  -- fortune telling is done in launcher

  local localVelDiff = received.vel-current.vel
  if current.pos:squaredDistance(received.pos) > 48 then
    forceSet(localVelDiff*0.75)
  else
    local linear, angular = calculateVelocities(dt)

    obj:applyClusterLinearAngularAccel(refNodeID, linear*20, angular*1.25)
  end
end

local function onPhysicsStep(dtPhys)
  local linearVel, angularVel = obj:getClusterVelocityAngVelWithoutWheels(refNodeID)
  current = {
    pos = obj:getPosition(),
    rot = quat(obj:getRotation()),
    vel = linearVel,
    velAng = angularVel
  }

  step = step + dtPhys
  if step > stepSize then
    step = 0
    obj:queueGameEngineLua(string.format("if ngmp_vehicleMgr then ngmp_vehicleMgr.sendVehicleTransformData(%q, %q) end", ngmp_sync.vehFullId, jsonEncode(get())))
  end
end

local function set(data)
  received = {
    pos = vec3(data.pos)+vec3(0,0,0.03),
    rot = quat(data.rot),
    vel = vec3(data.vel),
    velAng = vec3(data.velAng)
  }
end

local function onReset()
  local forceCoef = obj:getPhysicsFPS()

  local rawRef = v.data.refNodes[0]
  local refNodes = {
    rawRef.ref,
    rawRef.left,
    rawRef.back,
    rawRef.up
  }
  refNodeID = rawRef.ref
  local partOrigin = rawRef.partOrigin

  for k,v in pairs(v.data.nodes) do
    if v.partOrigin == partOrigin then
      applyForceNodes[#applyForceNodes + 1] = {
        cid = v.cid,
        weight = obj:getNodeMass(v.cid)*forceCoef,
      }
    end
  end
end

M.forceSet = forceSet
M.updateGFX = updateGFX
M.onPhysicsStep = onPhysicsStep
M.get = get
M.set = set

M.onExtensionLoaded = onReset
M.onReset = onReset

return M