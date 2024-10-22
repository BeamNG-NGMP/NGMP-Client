
-- extension that loads all files and does the main state management
local M = {}

M.protocolVersion = 0
do -- meta stuff
  M.clientVersion = tonumber(readFile("/ngmp/client_version.txt") or 0)
  local f = io.open("/ngmp/client_version.txt", "r")
  if f == nil then
    M.clientVersion = 0
  else
    M.clientVersion = tonumber(f:read("l"))
    f:close()
  end
end

local firstUpdate = false
M.isLoggedIn = false
M.playerName = ""
M.isBridgeConnected = false
M.extensionLoadList = {
  -- network first
  "ngmp_network",

  -- then the helper stuff...
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

  ngmp_network.sendPacket("CI")
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