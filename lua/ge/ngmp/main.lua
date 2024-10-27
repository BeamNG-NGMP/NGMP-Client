
-- extension that loads all files and does the main state management
local M = {}

M.toml = require("ngmp/tomlFile")
M.savePath = "/"
M.clientVersion = 0
M.protocolVersion = 0

local toml = M.toml
do -- meta stuff
  local configData = toml.readFile("/ngmp/config.toml") or {}

  M.clientVersion = configData.client_version or M.clientVersion
  M.savePath = configData.save_path or M.savePath
end

local firstUpdate = false

M.isBridgeConnected = false
M.isLoggedIn = false

M.extensionLoadList = {
  -- network first
  "ngmp_network",

  -- then the helper stuff...
  "ngmp_settings",
  "ngmp_mods",
  "ngmp_playerData",
  "ngmp_serverList",

  "ngmp_levelMgr",
  "ngmp_vehicleMgr",

  -- ui goes last
  "ngmp_ui",
  "ngmp_ui_sidebar",
}

local function setLogin(data)
  M.isLoggedIn = data.success or false
  extensions.hook("onNGMPLogin",
    M.isLoggedIn,
    data.player_name or "",
    data.steam_id or "",
    data.avatar_hash or ""
  )
end

local function setBridgeConnected(data)
  M.isBridgeConnected = data.bridgeConnected or true
  M.protocolVersion = data.protocolVersion or M.protocolVersion
  extensions.hook("onNGMPLauncherConnect", M.isBridgeConnected)
end

local function disconnect(err)
  if err then
    -- connection fail!
  else
    -- connection ended
  end
end

local function kicked(reason)
  disconnect()
end

local function onUpdate()
  if firstUpdate then return end
  firstUpdate = true

  for i=1, #M.extensionLoadList do
    extensions.load(M.extensionLoadList[i])
  end
  ngmp_network.registerPacketDecodeFunc("VC", setBridgeConnected) -- Version packet
  ngmp_network.registerPacketDecodeFunc("AI", setLogin) -- AuthenticationInfo packet
  ngmp_network.registerPacketEncodeFunc("LR", nop) -- LoginRequest packet
  ngmp_network.registerPacketEncodeFunc("RL", nop) -- ReloadLauncher packet

  ngmp_network.registerPacketDecodeFunc("HX", disconnect) -- ExitServer packet
  ngmp_network.registerPacketDecodeFunc("CE", disconnect) -- ConnectionError packet
  ngmp_network.registerPacketDecodeFunc("PK", kicked)

  ngmp_network.registerPacketEncodeFunc("CI", function() -- ClientInfo packet
    return {
      userfolder = FS:getUserPath(), -- uses OS standard
      client_version = ngmp_main.clientVersion,
    }
  end)
  ngmp_network.registerPacketEncodeFunc("HJ", function(ip_address, port) -- JoinServer packet
    local finalIp = ip_address
    if finalIp and port and port ~= "" then
      finalIp = finalIp..":"..port
    end
    return {
      ip_address = finalIp or M.connection.ip..":"..M.connection.serverPort
    }
  end)

  extensions.hook("onNGMPInit")
end

local function onExtensionLoaded()
  setExtensionUnloadMode(M, "manual")
end

local function onExtensionUnloaded()
  -- extension dependency system *should* handle this, but it might change across game updates
  for i=1, #M.extensionLoadList do
    extensions.unload(M.extensionLoadList[i])
  end
end

M.onUpdate = onUpdate
M.setBridgeConnected = setBridgeConnected
M.setLogin = setLogin
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

return M