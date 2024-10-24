
local M = {}
M.dependencies = {"ngmp_main"}

local MAX_CONFIRM_ID = 65535
local MAX_CONFIRM_ID_ITERATION = 20000

local socket = require("socket")
local wbp = socket.udp() -- water bucket protocol
M.connection = {
  wbp = wbp,
  connected = false,
  timeout = 0,
  ip = "127.0.0.1",
  clientPort = "42636",
  port = "42637",
  serverPort = "42630",
  errType = "",
  err = "",
}

local confirmIdCache = {}
local function generateConfirmID(asString)
  local confirm_id
  local loops = 0
  repeat
    loops = loops + 1
    confirm_id = math.random(0, MAX_CONFIRM_ID)
  until not confirmIdCache[confirm_id] or loops > MAX_CONFIRM_ID_ITERATION

  confirmIdCache[confirm_id] = true
  if asString then
    return ffi.string(ffi.new("uint16_t[1]", {confirm_id}), 2)
  end
  return confirm_id
end

local packetEncode = {
  ["CI"] = function()
    local raw = {
      confirm_id = generateConfirmID(),
      userfolder = FS:getUserPath(), -- uses OS standard
      client_version = ngmp_main.clientVersion,
    }

    return jsonEncode(raw)
  end,
  ["HJ"] = function(ip_address, port)
    ip_address = ip_address == "" and "127.0.0.1" or M.connection.ip
    port = port == "" and "42630" or M.connection.serverPort
    return generateConfirmID(true)..ip_address..":"..port
  end,
  ["MR"] = function(mods)
    return generateConfirmID(true)..mods
  end,
  ["RL"] = function()
    return generateConfirmID(true)
  end,
}

local function fromUINT16(bytes)
  local uint = ffi.new("uint16_t[1]")
  ffi.copy(uint, bytes, 2)
  return uint[0]
end

local packetDecode = {
  ["CC"] = function(data)
    local confirm_id = fromUINT16(data:sub(1,2))
    return confirm_id
  end,
  ["VC"] = function(data)
    local confirm_id = fromUINT16(data:sub(1,2))
    local protocol_version = fromUINT16(data:sub(3,4))

    ngmp_main.setBridgeConnected(protocol_version, true)
    return confirm_id
  end,
  ["AI"] = function(data)
    local success, jsonData = pcall(jsonDecode, data)
    if not success then
      log("E", "", jsonData)
      jsonData = {}
    end

    ngmp_main.setLogin(jsonData.success, jsonData.player_name)
    return jsonData.confirm_id or 0
  end,
  ["MP"] = function(data)
    local success, jsonData = pcall(jsonDecode, data)
    if not success then
      log("E", "", jsonData)
      jsonData = {}
    end

    if jsonData.mod_name then
      ngmp_mods.modDownloads[jsonData.mod_name] = jsonData.progress/100
    end
    return jsonData.confirm_id or 0
  end,
  ["LM"] = function(data)
    local confirm_id = fromUINT16(data:sub(1,2))
    local mapString = data:sub(3)

    ngmp_levelMgr.loadLevel(mapString)
    return confirm_id
  end,
  ["VS"] = function(data)
    local success, jsonData = pcall(jsonDecode, data)
    if not success then
      log("E", "", jsonData)
      jsonData = {}
    end

    if jsonData.Jbeam then
      ngmp_vehicleMgr.spawnVehicle(jsonData)
    end
    return jsonData.confirm_id or 0
  end,
}

local function sendPacket(packetType, ...)
  if not M.connection.connected then return end

  local args = {...}
  local data
  if args[1] and type(args[1]) == "table" then
    args[1].confirm_id = generateConfirmID()
    data = jsonEncode(args[1]) or ""
  elseif packetEncode[packetType] then
    data = packetEncode[packetType](...)
  else
    data = tostring(generateConfirmID(true))
  end

  local len = ffi.string(ffi.new("uint32_t[1]", {#data}), 4)
  wbp:send(packetType..len..data)

  return true
end

local function startConnection()
  if M.connection.connected then return end

  wbp:settimeout(M.connection.timeout)

  do
    local result, error = wbp:setsockname(M.connection.ip, M.connection.clientPort)
    if error then
      M.connection.errType = "Client socket init failed!"
      M.connection.err = error
      log("E", "startConnection", M.connection.errType)
      log("E", "startConnection", error)
      return false
    end
  end

  do
    local result, error = wbp:setpeername(M.connection.ip, M.connection.port)
    if result then
      M.connection.connected = true
    elseif result then
      M.connection.errType = "Launcher peer init failed!"
      M.connection.err = error
      log("E", "startConnection", M.connection.errType)
      log("E", "startConnection", error)
      return false
    end
  end

  sendPacket("CI")
end

local function onReceive(data)
  local packetType = data:sub(1, 2)

  if packetType ~= "" and packetDecode[packetType] then
    local packetLength = 0
    local packetLengthRaw = data:sub(3, 6)
    do
      -- convert to actual num
      -- this was for sure an experience
      local _packetLength = ffi.new("uint32_t[1]")
      ffi.copy(_packetLength, packetLengthRaw, 4)
      packetLength = _packetLength[0]
    end

    local rawData = data:sub(7)
    if rawData:len() == packetLength then
      local confirmId = packetDecode[packetType](rawData)
      confirmIdCache[confirmId] = true
    end
  end
end

local function onUpdate(dt)
  if not M.connection.connected then return end

  local buf = wbp:receive()
  if buf and buf ~= "" then
    onReceive(buf)
  end
end

local function onExtensionLoaded()
  setExtensionUnloadMode(M, "manual")
end

local function onExtensionUnloaded()
  if not M.connection.connected then return end
  wbp:close()
end

M.onUpdate = onUpdate
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

-- output
M.onNGMPInit = startConnection
M.sendPacket = sendPacket

return M