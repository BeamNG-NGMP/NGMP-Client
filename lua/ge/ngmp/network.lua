
local M = {}
M.dependencies = {"ngmp_main"}

local ngmpUtils = rerequire("ngmp/utils")
local http = require("socket/http")
http.TIMEOUT = 0.1
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
local packetEncode = {}

local function fromUINT16(bytes)
  local uint = ffi.new("uint16_t[1]")
  ffi.copy(uint, bytes, 2)
  return uint[0]
end

--[[
only the generics are here
use registerPacketDecodeFunc to add one

- confirm id return is optional
]]
local packetDecode = {
  ["CC"] = function(data)
    return data.confirm_id
  end,
}

local function onReceive(data)
  local packetType = data:sub(1, 2)

  if packetType == "" then return end
  if not packetDecode[packetType] then
    -- don't know what to do? just forget about it. your problems are not there if you ignore them.
    log("E", "onReceive", string.format("Received packet of type %s is either unknown or not registered.", packetType))
    return
  end

  local packetLengthRaw = data:sub(3, 6)
  local packetLength = ngmpUtils.ffiConvertNumber(packetLengthRaw, 4)

  local rawData = data:sub(7)
  if rawData:len() == packetLength then
    -- non-json packets are not supported
    local success, jsonData = pcall(jsonDecode, rawData)
    if not success then
      log("E", "onReceive", "Error during jsonDecode:")
      log("E", "onReceive", jsonData)
      return
    end

    local confirmId = packetDecode[packetType]()
    if confirmId then
      confirmIdCache[confirmId] = true
    end
  else
    log("E", "onReceive", string.format("Received packet of type %s does not match length! Expected: %d bytes, received: %d bytes.", packetType, packetLength, rawData:len()))
  end
end

local function sendPacket(packetType, context)
  if not M.connection.connected then return end

  local data
  local confirmId
  if context and context.custom then
    data = jsonEncode(context.data) or ""
  else
    if packetEncode[packetType] then
      data, confirmId = packetEncode[packetType](context and unpack(context.data))
      data = jsonEncode(data) -- non-json packets are not supported
    else
      -- Whoops, doesn't exists lol
      log("E", "sendPacket", string.format("Packet of type %s was not declared as custom and an encode function does not exist.", packetType))
      return
    end
  end

  local len = ffi.string(ffi.new("uint32_t[1]", {#data}), 4)
  wbp:send(packetType..len..data)

  return confirmId
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

local function retryConnection()
  sendPacket("RL")
  startConnection()
  sendPacket("CI")
end

local function onUpdate(dt)
  if not M.connection.connected then return end

  local buf = wbp:receive()
  if buf and buf ~= "" then
    onReceive(buf)
  end
end

local function httpGet(url)
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
  if not M.connection.connected then return end
  wbp:close()
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