

local M = {
  name = "Connect",
  author = "DaddelZeit (NGMP Official)"
}

local im = ui_imgui

local ngmpUtils = rerequire("ngmp/utils")
local imguiUtils = require("ui/imguiUtils")

local directConnectTargetSize = 1
local directConnectExtensionSmoother = newTemporalSigmoidSmoothing(950, 750)
local directConnectIp = im.ArrayChar(128)
local directConnectPort = im.ArrayChar(128)

local filtersTargetSize = 1
local filtersExtensionSmoother = newTemporalSigmoidSmoothing(950, 750)
local filters = {
  searchQuery = im.ArrayChar(128),
  empty = false,
  notEmpty = false,
  notFull = false,
  level = false,
}
local levelIds = {}

local function search()
end

local function filterCheckbox(name, val)
  local temp = im.BoolPtr(val or false)
  return im.Checkbox(name, temp)
end

local function renderDirectConnect(dt)
  local style = im.GetStyle()
  if directConnectExtensionSmoother:get(directConnectTargetSize, dt) >= 0.5 then
    im.BeginChild1("ServerListFilters##NGMPUI", im.ImVec2(im.GetContentRegionAvailWidth(), math.ceil(directConnectExtensionSmoother.state)), true, im.WindowFlags_NoScrollbar)
    im.SetWindowFontScale(1)

    im.Text("IP Address: ")
    im.SameLine()
    im.SetNextItemWidth(im.GetContentRegionAvailWidth())
    local cursorPos = im.GetCursorPos()
    im.InputText("##DirectConnectIP", directConnectIp, 128)
    if not im.IsItemActive() and directConnectIp[0] == 0 then
      local postCursorPos = im.GetCursorPos()
      im.SetCursorPosX(cursorPos.x+5)
      im.SetCursorPosY(cursorPos.y)
      im.BeginDisabled()
      im.Text("127.0.0.1")
      im.EndDisabled()
      im.SetCursorPos(postCursorPos)
    end

    im.Text("Port: ")
    im.SameLine()
    im.SetNextItemWidth(im.GetContentRegionAvailWidth())
    im.InputText("##DirectConnectPort", directConnectPort, 128)

    if ngmp_ui.button("Set from Clipboard", im.ImVec2(im.GetContentRegionAvailWidth(), 0)) then
      local ip, port = ngmpUtils.splitIP(getClipboard())
      ffi.copy(directConnectIp, ip or "")
      ffi.copy(directConnectPort, port or "")
    end
    im.Dummy(im.ImVec2(0,style.ItemSpacing.y))
    ngmp_ui.primaryButton("Connect", im.ImVec2(im.GetContentRegionAvailWidth(), im.GetTextLineHeight()*2))

    im.Dummy(im.ImVec2(0,style.ItemSpacing.y))
    if directConnectTargetSize ~= 0 then
      directConnectTargetSize = im.GetCursorPosY()
    end
    im.EndChild()
  else
    im.Dummy(im.ImVec2(0,directConnectExtensionSmoother.state))
  end
end

local function renderRecent()
end

local function renderFavorites()
end

local function renderServerList(dt)
  local style = im.GetStyle()
  im.SetNextItemWidth(im.GetContentRegionAvailWidth())

  local cursorPos = im.GetCursorPos()
  if im.InputText("##search", filters.searchQuery) then
    search()
  end
  if not im.IsItemActive() and filters.searchQuery[0] == 0 then
    local postCursorPos = im.GetCursorPos()
    im.SetCursorPosX(cursorPos.x+5)
    im.SetCursorPosY(cursorPos.y)
    im.BeginDisabled()
    im.Text("Search...")
    im.EndDisabled()
    im.SetCursorPos(postCursorPos)
  end

  if filtersExtensionSmoother:get(filtersTargetSize, dt) >= 0.5 then
    im.SetWindowFontScale(0.8)

    im.BeginChild1("ServerListFilters##NGMPUI", im.ImVec2(im.GetContentRegionAvailWidth(), math.ceil(filtersExtensionSmoother.state)), true, im.WindowFlags_NoScrollbar)
    im.Indent(style.WindowPadding.x)
    im.Text("Filters")
    if im.BeginTable("ServerListFiltersOptions##NGMPUI", 2) then
      im.TableNextColumn()
      if filterCheckbox("Empty", filters.empty) then
        filters.empty = not filters.empty
      end
      im.TableNextColumn()
      if filterCheckbox("Not Empty", filters.notEmpty) then
        filters.notEmpty = not filters.notEmpty
      end
      im.TableNextColumn()
      if filterCheckbox("Not Full", filters.notFull) then
        filters.notFull = not filters.notFull
      end
      im.TableNextColumn()
      if im.BeginCombo("Level", filters.level or "All") then
        im.SetWindowFontScale(0.7)
        if im.Selectable1("All") then
          filters.level = false
        end
        for i=1, #levelIds do
          if im.Selectable1(levelIds[i]) then
            filters.level = levelIds[i]
          end
        end
        im.SetWindowFontScale(1)
        im.EndCombo()
      end
      im.Dummy(im.ImVec2(0,style.ItemSpacing.y))

      im.EndTable()
    end

    if filtersTargetSize ~= 0 then
      filtersTargetSize = im.GetCursorPosY()
    end
    im.EndChild()
  else
    im.Dummy(im.ImVec2(0,filtersExtensionSmoother.state))
  end

  im.SetWindowFontScale(0.8)
  im.PushFont3("cairo_bold")
  local childHeight = im.GetTextLineHeightWithSpacing()+4
  im.PopFont()

  im.BeginChild1("ServerList##NGMPUI", im.ImVec2(im.GetContentRegionAvailWidth(), im.GetContentRegionAvail().y-childHeight-style.ItemSpacing.y), true)
  for k,v in ipairs({"This is a server", "This, too, is a server", "But this server list is not yet designed", "So this is really just filler"}) do
    im.Selectable1(v.."##"..k)
    im.Separator()
  end
  im.EndChild()

  im.PushFont3("cairo_bold")
  ngmp_ui.button("REFRESH", im.ImVec2(im.GetContentRegionAvailWidth(), 0))
  im.PopFont()
end

local function renderTabItem(dt, name, func)
  local hovered = false
  if im.BeginTabItem(name, nil, im.TabItemFlags_None) then
    hovered = im.IsItemHovered()
    im.PopFont()
    func(dt)
    im.PushFont3("cairo_bold")
    im.SetWindowFontScale(0.8)
    im.EndTabItem()
  else
    hovered = im.IsItemHovered()
  end

  if hovered then
    im.SetMouseCursor(im.MouseCursor_Hand)
  end
end

local function render(dt)
  im.SetWindowFontScale(0.8)
  im.PushStyleVar1(im.StyleVar_TabRounding, 5)

  im.PushFont3("cairo_bold")
  if im.BeginTabBar("Connect Tabs") then
    renderTabItem(dt, "Public", renderServerList)
    renderTabItem(dt, "Recent", renderRecent)
    renderTabItem(dt, "Favorites", renderFavorites)
    renderTabItem(dt, "Direct Connect", renderDirectConnect)
    im.EndTabBar()
  end
  im.PopFont()

  im.PopStyleVar()
  im.SetWindowFontScale(1)
end

local function init()
  levelIds = getAllLevelIdentifiers()
end

M.render = render
M.init = init

return M