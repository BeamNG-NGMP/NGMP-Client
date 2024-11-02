

local M = {
  name = "Launcher Connection",
  author = "DaddelZeit (NGMP Official)"
}

local im = ui_imgui
local imguiUtils = require("ui/imguiUtils")

local router
local feedbackTargetSize = 1
local feedbackExtensionSmoother = newTemporalSigmoidSmoothing(950, 750)

local function centerText(text, centerX)
  im.SetCursorPosX(centerX-im.CalcTextSize(text).x/2)
  im.Text(text)
end

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
  centerText("Looks like we can't connect to the launcher!", center.x)
  im.NewLine()
  local btnWidth = im.GetContentRegionAvailWidth()/2
  im.SetCursorPosX(center.x-btnWidth/2)
  if ngmp_ui.primaryButton("Retry", im.ImVec2(btnWidth, im.GetTextLineHeight()*1.5)) then
    ngmp_network.retryConnection()
  end

  im.SetWindowFontScale(1)
  if ngmp_network and ngmp_network.connection.errType ~= "" then
    if feedbackExtensionSmoother:get(feedbackTargetSize, dt) >= 0.5 then
      im.SetCursorPosY(im.GetWindowHeight()-math.ceil(feedbackExtensionSmoother.state)-3)
      im.BeginChild1("ConnectionFeedback##NGMPUI", im.ImVec2(im.GetContentRegionAvailWidth(), math.ceil(feedbackExtensionSmoother.state)), true, im.WindowFlags_NoScrollbar)

      im.PushTextWrapPos(im.GetContentRegionAvailWidth())
      im.PushFont3("robotomono_regular")
      im.SetWindowFontScale(0.75)
      im.Text("Error Report")
      im.Separator()
      im.SetWindowFontScale(0.75)
      im.Text(ngmp_network.connection.errType)
      im.Text("\""..ngmp_network.connection.err.."\"")
      im.SetWindowFontScale(1)
      im.PopFont()
      im.PopTextWrapPos()

      if feedbackTargetSize ~= 0 then
        feedbackTargetSize = im.GetCursorPosY()
      end
      im.EndChild()
    else
      im.Dummy(im.ImVec2(0,feedbackExtensionSmoother.state))
    end
  end
end

local function init()
  router = FS:fileExists("/art/ngmpui/router.png") and imguiUtils.texObj("/art/ngmpui/router.png")
end

M.render = render
M.init = init

return M
