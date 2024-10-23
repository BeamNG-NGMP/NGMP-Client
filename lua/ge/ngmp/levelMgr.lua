
local M = {}
M.dependencies = {"ngmp_main", "ngmp_network", "ngmp_settings"}

local currentLevel = ""
local autoDisconnect = false

local function onClientPreStartMission(filename)
  if autoDisconnect and filename ~= currentLevel then
    ngmp_network.sendPacket("EX")
  end
end

local function loadLevel(filename)
  if FS:fileExists(filename) then
    core_levels.startLevel(filename, false, function()
      autoDisconnect = true
      ngmp_network.sendPacket("CC")
      server.fadeoutLoadingScreen()
    end)
  else
    log("E", "loadLevel", "Level does not exist!")
  end
end

M.onClientPreStartMission = onClientPreStartMission
M.loadLevel = loadLevel

return M