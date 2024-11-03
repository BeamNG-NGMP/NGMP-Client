
local M = {}

local im = ui_imgui
M.dependencies = {"ngmp_main", "ngmp_ui", "ngmp_playerData", "ngmp_settings"}

local mouseFocusedPlayerPopupName = "Vehicle Owner Detail View##NGMPUI"
local mouseFocusedPlayerData
local mouseDownTimer = 0
local lastMouseDown = false

local fadeStartDistance = 20
local fadeStopDistance = 120

local settingMode = 2
local settingFade = false
local settingHideBehind = false

local nameRenderFuncs = {
  [0] = function(dt)
    local camPos = vec3(core_camera.getPositionXYZ())
    for _,vehData in pairs(ngmp_vehicleMgr.vehsByObjId) do
      local steamId = vehData[2].steamId
      if vehData[2].vehObjId == be:getPlayerVehicleID(0) then goto next end
      local playerData = ngmp_playerData.playerDataById[steamId]

      local vehOBB = vehData[1]:getSpawnWorldOOBB()
      local textPos = vehOBB:getCenter() + vec3(0,0,vehOBB:getHalfExtents().z*1.1)

      if playerData then
        local nameColor, backgroundColor = playerData.nameColor, playerData.backgroundColor
        if settingFade or settingHideBehind then
          local distanceToCam = camPos:distance(textPos)
          if settingFade then
            if distanceToCam > fadeStopDistance then goto next end
            local fadeState = linearScale(distanceToCam, fadeStartDistance, fadeStopDistance, 1, 0)

            -- unfortunately we need to re-instantiate these :(
            nameColor = ColorF(playerData.nameColor.r, playerData.nameColor.g, playerData.nameColor.b, playerData.nameColor.a*fadeState)
            backgroundColor = ColorI(playerData.backgroundColor.r, playerData.backgroundColor.g, playerData.backgroundColor.b, playerData.backgroundColor.a*fadeState)
          end
          -- raycasts are more expensive than a simple distance check, so this is done *after* the fade
          if settingHideBehind and castRayStatic(camPos, textPos-camPos, distanceToCam+1) < distanceToCam then
            goto next
          end
        end

        -- no idea what that second boolean does
        -- but it places the text in the top left of my screen so im not touching it
        debugDrawer:drawTextAdvanced(textPos,
          string.format(" %s ", playerData.name),
          nameColor, true, false,
          backgroundColor
        )
      end
      ::next::
    end
  end,
  [1] = function(dt)
    mouseDownTimer = lastMouseDown and (mouseDownTimer + dt) or 0
    lastMouseDown = im.IsMouseDown(1)
    if mouseDownTimer > 0.2 then return end

    if mouseFocusedPlayerData then
      if im.BeginPopup(mouseFocusedPlayerPopupName) then
        ngmp_playerData.renderData(mouseFocusedPlayerData)
        im.EndPopup()
      end
    end

    local mouseDown = im.IsMouseReleased(1)
    if not mouseFocusedPlayerData and mouseDown then
      local camMouseRay = getCameraMouseRay()
      local vehData, distance = ngmp_vehicleMgr.getVehicleByRay(camMouseRay)

      if vehData and vehData[2] then
        if vehData[2].vehObjId == be:getPlayerVehicleID(0) or castRayStatic(camMouseRay.pos, camMouseRay.dir, distance+1) < distance then
          return
        end

        mouseFocusedPlayerData = ngmp_playerData.playerDataById[vehData[2].steamId]
        if mouseFocusedPlayerData then
          im.OpenPopup1(mouseFocusedPlayerPopupName)
        end
      else
        mouseFocusedPlayerData = nil
      end
    elseif mouseFocusedPlayerData and (mouseDown or im.IsMouseDown(0)) then
      mouseFocusedPlayerData = nil
    end
  end
}

local function onNGMPUI(dt)
  if ui_visibility and ui_visibility.get() == false then return end
  if not ngmp_vehicleMgr or settingMode == 2 then return end
  dump(settingMode)
  nameRenderFuncs[settingMode](dt)
end

local function onNGMPSettingsChanged()
  settingMode = ngmp_settings.get("vehicleTooltips", {"ui", "generic"})
  settingFade = ngmp_settings.get("fade", {"ui", "vehicleTooltip", "1"})
  settingHideBehind = ngmp_settings.get("hideBehind", {"ui", "vehicleTooltip", "1"})
end

local function onExtensionLoaded()
  setExtensionUnloadMode(M, "manual")
  onNGMPSettingsChanged()
end

M.onNGMPSettingsChanged = onNGMPSettingsChanged
M.onExtensionLoaded = onExtensionLoaded
M.onNGMPUI = onNGMPUI

return M
