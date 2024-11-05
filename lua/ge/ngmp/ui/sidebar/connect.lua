

local M = {
  name = "Connect",
  author = "DaddelZeit (NGMP Official)"
}

local im = ui_imgui

local ngmpUtils = rerequire("ngmp/utils")
local imguiUtils = require("ui/imguiUtils")

local star
local unstar
local no_server

local sync
local err

local directConnectTargetSize = 1
local directConnectExtensionSmoother = newTemporalSigmoidSmoothing(950, 750)
local directConnectIp = im.ArrayChar(128)
local directConnectPort = im.ArrayChar(128)

local filtersTargetSize = 1
local filtersExtensionSmoother = newTemporalSigmoidSmoothing(950, 750)
local searchQuery = im.ArrayChar(128)
local filtersChanged = false
local filters = {
  searchQuery = "",
  empty = false,
  notEmpty = false,
  notFull = false,
  level = false,
  favorite = false,
}
local servers, serverKeys = ngmp_serverList.filter({})
local connectButtonTimer = 0

local function search()
end

local function filterCheckbox(name, val)
  local temp = im.BoolPtr(val or false)
  return im.Checkbox(name, temp)
end

local function connectButton(dt, ip, execFunc)
  local buttonHeight = im.GetTextLineHeight()*2
  local imgSize = im.ImVec2(buttonHeight*0.75, buttonHeight*0.75)

  local text = ngmp_network.serverConnection.ip == ip and ngmp_ui_translate("ui.sidebar.tabs.connect.reconnect") or ngmp_ui_translate("ui.sidebar.tabs.connect.connect")
  local disableButton = false
  if not ngmp_network.serverConnection.connected and ngmp_network.serverConnection.ip == ip then
    local prevCursorPosY = im.GetCursorPosY()
    if ngmp_network.serverConnection.err ~= "" then
      im.SetCursorPosY(prevCursorPosY+(buttonHeight-imgSize.y)/2)
      im.Image(err.texId, imgSize)
      if im.IsItemHovered() then
        im.SetTooltip(ngmp_network.serverConnection.err)
      end
      im.SameLine()
      text = ngmp_ui_translate("ui.sidebar.generic.input.retry")
    else
      connectButtonTimer = (connectButtonTimer+dt*10)%(math.pi*4)
      im.SetCursorPosY(prevCursorPosY+(buttonHeight-imgSize.y)/2)
      ngmp_ui.ImageRotated(im.GetWindowDrawList(), sync.texId, imgSize, connectButtonTimer, ngmp_ui.uv2D, ngmp_ui.uv1D, ngmp_ui.uv4D, ngmp_ui.uv3D)
      im.SameLine()
      text = ngmp_ui_translate("ui.sidebar.tabs.connect.connecting")
      disableButton = true
    end
    im.SetCursorPosY(prevCursorPosY)
  end
  im.PushFont3("cairo_bold")
  if disableButton then im.BeginDisabled() end
  if ngmp_ui.primaryButton(text, im.ImVec2(im.GetContentRegionAvailWidth(), buttonHeight)) then
    execFunc()
  end
  if disableButton then im.EndDisabled() end
  im.PopFont("cairo_bold")
end

local function renderDirectConnect(dt)
  local style = im.GetStyle()
  if directConnectExtensionSmoother:get(directConnectTargetSize, dt) >= 0.5 then
    im.BeginChild1("ServerListFilters##NGMPUI", im.ImVec2(im.GetContentRegionAvailWidth(), math.ceil(directConnectExtensionSmoother.state)), true, im.WindowFlags_NoScrollbar)
    im.SetWindowFontScale(1)

    im.Text(ngmp_ui_translate("ui.sidebar.tabs.connect.direct.ipaddress"))
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

    im.Text(ngmp_ui_translate("ui.sidebar.tabs.connect.direct.port"))
    im.SameLine()
    im.SetNextItemWidth(im.GetContentRegionAvailWidth())
    cursorPos = im.GetCursorPos()
    im.InputText("##DirectConnectPort", directConnectPort, 128)
    if not im.IsItemActive() and directConnectPort[0] == 0 then
      local postCursorPos = im.GetCursorPos()
      im.SetCursorPosX(cursorPos.x+5)
      im.SetCursorPosY(cursorPos.y)
      im.BeginDisabled()
      im.Text("42630")
      im.EndDisabled()
      im.SetCursorPos(postCursorPos)
    end

    if ngmp_ui.button(ngmp_ui_translate("ui.sidebar.tabs.connect.direct.clipboard"), im.ImVec2(im.GetContentRegionAvailWidth(), 0)) then
      local ip, port = ngmpUtils.splitIP(getClipboard())
      ffi.copy(directConnectIp, ip or "")
      ffi.copy(directConnectPort, port or "")
    end
    im.Dummy(im.ImVec2(0,style.ItemSpacing.y))
    local finalIp = ngmpUtils.buildIP(ffi.string(directConnectIp), ffi.string(directConnectPort))
    connectButton(dt, finalIp, function()
      ngmp_network.sendPacket("HJ", {data = {ffi.string(directConnectIp), ffi.string(directConnectPort)}})
      ngmp_settings.set("directconnectIP", ffi.string(directConnectIp), {"ui", "sidebar"})
      ngmp_settings.set("directconnectPort", ffi.string(directConnectPort), {"ui", "sidebar"})
    end)

    im.Dummy(im.ImVec2(0,style.ItemSpacing.y))
    if directConnectTargetSize ~= 0 then
      directConnectTargetSize = im.GetCursorPosY()
    end
    im.EndChild()
  else
    im.Dummy(im.ImVec2(0,directConnectExtensionSmoother.state))
  end
