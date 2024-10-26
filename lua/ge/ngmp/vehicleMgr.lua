
local M = {}
M.dependencies = {"ngmp_main", "ngmp_network", "ngmp_settings"}

M.owners = {}
M.vehsByVehId = {}
M.vehsByObjId = {}
M.vehs = {}

local queue = {}
local waitingForConfirm = {}

local function onVehicleSpawned(vehId, veh)
  if veh:getField("NGMP_SPAWN", 0) ~= "" then return end

  if FS:fileExists(veh.partConfig) then
    veh.partConfig = serialize(jsonReadFile(veh.partConfig)) or veh.partConfig
  end

  waitingForConfirm[ngmp_network.sendPacket("VS", {
    Jbeam = veh.Jbeam,
    partConfig = veh.partConfig,
    paints = veh.paints,
    pos = veh:getPosition():toTable(),
    rot = quat(veh:getRotation()):inversed():toTable(),
    object_id = vehId
  })] = vehId
end

local function setVehicleOwnership(steam_id, veh_id, object_id)
  local owner = M.owners[steam_id] or {}
  local vehId = steam_id.."_"..veh_id
  local veh = be:getObjectByID(object_id)
  table.insert(owner, {
    ownerId = steam_id,
    vehName = veh:getName(),
    vehId = vehId,
    vehObjId = object_id,
    veh = veh,
  })

  veh:queueLuaCommand(string.format([[
    extensions.reload("ngmp_sync");
    ngmp_sync.vehId = "%s"
  ]], vehId))
  M.owners[steam_id] = owner
  M.vehsByVehId[vehId] = {
    veh,
    owner
  }
  M.vehsByObjId[object_id] = {
    veh,
    owner
  }
end

local function confirmVehicle(confirm_id, veh_id, object_id)
  if waitingForConfirm[confirm_id] == object_id then
    local steamId = ngmp_main.steamId
    local owner = M.owners[steamId] or {}
    local vehId = steamId.."_"..veh_id
    local veh = be:getObjectByID(object_id)
    owner[veh_id] = {
      ownerId = steamId,
      vehName = veh:getName(),
      vehId = vehId,
      vehObjId = object_id,
      veh = veh,
    }

    veh:queueLuaCommand(string.format([[
      extensions.reload("ngmp_sync");
      ngmp_sync.vehId = "%s"
    ]], vehId))
    M.owners[steamId] = owner
    M.vehsByVehId[vehId] = {
      veh,
      owner
    }
    M.vehsByObjId[object_id] = {
      veh,
      owner
    }

    waitingForConfirm[confirm_id] = nil
  end
end

local function setVehicleData(data)
  local veh = M.vehsByVehId[data.steam_id.."_"..data.veh_id]
  if veh then
    veh[1]:queueLuaCommand(string.format("ngmp_sync.set(jsonDecode(%q))", data))
  end
end

local function sendVehicleData(vehData)
  local vehObj = M.vehsByVehId[vehData.vehId]
  if vehObj then
    ngmp_network.sendPacket("VU", vehData)
  end
end

local function spawnVehicle(data)
  if data.steam_id == ngmp_main.steamId then return end
  local vehId = data.steam_id.."_"..data.veh_id
  local objName = "NGMP_"..vehId

  local veh = spawn.spawnVehicle(
    data.Jbeam,
    data.partConfig,
    vec3(data.pos[1],data.pos[2],data.pos[3]),
    quat(data.rot[1],data.rot[2],data.rot[3],data.rot[4]),
    {vehName = objName}
  )
  if not veh then return end

  veh:setField("NGMP_SPAWN", 0, "1")
  setVehicleOwnership(data.steam_id, data.veh_id, veh:getID())
end

local function removeVehicle(veh_id, steam_id)
  local owner = M.owners[steam_id] or {}
  local vehId = steam_id.."_"..veh_id
  local veh = M.vehsByVehId[vehId]

  veh:delete()

  owner[veh_id] = nil
  M.vehsByVehId[vehId] = nil
  M.vehsByObjId[veh:getID()] = nil

  M.owners[steam_id] = owner
end

M.sendVehicleData = sendVehicleData
M.setVehicleData = setVehicleData

M.confirmVehicle = confirmVehicle
M.setVehicleOwnership = setVehicleOwnership

M.removeVehicle = removeVehicle
M.spawnVehicle = spawnVehicle

M.onVehicleSpawned = onVehicleSpawned

return M