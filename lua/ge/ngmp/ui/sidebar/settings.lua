

local M = {
  name = ngmp_ui_translate("ui.sidebar.tabs.settings.name"),
  author = ngmp_ui_translate("ui.sidebar.tabs.settings.author")
}

local im = ui_imgui

local vehicleTooltipsLookup = {
  [0] = ngmp_ui_translate("ui.sidebar.tabs.settings.userInterface.vehicleTooltip.0"),
  [1] = ngmp_ui_translate("ui.sidebar.tabs.settings.userInterface.vehicleTooltip.1"),
  [2] = ngmp_ui_translate("ui.sidebar.tabs.settings.userInterface.vehicleTooltip.2")
}

local function renderCheckbox(id, cats, translateCat)
  local boolPtr = im.BoolPtr(ngmp_settings.get(id, cats))
  if ngmp_ui.checkbox(ngmp_ui_translate("ui.sidebar.tabs.settings."..translateCat..id), boolPtr) then
    ngmp_settings.set(id, boolPtr[0], cats)
  end
end

local tabs = {
  {
    name = ngmp_ui_translate("ui.sidebar.tabs.settings.userInterface.header"),
    render = function()
      renderCheckbox("closeOnLeftClickOutOfArea", {"ui", "sidebar"}, "userInterface.")

      local vehTooltip = ngmp_settings.get("vehicleTooltips", {"ui", "generic"})
      do
        if im.BeginCombo(ngmp_ui_translate("ui.sidebar.tabs.settings.userInterface.vehicleTooltip"), vehicleTooltipsLookup[vehTooltip]) then
          im.SetWindowFontScale(0.7)
          for i=0, 2 do
            if ngmp_ui.Selectable1(vehicleTooltipsLookup[i]) then
              ngmp_settings.set("vehicleTooltips", i, {"ui", "generic"})
            end
          end
          im.SetWindowFontScale(1)
          im.EndCombo()
        end
      end
      if vehTooltip == 0 then
        renderCheckbox("fade", {"ui", "vehicleTooltip", "1"}, "userInterface.vehicleTooltip.")
        renderCheckbox("hideBehind", {"ui", "vehicleTooltip", "1"}, "userInterface.vehicleTooltip.")
      end
      im.Dummy(im.ImVec2(0,0))
      im.Text(ngmp_ui_translate("ui.sidebar.tabs.settings.userInterface.chat"))
      im.Separator()
      renderCheckbox("alwaysSteamIDonHover", {"ui", "generic"}, "userInterface.")
    end,
    lastCursorPosY = 0,
    targetSize = 1,
    extensionSmoother = newTemporalSigmoidSmoothing(950, 750)
  },
  {
    name = ngmp_ui_translate("ui.sidebar.tabs.settings.mod.header"),
    render = function()
      im.Text(ngmp_ui_translate("ui.sidebar.tabs.settings.mod.totalsize", {totalGB = ngmp_modMgr.totalSizeGB}))
      im.PushFont3("cairo_bold")
      ngmp_ui.primaryButton(ngmp_ui_translate("ui.sidebar.tabs.settings.mod.clear"), im.ImVec2(im.GetContentRegionAvailWidth(), im.GetTextLineHeightWithSpacing()*math.max(ngmp_modMgr.totalSizeGB or 1, 1)))
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