end

local function renderServerlist(dt)
  local style = im.GetStyle()
  im.SetNextItemWidth(im.GetContentRegionAvailWidth())

  local cursorPos = im.GetCursorPos()
  if im.InputText("##search", searchQuery) then
    search()
  end
  if not im.IsItemActive() and searchQuery[0] == 0 then
    local postCursorPos = im.GetCursorPos()
    im.SetCursorPosX(cursorPos.x+5)
    im.SetCursorPosY(cursorPos.y)
    im.BeginDisabled()
    im.Text(ngmp_ui_translate("ui.sidebar.generic.input.search"))
    im.EndDisabled()
    im.SetCursorPos(postCursorPos)
  end

  if filtersExtensionSmoother:get(filtersTargetSize, dt) >= 0.5 then
    im.SetWindowFontScale(0.8)

    im.BeginChild1("ServerListFilters##NGMPUI", im.ImVec2(im.GetContentRegionAvailWidth(), math.ceil(filtersExtensionSmoother.state)), true, im.WindowFlags_NoScrollbar)
    im.Text(ngmp_ui_translate("ui.sidebar.tabs.connect.filter"))
    im.Separator()
    if im.BeginTable("ServerListFiltersOptions##NGMPUI", 2) then
      im.TableNextColumn()
      if filterCheckbox(ngmp_ui_translate("ui.sidebar.tabs.connect.filter.empty"), filters.empty) then
        filters.empty = not filters.empty
        filtersChanged = true
      end
      im.TableNextColumn()
      if filterCheckbox(ngmp_ui_translate("ui.sidebar.tabs.connect.filter.notempty"), filters.notEmpty) then
        filters.notEmpty = not filters.notEmpty
        filtersChanged = true
      end
      im.TableNextColumn()
      if filterCheckbox(ngmp_ui_translate("ui.sidebar.tabs.connect.filter.notfull"), filters.notFull) then
        filters.notFull = not filters.notFull
        filtersChanged = true
      end
      im.TableNextColumn()
      if im.BeginCombo(ngmp_ui_translate("ui.sidebar.tabs.connect.filter.level"), filters.level or ngmp_ui_translate("ui.sidebar.tabs.connect.filter.levelall")) then
        im.SetWindowFontScale(0.7)
        if ngmp_ui.Selectable1(ngmp_ui_translate("ui.sidebar.tabs.connect.filter.levelall")) then
          filters.level = false
          filtersChanged = true
        end
        for i=1, #ngmp_serverList.availableLevels do
          if ngmp_ui.Selectable1(ngmp_serverList.availableLevels[i][1]) then
            filters.level = ngmp_serverList.availableLevels[i][1]
            filtersChanged = true
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
  if #serverKeys == 0 then
    local center = im.ImVec2(im.GetContentRegionAvailWidth()/2, im.GetContentRegionAvail().y/2)
    im.SetCursorPos(center)

    im.PushFont3("cairo_regular_medium")
    im.SetWindowFontScale(1.75)
    im.SetCursorPosX(center.x-im.CalcTextSize(ngmp_ui_translate("ui.sidebar.generic.fuckup")).x/2)
    im.SetCursorPosY(im.GetCursorPosY()-im.GetTextLineHeightWithSpacing()*1.8)
    im.Text(ngmp_ui_translate("ui.sidebar.generic.fuckup"))
    im.SetWindowFontScale(1)
    im.PopFont()

    if no_server then
      local sizeFac = ngmp_ui.getPercentVecX(4, false, true)/no_server.size.x
      local size = ngmp_ui.mulVec2Num(no_server.size, sizeFac)
      im.SetCursorPosX(center.x-size.x/2)
      im.SetCursorPosY(center.y-size.y/2-im.GetTextLineHeight()*0.8)

      im.Image(no_server.texId, size)
    end

    im.SetCursorPosX(center.x-im.CalcTextSize(ngmp_ui_translate("ui.sidebar.tabs.connect.serverlist.empty")).x/2)
    im.Text(ngmp_ui_translate("ui.sidebar.tabs.connect.serverlist.empty"))
    im.SetCursorPosX(center.x-im.CalcTextSize(ngmp_ui_translate("ui.sidebar.tabs.connect.serverlist.empty1")).x/2)
    im.Text(ngmp_ui_translate("ui.sidebar.tabs.connect.serverlist.empty1"))
  end
  for i = 1, #serverKeys do
    local key = serverKeys[i]
    local server = servers[key]
    local xWidth = im.GetContentRegionAvailWidth()
    im.PushTextWrapPos(xWidth)
    im.SetWindowFontScale(1.3)
    im.PushFont3("cairo_bold")
    local extended
    local playerCountStr = ngmp_ui_translate("ui.sidebar.tabs.connect.serverInfo.playerCount", {players = #server.players, maxplayers = server.max_players})
    do
      extended = im.TreeNodeEx1(server.name.."##NGMPUI"..i, im.ImGuiTreeNodeFlags_SpanAvailWidth)
      if im.IsItemHovered() then
        im.SetMouseCursor(im.MouseCursor_Hand)
      end

      im.SameLine()
      im.SetCursorPosX(xWidth-im.CalcTextSize(playerCountStr).x-im.GetTextLineHeight()*0.7)
      im.Text(playerCountStr)
      im.SameLine()
      if star and unstar then
        local yOffset = im.GetTextLineHeight()*0.3/2
        im.SetCursorPosY(im.GetCursorPosY()+yOffset)
        if ngmp_serverList.favorites[key] then
          im.Image(star.texId, im.ImVec2(im.GetTextLineHeight()*0.7, im.GetTextLineHeight()*0.7), nil, nil, ngmp_ui.bngCol)
        else
          im.Image(unstar.texId, im.ImVec2(im.GetTextLineHeight()*0.7, im.GetTextLineHeight()*0.7))
        end
        if im.IsItemHovered() then
          im.SetMouseCursor(im.MouseCursor_Hand)
          if im.IsMouseClicked(0) then
            ngmp_serverList.setFavorite(key, not ngmp_serverList.favorites[key])
          end
        end
      end
    end
    im.PopFont()
    im.SetWindowFontScale(1)

    if extended then
      im.Unindent()
      im.PushFont3("notosans_sc_regular")
      if im.BeginTable("ServerView##NGMPUI"..key, 1, im.TableFlags_RowBg+im.TableFlags_BordersOuter+im.TableFlags_SizingFixedSame, im.ImVec2(im.GetContentRegionAvailWidth(), 0)) then
        im.TableNextColumn()
        im.SetWindowFontScale(1.1)
        im.Text(server.description)
        im.SetWindowFontScale(1)
        im.Dummy(im.ImVec2(0,0))
        im.TableNextColumn()
        im.Text(ngmp_ui_translate("ui.sidebar.tabs.connect.serverInfo.categories", {categories = table.concat(server.categories, ", ")}))
        im.TableNextColumn()
        im.Text(ngmp_ui_translate("ui.sidebar.tabs.connect.serverInfo.players", {playercount = playerCountStr, playerslist = table.concat(server.players, ", ")}))
        im.TableNextColumn()
        im.Text(ngmp_ui_translate("ui.sidebar.tabs.connect.serverInfo.level", {level = server.level:match("/levels/(.*)/")}))
        im.TableNextColumn()
        im.Text(ngmp_ui_translate("ui.sidebar.tabs.connect.serverInfo.host", {author = server.author}))
        im.EndTable()
      end
      im.PopFont()

      local finalIp = ngmpUtils.buildIP(key:match("^(.+):(%d+)$"))
      connectButton(dt, finalIp, function()
        ngmp_network.sendPacket("HJ", {data = {key:match("^(.+):(%d+)$")}})
      end)

      im.Indent()
      im.TreePop()
    end
    im.PopTextWrapPos()
    im.Separator()
  end
  im.EndChild()

  im.PushFont3("cairo_bold")
  ngmp_ui.button(ngmp_ui_translate("ui.sidebar.tabs.connect.serverlist.reload"), im.ImVec2(im.GetContentRegionAvailWidth(), 0))
  im.PopFont()
end

local function renderRecent(dt, activated)
  if activated then
    filters.favorite = false
    filtersChanged = true
  end
  renderServerlist(dt)

  if filtersChanged then
    servers, serverKeys = ngmp_serverList.filter(filters, "time")
    filtersChanged = false
  end
end

local function renderFavorites(dt, activated)
  if activated then
    filters.favorite = true
    filtersChanged = true
  end
  renderServerlist(dt)

  if filtersChanged then
    servers, serverKeys = ngmp_serverList.filter(filters)
    filtersChanged = false
  end
end

local function renderPublic(dt, activated)
  if activated then
    filters.favorite = false
    filtersChanged = true
  end
  renderServerlist(dt)

  if filtersChanged then
    servers, serverKeys = ngmp_serverList.filter(filters)
    filtersChanged = false
  end
end

local lastTab = ""
local function renderTabItem(dt, name, func)
  local hovered = false
  if im.BeginTabItem(name, nil, im.TabItemFlags_None) then
    hovered = im.IsItemHovered()
    im.PopFont()
    func(dt, lastTab ~= name)
    im.PushFont3("cairo_bold")
    im.SetWindowFontScale(0.8)
    im.EndTabItem()
    lastTab = name
  else
    hovered = im.IsItemHovered()
  end

  if hovered then
    im.SetMouseCursor(im.MouseCursor_Hand)
  end
end

local function render(dt)
  local style = im.GetStyle()
  im.SetWindowFontScale(0.8)
  im.PushStyleVar1(im.StyleVar_TabRounding, 5)

  local playerData = ngmp_playerData.getOwnData()
  local avatar = ngmp_playerData.getAvatar(playerData.avatarHash)
  if avatar then
    local sizeFac = ngmp_ui.getPercentVecX(1, false, true)/avatar.size.x
    local size = ngmp_ui.mulVec2Num(avatar.size, sizeFac)

    im.BeginChild1("ProfilePreview##NGMPUI", im.ImVec2(im.GetContentRegionAvailWidth(), size.y+style.WindowPadding.y*2), true, im.WindowFlags_NoScrollbar)
    im.BeginGroup()
    im.Image(avatar.texId, size)
    im.SameLine()
    im.SetCursorPosX(im.GetCursorPosX()+style.WindowPadding.x)
    im.PushFont3("cairo_bold")
    im.Text(playerData.name)
    im.PopFont()
    im.EndGroup()
    if im.IsItemHovered() then
      ngmp_playerData.renderTooltip(playerData.steamId)
    end
    im.EndChild()
  end

  im.PushFont3("cairo_bold")
  if im.BeginTabBar("Connect Tabs") then
    renderTabItem(dt, ngmp_ui_translate("ui.sidebar.tabs.connect.tab.public"), renderPublic)
    renderTabItem(dt, ngmp_ui_translate("ui.sidebar.tabs.connect.tab.recent"), renderRecent)
    renderTabItem(dt, ngmp_ui_translate("ui.sidebar.tabs.connect.tab.favorites"), renderFavorites)
    renderTabItem(dt, ngmp_ui_translate("ui.sidebar.tabs.connect.tab.direct"), renderDirectConnect)
    im.EndTabBar()
  end
  im.PopFont()

  im.PopStyleVar()
  im.SetWindowFontScale(1)
end

local function init()
  star = FS:fileExists("/art/ngmpui/star_fill.png") and imguiUtils.texObj("/art/ngmpui/star_fill.png")
  unstar = FS:fileExists("/art/ngmpui/star.png") and imguiUtils.texObj("/art/ngmpui/star.png")
  no_server = FS:fileExists("/art/ngmpui/tune.png") and imguiUtils.texObj("/art/ngmpui/tune.png")

  sync = FS:fileExists("/art/ngmpui/sync.png") and imguiUtils.texObj("/art/ngmpui/sync.png")
  err = FS:fileExists("/art/ngmpui/error.png") and imguiUtils.texObj("/art/ngmpui/error.png")

  ffi.copy(directConnectIp, ngmp_settings.get("directconnectIP", {"ui", "sidebar"}))
  ffi.copy(directConnectPort, ngmp_settings.get("directconnectPort", {"ui", "sidebar"}))
end

M.render = render
M.init = init

return M
