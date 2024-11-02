
local M = {}
M.dependencies = {"ngmp_main", "ngmp_network", "ngmp_settings"}

local currentLevel = ""
local autoDisconnect = false
local loadConfirmId

local function onClientPreStartMission(filename)
  -- disconnect automatically
  if autoDisconnect and filename ~= currentLevel then
    ngmp_network.sendPacket("EX")
  end
end

local function onClientPostStartMission()
  if loadConfirmId then
    autoDisconnect = true

    -- send a confirm to the launcher that we've loaded the map
    ngmp_network.sendPacket("CC", {data = {loadConfirmId}})
  end
end

local function loadLevel(confirm_id, filename)
  loadConfirmId = confirm_id
  if FS:fileExists(filename) then
    core_levels.startLevel(filename, nil, nil, false)
  else
    log("E", "ngmp.levelMgr.loadLevel", "Level does not exist!")
  end
end

M.onClientPreStartMission = onClientPreStartMission
M.onClientPostStartMission = onClientPostStartMission
M.loadLevel = loadLevel

return M
