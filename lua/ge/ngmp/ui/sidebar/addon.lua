

local M = {
  name = ngmp_ui_translate("ui.sidebar.tabs.addon.name"),
  author = ngmp_ui_translate("ui.sidebar.tabs.addon.author")
}

local im = ui_imgui

local uiModules = {}
local tabs = {}

local function renderTab(dt, tab, i)
  im.SetWindowFontScale(0.8)
  local style = im.GetStyle()
  if tab.extensionSmoother:get(tab.targetSize, dt) >= 0.5 then
    im.BeginChild1("SideBarAddonTab"..i.."##NGMPUI", im.ImVec2(im.GetContentRegionAvailWidth(), math.ceil(tab.extensionSmoother.state)), true, im.WindowFlags_NoScrollbar)
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
  im.BeginChild1("SideBarAddonTab##NGMPUI", im.GetContentRegionAvail(), false, im.WindowFlags_NoBackground)
  for i=1, #tabs do
    renderTab(dt, tabs[i], i)
  end
  im.Dummy(im.ImVec2(0,0))
  im.EndChild()
end

local function open(modulePath)
  if not FS:fileExists(modulePath) then
    log("E", "ngmp.ui.sidebar.addon.open", "Sidebar tab attempted to load not existing extension module. If you are a mod developer, verify the path.")
    return false
  end

  local moduleName = modulePath:match("^(.+)%.")
  local moduleKey = moduleName:match("^.+/(.+)")

  if not uiModules[moduleKey] then
    local module = rerequire(moduleName)
    module.init()
    uiModules[moduleKey] = module

    tabs[#tabs+1] = module
    return true
  end
  return false
end

local function close(modulePath)
  local module = uiModules[modulePath:match("^.+/(.+)%.")]
  if not module then return end
  local index = arrayFindValueIndex(tabs, module)
  if index then
    table.remove(tabs, index)
    if module.onClose then
      module.onClose()
    end
    uiModules[modulePath:match("^.+/(.+)%.")] = nil
  end
  return #tabs == 0
end

local function init()
end

M.render = render
M.init = init
M.open = open
M.close = close

return M
