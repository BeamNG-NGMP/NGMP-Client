
local M = {}
M.dependencies = {"ngmp_main", "ngmp_network", "ngmp_settings"}

M.owners = {}

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
  local owner = M.owners[data.steam_id] or {}
  local objName = "NGMP_Veh"..data.steam_id.."_"..(#owner+1)

  local veh = spawn.spawnVehicle(
    data.Jbeam,
    data.partConfig,
    vec3(data.pos.x,data.pos.y,data.pos.z),
    quat(data.rot.x,data.rot.y,data.rot.z,data.rot.w),
    {vehName = objName}
  )
  if not veh then return end

  table.insert(owner, {
    vehName = objName,
    vehId = veh:getID(),
    veh = veh
  })

  M.owners[data.SteamID] = owner
end

M.onVehicleSpawned = onVehicleSpawned
M.spawnVehicle = spawnVehicle

return M