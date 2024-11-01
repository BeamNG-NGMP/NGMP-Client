
local M = {}
M.dependencies = {"ngmp_main", "ngmp_network", "ngmp_settings"}

local currentLevel = ""
local autoDisconnect = false
local loadDefaultVehFunc = nop

local function onClientPreStartMission(filename)
  -- disconnect automatically
  if autoDisconnect and filename ~= currentLevel then
    ngmp_network.sendPacket("EX")
  end
end

local function loadLevel(confirm_id, filename)
  if FS:fileExists(filename) then
    -- overwrite normal defaultVehicle function
    loadDefaultVehFunc = core_levels.maybeLoadDefaultVehicle
    core_levels.maybeLoadDefaultVehicle = nop

    core_levels.startLevel(filename, false, function()
      autoDisconnect = true

      -- send a confirm to the launcher that we've loaded the map
      ngmp_network.sendPacket("CC", {data = {confirm_id}})

      server.fadeoutLoadingScreen()

      -- reset the defaultVehicle function
      core_levels.maybeLoadDefaultVehicle = loadDefaultVehFunc
    end)
  else
    log("E", "ngmp.levelMgr.loadLevel", "Level does not exist!")
  end
end

M.onClientPreStartMission = onClientPreStartMission
M.loadLevel = loadLevel

return M
