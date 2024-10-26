
local M = {}
M.dependencies = {"ngmp_main", "ngmp_network", "ngmp_settings"}

M.owners = {}
M.vehsByVehFullId = {}
M.vehsByObjId = {}
M.vehs = {}

local queue = {}
local waitingForConfirm = {}
local dontSendSpawnInfo = {}

local function onVehicleSpawned(vehFullId, veh)
  if dontSendSpawnInfo[veh:getName()] then return end

  if FS:fileExists(veh.partConfig) then
    veh.partConfig = serialize(jsonReadFile(veh.partConfig)) or veh.partConfig
  end
  waitingForConfirm[ngmp_network.sendPacket("VS", {
    Jbeam = veh.Jbeam,
    partConfig = veh.partConfig,
    paints = veh.paints,
    pos = veh:getPosition():toTable(),
    rot = quat(veh:getRotation()):toTable(),
    object_id = vehFullId
  })] = vehFullId
  be:enterVehicle(0, be:getObjectByID(vehFullId))
end

local function setVehicleOwnership(steam_id, veh_id, object_id)
  local owner = M.owners[steam_id] or {}
  local vehFullId = steam_id.."_"..veh_id
  local veh = be:getObjectByID(object_id)
  table.insert(owner, {
    ownerId = steam_id,
    vehName = veh:getName(),
    vehId = veh_id,
    vehFullId = vehFullId,
    vehObjId = object_id,
    veh = veh,
  })

  veh:queueLuaCommand(string.format([[
    extensions.reload("ngmp_sync");
    ngmp_sync.vehFullId = "%s"
  ]], vehFullId))
  M.owners[steam_id] = owner
  M.vehsByVehFullId[vehFullId] = {
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
    local vehFullId = steamId.."_"..veh_id
    local veh = be:getObjectByID(object_id)
    owner[veh_id] = {
      ownerId = steamId,
      vehName = veh:getName(),
      vehFullId = vehFullId,
      vehObjId = object_id,
      veh = veh,
    }

    veh:queueLuaCommand(string.format([[
      extensions.reload("ngmp_sync");
      ngmp_sync.vehFullId = "%s"
    ]], vehFullId))
    M.owners[steamId] = owner
    M.vehsByVehFullId[vehFullId] = {
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

local function setVehicleData(vehFullId, data)
  local veh = M.vehsByVehFullId[vehFullId]
  if veh then
    veh[1]:queueLuaCommand(string.format("ngmp_sync.set(jsonDecode(%q))", data))
  end
end

local function setVehicleTransformData(vehFullId, data)
  local veh = M.vehsByVehFullId[vehFullId]
  if veh then
    veh[1]:queueLuaCommand(string.format("ngmp_sync.set(jsonDecode(%q))", data))
  end
end

local function sendVehicleData(vehFullId, vehData)
  local vehObj = M.vehsByVehFullId[vehFullId]
  if vehObj then
    ngmp_network.sendPacket("VU", vehObj[2], vehData)
  end
end

local function sendVehicleTransformData(vehFullId, vehData)
  local vehObj = M.vehsByVehFullId[vehFullId]
  if vehObj then
    ngmp_network.sendPacket("VT", vehObj[2], vehData)
  end
end

local function spawnVehicle(data)
  if data.steam_id == ngmp_main.steamId then return end
  local vehFullId = data.steam_id.."_"..data.veh_id
  local objName = "NGMP_"..vehFullId

  dontSendSpawnInfo[objName] = true
  local paintData = deserialize(data.paints)
  local veh = spawn.spawnVehicle(
    data.Jbeam,
    data.partConfig,
    vec3(data.pos[1],data.pos[2],data.pos[3]),
    quat(data.rot[1],data.rot[2],data.rot[3],data.rot[4]),
    {
      vehicleName = objName,
      paint = paintData[1],
      paint2 = paintData[2],
      paint3 = paintData[3],
      autoEnterVehicle = false,
    }
  )
  if not veh then return end

  setVehicleOwnership(data.steam_id, data.veh_id, veh:getID())
end

local function removeVehicle(veh_id, steam_id)
  local owner = M.owners[steam_id] or {}
  local vehFullId = steam_id.."_"..veh_id
  local veh = M.vehsByVehFullId[vehFullId]

  veh:delete()

  owner[veh_id] = nil
  M.vehsByVehFullId[vehFullId] = nil
  M.vehsByObjId[veh:getID()] = nil

  M.owners[steam_id] = owner
end

M.sendVehicleTransformData = sendVehicleTransformData
M.sendVehicleData = sendVehicleData
M.setVehicleTransformData = setVehicleTransformData
M.setVehicleData = setVehicleData

M.confirmVehicle = confirmVehicle
M.setVehicleOwnership = setVehicleOwnership

M.removeVehicle = removeVehicle
M.spawnVehicle = spawnVehicle

M.onVehicleSpawned = onVehicleSpawned

return M