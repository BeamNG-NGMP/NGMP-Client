
local M = {}
M.dependencies = {"ngmp_main", "ngmp_network", "ngmp_settings"}

M.owners = {}
M.vehsByVehFullId = {}
M.vehsByObjId = {}
M.vehs = {}

local queue = {}
local waitingForConfirm = {}
local dontSendSpawnInfo = {}

local function setVehicleOwnership(steam_id, vehicle_id, object_id)
  local owner = M.owners[steam_id] or {}
  local vehFullId = steam_id.."_"..vehicle_id
  local veh = be:getObjectByID(object_id)
  table.insert(owner, {
    steamId = steam_id,
    vehName = veh:getName(),
    vehId = vehicle_id,
    vehFullId = vehFullId,
    vehObjId = object_id,
    veh = veh,
  })

  veh:queueLuaCommand(string.format([[
    extensions.reload("ngmp_sync");
    ngmp_sync.vehFullId = "%s";
    ngmp_sync.mode = "receive";
  ]], vehFullId))
  M.owners[steam_id] = owner
  M.vehsByVehFullId[vehFullId] = {
    veh,
    owner[object_id]
  }
  M.vehsByObjId[object_id] = {
    veh,
    owner[object_id]
  }
end

local function confirmVehicle(data)
  local confirmId = data.confirm_id
  local vehId = data.vehicle_id
  local objectId = data.object_id

  if waitingForConfirm[confirmId] == objectId then
    local steamId = ngmp_playerData.steamId
    local owner = M.owners[steamId] or {}
    local vehFullId = steamId.."_"..vehId
    local veh = be:getObjectByID(objectId)
    owner[vehId] = {
      steamId = steamId,
      vehName = veh:getName(),
      vehFullId = vehFullId,
      vehObjId = objectId,
      vehId = vehId,
      veh = veh,
    }

    veh:queueLuaCommand(string.format([[
      extensions.reload("ngmp_sync");
      ngmp_sync.vehFullId = "%s"
      ngmp_sync.mode = "send";
    ]], vehFullId))
    M.owners[steamId] = owner
    M.vehsByVehFullId[vehFullId] = {
      veh,
      owner[vehId]
    }
    M.vehsByObjId[objectId] = {
      veh,
      owner[vehId]
    }

    waitingForConfirm[confirmId] = nil
  end
end

local function onVehicleSpawned(objectId, veh)
  if dontSendSpawnInfo[veh:getName()] then
    local thisVeh = M.vehsByObjId[objectId]
    if thisVeh then
      setVehicleOwnership(thisVeh[2].steamId, thisVeh[2].vehId, thisVeh[2].vehObjId)
    end
    return
  end

  if FS:fileExists(veh.partConfig) then
    veh.partConfig = serialize(jsonReadFile(veh.partConfig)) or veh.partConfig
  end
  waitingForConfirm[ngmp_network.sendPacket("VS", {data = {{
    Jbeam = veh.Jbeam,
    partConfig = veh.partConfig,
    paints = veh.paints,
    pos = veh:getPosition():toTable(),
    rot = quatFromDir(veh:getDirectionVector(), veh:getDirectionVectorUp()):toTable(),
    object_id = objectId
  }}})] = objectId
  be:enterVehicle(0, veh)
end

local function spawnVehicle(data)
  if data.steam_id == ngmp_playerData.steamId then return end
  local vehFullId = data.steam_id.."_"..data.vehicle_id
  local objName = "NGMP_"..vehFullId

  dontSendSpawnInfo[objName] = true
  local vehData = data.vehicle_data
  local paintData = deserialize(vehData.paints)
  local veh = spawn.spawnVehicle(
    vehData.Jbeam,
    vehData.partConfig,
    vec3(vehData.pos[1],vehData.pos[2],vehData.pos[3]),
    quat(vehData.rot[1],vehData.rot[2],vehData.rot[3],vehData.rot[4]),
    {
      vehicleName = objName,
      paint = paintData[1],
      paint2 = paintData[2],
      paint3 = paintData[3],
      autoEnterVehicle = false,
    }
  )
  if not veh then return end

  setVehicleOwnership(data.steam_id, data.vehicle_id, veh:getID())
end

local function removeVehicle(data)
  local vehId = data.vehicle_id
  local steamId = data.steam_id
  local owner = M.owners[steamId] or {}
  local vehFullId = steamId.."_"..vehId
  local veh = M.vehsByVehFullId[vehFullId]

  veh:delete()

  owner[vehId] = nil
  M.vehsByVehFullId[vehFullId] = nil
  M.vehsByObjId[veh:getID()] = nil

  M.owners[steamId] = owner
end

local function setVehicleData(vehFullId, data)
  local vehObj = M.vehsByVehFullId[vehFullId]
  if vehObj then
    vehObj[1]:queueLuaCommand(string.format("ngmp_sync.set(jsonDecode(%q))", data))
  end
end

local function setVehicleTransformData(vehFullId, data)
  local vehObj = M.vehsByVehFullId[vehFullId]
  if vehObj then
    vehObj[1]:queueLuaCommand(string.format("ngmp_transformSync.set(jsonDecode(%q))", data))
  end
end

local function sendVehicleData(vehFullId, vehData)
  local vehObj = M.vehsByVehFullId[vehFullId]
  if vehObj and vehObj[2].steamId == ngmp_playerData.steamId then
    ngmp_network.sendPacket("VU", {data = {vehObj[2], vehData}})
  end
end

local function sendVehicleTransformData(vehFullId, vehData)
  local vehObj = M.vehsByVehFullId[vehFullId]
  if vehObj and vehObj[2].steamId == ngmp_playerData.steamId then
    ngmp_network.sendPacket("VT", {data = {vehObj[2], vehData}})
  end
end

local function onNGMPInit()
  ngmp_network.registerPacketEncodeFunc("VS", function(data)
    local confirm_id = ngmp_network.generateConfirmID()
    return {
      confirm_id = confirm_id,
      steam_id = ngmp_playerData.steamId,
      vehicle_id = 0,
      vehicle_data = data,
    }, confirm_id
  end)
  ngmp_network.registerPacketEncodeFunc("VU", function(ownerData, vehicleData)
    return {
      steam_id = ownerData.steamId,
      transform = vehicleData,
      vehicle_id = ownerData.vehId,
    }
  end)
  ngmp_network.registerPacketEncodeFunc("VT", function(ownerData, vehicleData)
    return {
      steam_id = ownerData.steamId,
      transform = vehicleData,
      vehicle_id = ownerData.vehId,
    }
  end)
  ngmp_network.registerPacketEncodeFunc("VD", function(ownerData, licenseText, paints)
    return {
      steam_id = ownerData.steamId,
      display_data = {
        license_text = licenseText,
        paints = paints
      },
      vehicle_id = ownerData.vehId,
    }
  end)

  ngmp_network.registerPacketDecodeFunc("VS", spawnVehicle)
  ngmp_network.registerPacketDecodeFunc("VA", confirmVehicle)
  ngmp_network.registerPacketDecodeFunc("VR", confirmVehicle)
  ngmp_network.registerPacketDecodeFunc("VU", function(data)
    setVehicleData(data.steam_id.."_"..data.vehicle_id, data.runtime_data)
  end)
  ngmp_network.registerPacketDecodeFunc("VT", function(data)
    setVehicleTransformData(data.steam_id.."_"..data.vehicle_id, data.transform)
  end)
end

M.onNGMPInit = onNGMPInit

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
