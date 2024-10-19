

local M = {
  name = "Connect",
  author = "DaddelZeit (NGMP Official)"
}

local im = ui_imgui
local imguiUtils = require("ui/imguiUtils")


local function render(dt, windowWidth, windowHeight, indent)
  im.BeginChild1("Server List##NGMPUI", im.ImVec2(windowWidth, ngmp_ui.getPercentVecY(20, true)))
  for k,v in ipairs({"a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a"}) do
    im.Selectable1(v.."##"..k)
  end
  im.EndChild()
end

local function init()

end

M.render = render
M.init = init

return M