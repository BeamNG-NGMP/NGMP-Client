

local M = {
  name = "Login",
  author = "DaddelZeit (NGMP Official)"
}

local im = ui_imgui
local imguiUtils = require("ui/imguiUtils")

local lock
local unlock
local showLocked = true

local function render(dt, windowWidth, windowHeight, indent)
  local style = im.GetStyle()
  local center = im.ImVec2(indent+windowWidth/2, windowHeight/2)
  im.SetCursorPosX(center.x)
  im.SetCursorPosY(center.y)

  if lock and unlock then
    local sizeFac = ngmp_ui.getPercentVecX(4, false, true)/lock.size.x
    local size = ngmp_ui.mulVec2Num(lock.size, sizeFac)
    im.SetCursorPosX(im.GetCursorPosX()-size.x/2)
    im.SetCursorPosY(im.GetCursorPosY()-size.y/2)

    if showLocked then
      im.Image(lock.texId, size)
    else
      im.Image(unlock.texId, size)
    end
  end

  im.PushFont3("cairo_bold")
  local textWidth = im.CalcTextSize("Log In with Steam").x
  im.NewLine()
  im.SetCursorPosX(center.x-textWidth/2-style.FramePadding.x*2-style.ItemSpacing.x/2)
  if im.Button("Log In with Steam") then
    showLocked = not showLocked
  end
  im.PopFont()
end

local function init()
  lock = FS:fileExists("/art/ngmpui/locked.png") and imguiUtils.texObj("/art/ngmpui/locked.png")
  unlock = FS:fileExists("/art/ngmpui/unlocked.png") and imguiUtils.texObj("/art/ngmpui/unlocked.png")
end

M.render = render
M.init = init

return M