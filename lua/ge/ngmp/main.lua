
-- extension that loads all files and does the main state management
local M = {}

M.savePath = "/"
M.clientVersion = 0
M.protocolVersion = 0

do -- meta stuff
  local iniData = loadIni("/ngmp/info.ini") or {}
  M.clientVersion = iniData.client_version or M.clientVersion
  M.savePath = iniData.save_path or M.savePath
end

local firstUpdate = false
M.isLoggedIn = false
M.playerName = ""
M.isBridgeConnected = false
M.extensionLoadList = {
  -- network first
  "ngmp_network",

  -- then the helper stuff...
  "ngmp_settings",
  "ngmp_mods",
  "ngmp_serverList",

  -- ui goes last
  "ngmp_ui",
  "ngmp_ui_sidebar",
}

local function setLogin(loggedIn, player)
  M.isLoggedIn = loggedIn or false
  M.playerName = player or ""
  extensions.hook("onNGMPLogin", M.isLoggedIn, M.playerName)
end

local function setBridgeConnected(protocolVersion, bridgeConnected)
  M.isBridgeConnected = bridgeConnected or true
  M.protocolVersion = protocolVersion or M.protocolVersion
  extensions.hook("onNGMPLauncherConnect", M.isBridgeConnected)
end

local function onUpdate()
  if firstUpdate then return end
  firstUpdate = true

  for i=1, #M.extensionLoadList do
    extensions.load(M.extensionLoadList[i])
  end
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