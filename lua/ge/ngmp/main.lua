
-- extension that loads all files and does the main state management
local M = {}

M.toml = require("ngmp/tomlFile")
M.savePath = "/"
M.clientVersion = 0

-- TODO: actually implement a check for this
M.protocolVersion = 0

do -- meta stuff
  local configData = M.toml.readFile("/ngmp/config.toml") or {}

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
  "ngmp_playerData",
  "ngmp_serverList",

  -- modMgr is somewhat needed for UI beforehand
  "ngmp_modMgr",

  -- ui goes last
  "ngmp_ui",
  "ngmp_ui_sidebar",
}

-- this is only loaded when joining a server and unloaded when leaving
-- switching servers causes a reload
M.serverExtensionList = {
  -- the managers...
  "ngmp_levelMgr",
  "ngmp_vehicleMgr",
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
  for i=1, #M.serverExtensionList do
    extensions.unload(M.serverExtensionList[i])
  end

  if err then
    -- connection fail!
  else
    -- connection ended
  end
end

local function connect(data)
  for i=1, #M.serverExtensionList do
    extensions.load(M.serverExtensionList[i])
  end

  ngmp_levelMgr.loadLevel(data.confirm_id, data.map_string)
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

  -- register all generic, connection specific or login specific packets
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

  ngmp_network.registerPacketDecodeFunc("LM", connect)

  -- startup after *all* modules are loaded
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
