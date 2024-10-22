

local M = {
  name = "Settings",
  author = "DaddelZeit (NGMP Official)"
}

local im = ui_imgui

local tabs = {
  {
    name = "Mod Cache",
    render = function()
      im.Text(("Cache Size: %.1fGB"):format(ngmp_mods.totalSizeGB))
      im.PushFont3("cairo_bold")
      ngmp_ui.primaryButton("Clear Cache", im.ImVec2(im.GetContentRegionAvailWidth(), im.GetTextLineHeightWithSpacing()*math.max(ngmp_mods.totalSizeGB, 1)))
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