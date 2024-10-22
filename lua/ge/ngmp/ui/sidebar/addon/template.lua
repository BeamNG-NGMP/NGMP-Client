

local M = {
  name = "Template",
  author = "DaddelZeit (NGMP Official)",
  targetSize = 1,
  extensionSmoother = newTemporalSigmoidSmoothing(950, 750),
  lastCursorPosY = 0
}

local im = ui_imgui
local imguiUtils = require("ui/imguiUtils")

local textArray = im.ArrayChar(128)

local function render(dt)
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

  ngmp_ui.button("Even Buttons!")
  ngmp_ui.button("And scaled buttons!", im.ImVec2(im.GetContentRegionAvailWidth(), 0))

  im.PushFont3("cairo_bold")
  ngmp_ui.primaryButton("And fancy buttons")
  im.PopFont()
end

local function onClose()
end

local function init()
end

M.render = render
M.init = init
M.onClose = onClose

return M