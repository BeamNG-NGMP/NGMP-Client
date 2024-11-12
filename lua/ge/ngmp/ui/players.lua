
local M = {}

local im = ui_imgui
local imguiUtils = require('ui/imguiUtils')
local playerWindowHandle = rerequire("ngmp/ui/genericWindow")("playerListUi", "ui.playerlist.name")
M.dependencies = {"ngmp_main", "ngmp_ui", "ngmp_playerData", "ngmp_settings"}

local contactTxt = ngmp_ui_translate("ui.playerlist.contact")
local removeVehTxt = ngmp_ui_translate("ui.playerlist.removeVeh")
local respawnVehTxt = ngmp_ui_translate("ui.playerlist.respawnVeh")
local copysteamTxt = ngmp_ui_translate("ui.playerlist.copysteam")
local lastHoveredPlayer

local function render(dt)
  local style = im.GetStyle()
  im.SetWindowFontScale(0.85)
  im.SetNextWindowBgAlpha(0.6)
  im.BeginChild1("PlayersContent##NGMPUI", im.ImVec2(im.GetContentRegionAvailWidth(), im.GetContentRegionAvail().y), true)
  im.SetWindowFontScale(1)
  im.PushTextWrapPos(im.GetContentRegionAvailWidth())

  local hoveredPlayer = lastHoveredPlayer
  for playerIndex,playerData in pairs(ngmp_playerData.playerData) do
    ngmp_playerData.renderData(playerData)
    hoveredPlayer = im.IsItemHovered() and playerIndex or hoveredPlayer
    im.Separator()
  end

  if hoveredPlayer and im.BeginPopupContextWindow("PlayerOptions##NGMPUI") then
    lastHoveredPlayer = hoveredPlayer
    im.SetWindowFontScale(0.8)
    im.PushFont3("cairo_bold")
    if ngmp_ui.Selectable1(contactTxt) then
      -- contact
      ngmp_ui_chat.directMessage(ngmp_playerData.playerData[hoveredPlayer].name, ngmp_playerData.playerData[hoveredPlayer].steamId)
    end
    im.PopFont()
    im.PushFont3("cairo_regular")
    if ngmp_ui.Selectable1(removeVehTxt) then
      -- contact
    end
    if ngmp_ui.Selectable1(respawnVehTxt) then
      -- contact
    end
    if ngmp_ui.Selectable1(copysteamTxt) then
      setClipboard(ngmp_playerData.playerData[hoveredPlayer].steamId)
    end
    im.PopFont()
    im.EndPopup()
  else
    lastHoveredPlayer = nil
  end

  im.PopTextWrapPos()
  im.EndChild()
end

local function onNGMPUI(dt)
  im.SetNextWindowBgAlpha(0.25)
  playerWindowHandle:render(dt, render)
end

local function onNGMPSettingsChanged()
  playerWindowHandle.transparency = ngmp_settings.get("windowTransparency", {"ui","generic"})
end

local function onExtensionLoaded()
  setExtensionUnloadMode(M, "manual")
end

M.onExtensionLoaded = onExtensionLoaded
M.onNGMPUI = onNGMPUI
M.onNGMPSettingsChanged = onNGMPSettingsChanged

return M
