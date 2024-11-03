

local M = {
  name = "Settings",
  author = "DaddelZeit (NGMP Official)"
}

local im = ui_imgui

local vehicleTooltipsLookup = {
  [0] = "Always Show Text",
  [1] = "Show on Right Click",
  [2] = "Never Show"
}
local tabs = {
  {
    name = "User Interface",
    render = function()
      do
        local boolPtr = im.BoolPtr(ngmp_settings.get("closeOnLeftClickOutOfArea", {"ui", "sidebar"}))
        if im.Checkbox("Close sidebar on click beside", boolPtr) then
          ngmp_settings.set("closeOnLeftClickOutOfArea", boolPtr[0], {"ui", "sidebar"})
        end
      end

      local vehTooltip = ngmp_settings.get("vehicleTooltips", {"ui", "generic"})
      do
        if im.BeginCombo("Name Tooltips", vehicleTooltipsLookup[vehTooltip]) then
          im.SetWindowFontScale(0.7)
          for i=0, 2 do
            if im.Selectable1(vehicleTooltipsLookup[i]) then
              ngmp_settings.set("vehicleTooltips", i, {"ui", "generic"})
            end
          end
          im.SetWindowFontScale(1)
          im.EndCombo()
        end
      end
      if vehTooltip == 0 then
        do
          local boolPtr = im.BoolPtr(ngmp_settings.get("fade", {"ui", "vehicleTooltip", "1"}))
          if im.Checkbox("Fade Names by Distance", boolPtr) then
            ngmp_settings.set("fade", boolPtr[0], {"ui", "vehicleTooltip", "1"})
          end
        end
        do
          local boolPtr = im.BoolPtr(ngmp_settings.get("hideBehind", {"ui", "vehicleTooltip", "1"}))
          if im.Checkbox("Hide Names Behind Objects", boolPtr) then
            ngmp_settings.set("hideBehind", boolPtr[0], {"ui", "vehicleTooltip", "1"})
          end
        end
      end
      im.Dummy(im.ImVec2(0,0))
      im.Text("Chat")
      im.Separator()
      do
        local boolPtr = im.BoolPtr(ngmp_settings.get("alwaysSteamIDonHover", {"ui", "generic"}))
        if im.Checkbox("Always show SteamID in user popup", boolPtr) then
          ngmp_settings.set("alwaysSteamIDonHover", boolPtr[0], {"ui", "generic"})
        end
      end
    end,
    lastCursorPosY = 0,
    targetSize = 1,
    extensionSmoother = newTemporalSigmoidSmoothing(950, 750)
  },
  {
    name = "Mod Cache",
    render = function()
      im.Text(("%.1fGB used"):format(ngmp_modMgr.totalSizeGB))
      im.PushFont3("cairo_bold")
      ngmp_ui.primaryButton("Clear Cache", im.ImVec2(im.GetContentRegionAvailWidth(), im.GetTextLineHeightWithSpacing()*math.max(ngmp_modMgr.totalSizeGB or 1, 1)))
      im.PopFont()
    end,
    lastCursorPosY = 0,
    targetSize = 1,
    extensionSmoother = newTemporalSigmoidSmoothing(950, 750)
  }
}

local function renderTab(dt, tab, i)
  im.SetWindowFontScale(0.8)
  local style = im.GetStyle()
  if tab.extensionSmoother:get(tab.targetSize, dt) >= 0.5 then
    im.BeginChild1("SideBarSettingTab"..i.."##NGMPUI", im.ImVec2(im.GetContentRegionAvailWidth(), math.ceil(tab.extensionSmoother.state)), true, im.WindowFlags_NoScrollbar)
    im.SetWindowFontScale(1)
    im.Text(tab.name)
    im.Separator()
    im.Dummy(im.ImVec2(0,0))
    tab.render()
    if tab.targetSize ~= 0 and tab.targetSize ~= tab.extensionSmoother.state or tab.lastCursorPosY ~= im.GetCursorPosY() then
      tab.targetSize = im.GetCursorPosY()+style.ItemSpacing.y+style.WindowPadding.y
    end
    tab.lastCursorPosY = im.GetCursorPosY()
    im.EndChild()
  else
    im.Dummy(im.ImVec2(0,tab.extensionSmoother.state))
  end

  im.SetWindowFontScale(1)
end

local function render(dt)
  im.BeginChild1("SideBarSettingTab##NGMPUI", im.GetContentRegionAvail(), false, im.WindowFlags_NoBackground)
  for i=1, #tabs do
    renderTab(dt, tabs[i], i)
  end
  im.Dummy(im.ImVec2(0,0))
  im.EndChild()
end

local function init()
end

M.render = render
M.init = init

return M
