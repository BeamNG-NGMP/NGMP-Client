

local M = {
  name = "Launcher Connection",
  author = "DaddelZeit (NGMP Official)"
}

local im = ui_imgui
local imguiUtils = require("ui/imguiUtils")

local router

local function render(dt)
  local style = im.GetStyle()
  local center = im.ImVec2(im.GetContentRegionAvailWidth()/2, im.GetContentRegionAvail().y/2)
  im.SetCursorPosX(center.x)
  im.SetCursorPosY(center.y)

  im.PushFont3("cairo_regular_medium")
  im.SetWindowFontScale(1.75)
  im.SetCursorPosX(center.x-im.CalcTextSize("Uh-Oh!").x/2)
  im.SetCursorPosY(im.GetCursorPosY()-im.GetTextLineHeightWithSpacing()*1.8)
  im.Text("Uh-Oh!")
  im.SetWindowFontScale(1)
  im.PopFont()

  if router then
    local sizeFac = ngmp_ui.getPercentVecX(4, false, true)/router.size.x
    local size = ngmp_ui.mulVec2Num(router.size, sizeFac)
    im.SetCursorPosX(center.x-size.x/2)
    im.SetCursorPosY(center.y-size.y/2-im.GetTextLineHeight()*0.8)

    im.Image(router.texId, size)
  end

  im.SetWindowFontScale(0.9)
  im.SetCursorPosX(center.x-im.CalcTextSize("Looks like we can't connect to the launcher!").x/2)
  im.Text("Looks like we can't connect to the launcher!")
  im.SetWindowFontScale(1)
end

local function init()
  router = FS:fileExists("/art/ngmpui/router.png") and imguiUtils.texObj("/art/ngmpui/router.png")
end

M.render = render
M.init = init

return M