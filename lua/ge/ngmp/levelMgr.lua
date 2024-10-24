
local M = {}
M.dependencies = {"ngmp_main", "ngmp_network", "ngmp_settings"}

local currentLevel = ""
local autoDisconnect = false
local loadDefaultVehFunc = nop

local function onClientPreStartMission(filename)
  if autoDisconnect and filename ~= currentLevel then
    ngmp_network.sendPacket("EX")
  end
end

local function loadLevel(filename)
  if FS:fileExists(filename) then
    loadDefaultVehFunc = core_levels.maybeLoadDefaultVehicle
    core_levels.maybeLoadDefaultVehicle = nop

    core_levels.startLevel(filename, false, function()
      autoDisconnect = true
      ngmp_network.sendPacket("CC")
      server.fadeoutLoadingScreen()
      core_levels.maybeLoadDefaultVehicle = loadDefaultVehFunc
    end)
  else
    log("E", "loadLevel", "Level does not exist!")
  end
end

M.onClientPreStartMission = onClientPreStartMission
M.loadLevel = loadLevel

return M