
local M = {}
M.dependencies = {"ngmp_main", "ngmp_network", "ngmp_settings"}

M.owners = {}
M.vehsByVehId = {}
M.vehsByObjId = {}
M.vehs = {}

local function onVehicleSpawned(vehId, veh)
  ngmp_network.sendPacket("VS", {
    Jbeam = veh.Jbeam,
    partConfig = veh.partConfig,
    paints = veh.paints,
    pos = veh:getPosition(),
    rot = veh:getRefNodeRotation(),
  })
end

local function setVehicleData(data)
  if M.vehsByVehId[data.veh_id][1] then
    M.vehsByVehId[data.veh_id][1]:queueLuaCommand("ngmp_sync.set(lpack.decode('"..lpack.encode(data).."'))")
  end
end

local function sendVehicleData(objectId, vehData)
  if M.vehsByObjId[objectId] then
    ngmp_network.sendPacket("VU", vehData)
  end
end

local function spawnVehicle(data)
  local owner = M.owners[data.steam_id] or {}
  local objName = "NGMP_Veh_"..data.veh_id

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
    veh = veh,
    ownerId = data.SteamID
  })

  veh:queueLuaCommand("extensions.reload('ngmp_sync')")
  M.owners[data.SteamID] = owner
  M.vehsByVehId[data.veh_id] = {
    veh,
    owner
  }
  M.vehsByObjId[veh:getID()] = {
    veh,
    owner
  }
end

M.sendVehicleData = sendVehicleData

M.setVehicleData = setVehicleData
M.onVehicleSpawned = onVehicleSpawned
M.spawnVehicle = spawnVehicle

return M