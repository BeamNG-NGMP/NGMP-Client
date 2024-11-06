

local M = {
  name = ngmp_ui_translate("ui.sidebar.tabs.launcher.name"),
  author = ngmp_ui_translate("ui.sidebar.tabs.launcher.author")
}

local im = ui_imgui
local imguiUtils = require("ui/imguiUtils")

local router
local feedbackTargetSize = 1
local feedbackExtensionSmoother = newTemporalSigmoidSmoothing(950, 750)

local networkErrText = ngmp_ui_translate("ui.sidebar.tabs.launcher.error", {err = ngmp_network.connection.err})

local function render(dt)
  local style = im.GetStyle()
  local center = im.ImVec2(im.GetContentRegionAvailWidth()/2, im.GetContentRegionAvail().y/2)
  im.SetCursorPosX(center.x)
  im.SetCursorPosY(center.y)

  im.SetWindowFontScale(1.75)
  im.PushFont3("cairo_regular_medium")
  im.SetCursorPosX(center.x-im.CalcTextSize(ngmp_ui_translate("ui.sidebar.generic.fuckup").txt).x/2)
  im.SetCursorPosY(im.GetCursorPosY()-im.GetTextLineHeightWithSpacing()*1.8)
  ngmp_ui.TextU(ngmp_ui_translate("ui.sidebar.generic.fuckup"))
  im.PopFont()
  im.SetWindowFontScale(1)

  if router then
    local sizeFac = ngmp_ui.getPercentVecX(4, false, true)/router.size.x
    local size = ngmp_ui.mulVec2Num(router.size, sizeFac)
    im.SetCursorPosX(center.x-size.x/2)
    im.SetCursorPosY(center.y-size.y/2-im.GetTextLineHeight()*0.8)

    im.Image(router.texId, size)
  end

  im.SetWindowFontScale(0.9)
  ngmp_ui.TextCentered(ngmp_ui_translate("ui.sidebar.tabs.launcher.info"), center.x)
  im.NewLine()
  local btnWidth = im.GetContentRegionAvailWidth()/2
  im.SetCursorPosX(center.x-btnWidth/2)
  if ngmp_ui.primaryButton(ngmp_ui_translate("ui.sidebar.generic.input.retry"), im.ImVec2(btnWidth, im.GetTextLineHeight()*1.5)) then
    ngmp_network.retryConnection()
  end

  im.SetWindowFontScale(1)
  if ngmp_network and ngmp_network.connection.errType ~= "" then
    if feedbackExtensionSmoother:get(feedbackTargetSize, dt) >= 0.5 then
      im.SetCursorPosY(im.GetWindowHeight()-math.ceil(feedbackExtensionSmoother.state)-3)
      im.BeginChild1("ConnectionFeedback##NGMPUI", im.ImVec2(im.GetContentRegionAvailWidth(), math.ceil(feedbackExtensionSmoother.state)), true, im.WindowFlags_NoScrollbar)

      ngmp_ui.TextU(ngmp_ui_translate("ui.sidebar.tabs.launcher.report"))
      im.Separator()
      im.PushTextWrapPos(im.GetContentRegionAvailWidth())
      im.PushFont3("robotomono_regular")
      im.SetWindowFontScale(0.75)
      ngmp_ui.TextU(ngmp_network.connection.errType)
      if networkErrText.context.err ~= ngmp_network.connection.err then
        networkErrText:update({err = ngmp_network.connection.err})
      end
      ngmp_ui.TextU(networkErrText)
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
