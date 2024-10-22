

local M = {
  name = "Template",
  author = "DaddelZeit (NGMP Official)"
}

local im = ui_imgui

local imguiUtils = require("ui/imguiUtils")

local targetSize = 1
local extensionSmoother = newTemporalSigmoidSmoothing(950, 750)

local textArray = im.ArrayChar(128)

local function renderDirectConnect(dt)
  im.Text("Put your widgets here.")
  im.BulletText("There's a lot you can do.")

  im.Text("Even this:")
  im.SameLine()
  im.SetNextItemWidth(im.GetContentRegionAvailWidth())
  local cursorPos = im.GetCursorPos()
  im.InputText("##TemplateInputTextId", textArray, 128)
  if not im.IsItemActive() and textArray[0] == 0 then
    local postCursorPos = im.GetCursorPos()
    im.SetCursorPosX(cursorPos.x+5)
    im.SetCursorPosY(cursorPos.y)
    im.BeginDisabled()
    im.Text("Default Text")
    im.EndDisabled()
    im.SetCursorPos(postCursorPos)
  end
end

local function render(dt)
  im.SetWindowFontScale(0.8)
  local style = im.GetStyle()
  if extensionSmoother:get(targetSize, dt) >= 0.5 then
    im.BeginChild1("ServerListFilters##NGMPUI", im.ImVec2(im.GetContentRegionAvailWidth(), math.ceil(extensionSmoother.state)), true, im.WindowFlags_NoScrollbar)
    im.SetWindowFontScale(1)
    renderDirectConnect()
    im.Dummy(im.ImVec2(0,style.ItemSpacing.y))
    if targetSize ~= 0 then
      targetSize = im.GetCursorPosY()
    end
    im.EndChild()
  else
    im.Dummy(im.ImVec2(0,extensionSmoother.state))
  end

  im.SetWindowFontScale(1)
end

local function init()
end

M.render = render
M.init = init

return M