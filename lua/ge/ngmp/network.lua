
local M = {}
M.dependencies = {"ngmp_main"}
M.debugPrintIn = false
M.debugPrintOut = false

local ngmpUtils = rerequire("ngmp/utils")

local http = require("socket/http")
http.TIMEOUT = 0.1
local MAX_CONFIRM_ID = 65535
local MAX_CONFIRM_ID_ITERATION = 20000

local socket = rerequire("ngmp/netWrapper/tcp")
M.connection = {
  connected = false,
  timeout = 0,
  ip = "127.0.0.1",
  clientPort = "42636",
  port = "42637",
  serverPort = "42630",
  errType = "",
  err = "",
}
socket.init(M.connection)

local confirmIdCache = {}
local function generateConfirmID()
  local confirm_id
  local loops = 0
  repeat
    loops = loops + 1
    confirm_id = math.random(0, MAX_CONFIRM_ID)
  until not confirmIdCache[confirm_id] or loops > MAX_CONFIRM_ID_ITERATION

  confirmIdCache[confirm_id] = true
  return confirm_id
end

-- use registerPacketEncodeFunc to add one
-- usage:
-- ngmp_network.sendPacket("ID", {data = {"arg1", "arg2"}})
-- or (does not need function register):
-- ngmp_network.sendPacket("ID", {custom = true, data = {"arg1", "arg2"}})
local packetEncode = {
  ["CC"] = function(customConfirmId)
    customConfirmId = customConfirmId or generateConfirmID()
    return {confirm_id = customConfirmId}, customConfirmId
  end,
}

-- use registerPacketDecodeFunc to add one
-- confirm id return is optional
local packetDecode = {
  ["CC"] = function(data)
    return data.confirm_id
  end,
}

local function onReceive(packetType, data)
  if M.debugPrintIn then
    log("D", "ngmp.network.onReceive", string.format("Packet Received! Type: %s", packetType))
  end

  if not packetDecode[packetType] then
    -- don't know what to do? just forget about it. your problems are not there if you ignore them.
    log("E", "ngmp.network.onReceive", string.format("Received packet of type %s is either unknown or not registered.", packetType))
    return
  end

  local packetLengthRaw = socket.receive(4)
  local packetLength = ngmpUtils.ffiConvertNumber(packetLengthRaw, 4)

  local rawData = socket.receive(packetLength)
  if rawData:len() == packetLength then
    -- non-json packets are not supported
    local success, jsonData = pcall(jsonDecode, rawData)
    if not success then
      log("E", "ngmp.network.onReceive", "Error during jsonDecode:")
      log("E", "ngmp.network.onReceive", jsonData)
      return
    end

    local confirmId = packetDecode[packetType](jsonData)
    if confirmId then
      confirmIdCache[confirmId] = true
    end
  else
    log("E", "ngmp.network.onReceive", string.format("Received packet of type %s does not match length! Expected: %d bytes, received: %d bytes.", packetType, packetLength, rawData:len()))
  end
end

local function sendPacket(packetType, context)
  if not M.connection.connected then return end
  context = context or {}

  local data, confirmId
  if context.custom then
    data = jsonEncode(context.data) or ""
  else
    if packetEncode[packetType] then
      -- this ends up with the arguments in the input array split into actual arguments for the function
      data, confirmId = packetEncode[packetType](unpack(context.data or {}))
      data = jsonEncode(data) -- non-json packets are not supported
    else
      -- Whoops, doesn't exists lol
      log("E", "ngmp.network.sendPacket", string.format("Packet of type %s was not declared as custom and an encode function does not exist.", packetType))
      return
    end
  end

  if M.debugPrintOut then
    log("D", "ngmp.network.sendPacket", string.format("Packet to send! Type: %s", packetType))
    log("D", "ngmp.network.sendPacket", string.format("Data: %s", data))
  end

  local err = socket.send(packetType, data)
  if err then
    log("D", "ngmp.network.sendPacket", string.format("Packet of type %s failed to send!", packetType))
    log("D", "ngmp.network.sendPacket", string.format("Error: %s", err))
  end

  return confirmId
end

local function startConnection()
  if socket.connect(M.connection) then
    sendPacket("CI")
  else
    log("W", "ngmp.network.startConnection", "Connection failed! See above for error.")
  end
end

local function retryConnection()
  log("D", "ngmp.network.retryConnection", "Attempting connection retry.")
  sendPacket("RL")
  startConnection()
end

local function onUpdate(dt)
  if not M.connection.connected then return end

  local packetType
  repeat
    packetType = socket.receive(2)
    if packetType then
      onReceive(packetType)
    end
  until not packetType
end

local function httpGet(url)
  log("D", "ngmp.network.httpGet", string.format("Sending HTTP GET request to %s", url))
  return http.request("http://127.0.0.1:4434/external/"..url)
end

local function registerPacketDecodeFunc(packetType, func)
  packetDecode[packetType] = func
end

local function registerPacketEncodeFunc(packetType, func)
  packetEncode[packetType] = func
end

local function onExtensionLoaded()
  setExtensionUnloadMode(M, "manual")
end

local function onExtensionUnloaded()
  socket.disconnect()
end

M.onUpdate = onUpdate
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

-- output
M.retryConnection = retryConnection
M.onNGMPInit = startConnection
M.sendPacket = sendPacket

M.httpGet = httpGet

M.generateConfirmID = generateConfirmID
M.registerPacketDecodeFunc = registerPacketDecodeFunc
M.registerPacketEncodeFunc = registerPacketEncodeFunc

return M
