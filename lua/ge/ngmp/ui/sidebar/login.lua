

local M = {
  name = "Login",
  author = "DaddelZeit (NGMP Official)"
}

local im = ui_imgui
local imguiUtils = require("ui/imguiUtils")

local lock
local unlock
local showLocked = true

local function render(dt)
  local style = im.GetStyle()
  local center = im.ImVec2(im.GetContentRegionAvailWidth()/2, im.GetContentRegionAvail().y/2)
  im.SetCursorPosX(center.x)
  im.SetCursorPosY(center.y)

  im.PushFont3("cairo_bold")
  local buttonSize = ngmp_ui.calculateButtonSize("Log in with Steam")
  buttonSize.x = center.x
  im.PopFont()

  if lock and unlock then
    local sizeFac = ngmp_ui.getPercentVecX(4, false, true)/lock.size.x
    local size = ngmp_ui.mulVec2Num(lock.size, sizeFac)
    im.SetCursorPosX(im.GetCursorPosX()-size.x/2)
    im.SetCursorPosY(im.GetCursorPosY()-size.y/2-buttonSize.y)

    if showLocked then
      im.Image(lock.texId, size)
    else
      im.Image(unlock.texId, size)
    end
  end

  im.PushFont3("cairo_bold")
  im.SetCursorPosX(center.x-buttonSize.x/2)
  if ngmp_ui.primaryButton("Log in with Steam", buttonSize) then
    ngmp_network.sendPacket("LR")
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