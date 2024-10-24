
local M = {}
M.dependencies = {"ngmp_main", "ngmp_network", "ngmp_settings"}

local ownedVehicle

local function onVehicleSpawned(vehId, veh)
  ngmp_network.sendPacket("VS", {
    Jbeam = veh.Jbeam,
    partConfig = veh.partConfig,
    paints = veh.paints,
    pos = veh:getPosition(),
    rot = veh:getRefNodeRotation(),
  })
end

local function spawnVehicle(data)
  spawn.spawnVehicle(
    data.Jbeam,
    data.partConfig,
    vec3(data.pos.x,data.pos.y,data.pos.z),
    quat(data.rot.x,data.rot.y,data.rot.z,data.rot.w)
  )
end

M.onVehicleSpawned = onVehicleSpawned
M.spawnVehicle = spawnVehicle

return M