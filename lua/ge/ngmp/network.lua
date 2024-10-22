
local M = {}
M.dependencies = {"ngmp_main"}

local MAX_CONFIRM_ID = 65535
local MAX_CONFIRM_ID_ITERATION = 20000

local socket = require("socket")
local wbp = socket.udp() -- water bucket protocol
M.connection = {
  wbp = wbp,
  connected = false,
  timeout = 0.01,
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
  ["LM"] = function(map_string)
    return generateConfirmID(true)..map_string
  end,
  ["HJ"] = function(ip_address)
    return generateConfirmID(true)..ip_address
  end,
  ["ML"] = function(mods)
    return generateConfirmID(true)..mods
  end,
}

local packetDecode = {
  ["CC"] = function(packetLength)
    local _confirm_id = ffi.new("uint16_t[1]")
    ffi.copy(_confirm_id, ffi.new("uint8_t[2]", wbp:receive(2)), 2)
    local confirm_id = _confirm_id[0]

    return confirm_id
  end,
  ["VC"] = function(packetLength)
    local _confirm_id = ffi.new("uint16_t[1]")
    ffi.copy(_confirm_id, ffi.new("uint8_t[2]", wbp:receive(2)), 2)
    local confirm_id = _confirm_id[0]

    local _protocol_version = ffi.new("uint16_t[1]")
    ffi.copy(_protocol_version, ffi.new("uint8_t[2]", wbp:receive(2)), 2)
    local protocol_version = _protocol_version[0]

    ngmp_main.setBridgeConnected(true, protocol_version)
    return confirm_id, protocol_version
  end,
  ["AI"] = function(packetLength)
    local raw = wbp:receive(packetLength)
    local success, data = pcall(jsonDecode, raw)
    if not success then
      log("E", "", data)
      data = {}
    end

    ngmp_main.setLogin(data.success, data.player_name)
    return data.confirm_id or 0, data
  end,
  ["MP"] = function(packetLength)
    local raw = wbp:receive(packetLength)
    local success, data = pcall(jsonDecode, raw)
    if not success then
      log("E", "", data)
      data = {}
    end

    if data.mod_name then
      ngmp_mods.modDownloads[data.mod_name] = data.progress/100
    end
    return data.confirm_id or 0, data
  end,
  ["ML"] = function(packetLength)
    local _confirm_id = ffi.new("uint16_t[1]")
    ffi.copy(_confirm_id, ffi.new("uint8_t[2]", wbp:receive(2)), 2)
    local confirm_id = _confirm_id[0]

    local raw = wbp:receive(packetLength-2)
    local modsHashes = split(raw, "/")
    local mods = {}
    for i=1, #modsHashes do
      mods[i] = split(modsHashes, ":")
    end
    if data.mod_name then
      ngmp_mods.verifyInstalledMods(mods)
    end
    return confirm_id
  end,
}

local function sendPacket(packetType, ...)
  local args = {...}
  local data
  if args[1] and type(args[1]) == "table" then
    args[1].confirm_id = generateConfirmID()
    data = jsonEncode(args[1]) or ""
  elseif packetEncode[packetType] then
    data = packetEncode[packetType](...)
  else
    return false
  end

  local len = ffi.string(ffi.new("uint32_t[1]", {#data}), 4)
  wbp:send(len..packetType..data)
  return true
end

local function startConnection()
  wbp:settimeout(M.connection.timeout)

  wbp:setsockname("127.0.0.1", "42636")
  wbp:setpeername("127.0.0.1", "42637")
end

local function onUpdate(dt)
  local packetLength = 0
  local packetLengthRaw = wbp:receive(4)

  if packetLengthRaw then
    do
      -- convert to actual num
      -- this was for sure an experience
      local _packetLength = ffi.new("uint32_t[1]")
      ffi.copy(_packetLength, ffi.new("uint8_t[4]", packetLengthRaw), 4)
      packetLength = _packetLength[0]
    end

    local packetType = wbp:receive(2)
    if packetDecode[packetType] then
      local confirmId = packetDecode[packetType](packetLength)
      confirmIdCache[confirmId] = true
    else
      -- clear
      wbp:receive(packetLength)
    end
  end
end

local function onExtensionLoaded()
  setExtensionUnloadMode(M, "manual")
end

M.onUpdate = onUpdate
M.onExtensionLoaded = onExtensionLoaded

-- output
M.onNGMPInit = startConnection
M.sendPacket = sendPacket

return M