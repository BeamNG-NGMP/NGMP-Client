
local M = {}

local im = ui_imgui
local imguiUtils = require('ui/imguiUtils')
local chatWindowHandle = rerequire("ngmp/ui/genericWindow")("chatUiConvPublic", "ui.chat.name")
M.dependencies = {"ngmp_main", "ngmp_ui", "ngmp_playerData", "ngmp_settings"}

M.notifications = 0
local newMessage = im.ArrayChar(512)
local newMessageDisplay = im.ArrayChar(512)
local callbackName = "chatTextCallbackNGMP"
local pingChar = "@"
local isPinging = false
local isPingingAtChar
local refocusText = 0
local refocusTextAtPos = 0

local newMessageReceived = false
local keepDown = false
local pingNameSearch
local pingName = 1
local pingNames = {}

local receivedMessages = {}

ffi.cdef("int ImGuiInputTextCallbackLua(const ImGuiInputTextCallbackData* data);")
local inputCallback = nil

local function refreshPlayerSearch()
  pingNames = {}
  for i = 1, #ngmp_playerData.playerData do
    if (ngmp_playerData.playerData[i].name:lower()):match("^"..(pingNameSearch:lower())) then
      pingNames[#pingNames+1] = ngmp_playerData.playerData[i].name
    end
  end
  table.sort(pingNames)
  pingName = 1
end

-- this is the only command that has this feature: all other ones are server side ONLY
local function directMessage(name, steamId)
  local str = ffi.string(newMessage)
  str = str:match("^/msg "..pingChar..".+ (.*)") or str:match("^/r "..pingChar..".+ (.*)") or str
  ffi.copy(newMessage, "/msg "..pingChar..name.." "..str)
end

local function receiveMessage(steamId, msg)
  local ping = msg:match(pingChar.."<"..ngmp_playerData.steamId..">") ~= nil
  for i = 1, #ngmp_playerData.playerData do -- replace to visible data
    msg = msg:gsub(pingChar.."<"..ngmp_playerData.playerData[i].steamId.."> ", pingChar..ngmp_playerData.playerData[i].name.." ")
  end

  table.insert(receivedMessages, 1, {
    isPing = ping,
    player = ngmp_playerData.playerDataById[steamId],
    message = msg,
    msgType = "norm" -- TODO
  })
  newMessageReceived = true
end

local function sendMessage(str)
  local names = {}
  for i = 1, #ngmp_playerData.playerData do   -- escape name for gsub
    names[i] = ngmp_playerData.playerData[i].name:gsub("([^%w])", "%%%1")
  end
  table.sort(names, function(a, b) -- sort the names from longest to smallest (IMPORTANT)
    return #b < #a
  end)

  for i = 1, #names do -- transform final string
    str = str:gsub(pingChar..names[i].." ", pingChar.."<"..ngmp_playerData.playerData[i].steamId.."> ")
  end

  receiveMessage(ngmp_playerData.steamId, str)

  ngmp_network.sendPacket("CM", {data={string_message}})
end

local function inputCallbackFunc(data)
  inputCallback = ffi.cast("ImGuiInputTextCallbackData*", data)

  -- set selection, set cursor pos
  if refocusText == 1 then
    inputCallback.CursorPos = refocusTextAtPos
    inputCallback.SelectionStart = refocusTextAtPos
    inputCallback.SelectionEnd = refocusTextAtPos
    refocusText = 0
  end

  if inputCallback.EventFlag == im.InputTextFlags_CallbackHistory then
    if inputCallback.EventKey == im.Key_UpArrow then
      pingName = math.max(pingName - 1, 0)
    end
    if inputCallback.EventKey == im.Key_DownArrow then
      pingName = math.min(pingName + 1, #pingNames)
    end
  else
    local lastPingName = pingNameSearch
    pingNameSearch = inputCallback.Buf:match(pingChar.."(.*)$") or ""
    if lastPingName ~= pingNameSearch then
      refreshPlayerSearch()
    end

    isPinging = inputCallback.Buf:sub(inputCallback.CursorPos-#pingNameSearch, inputCallback.CursorPos-#pingNameSearch) == pingChar and #pingNames>0
    isPingingAtChar = inputCallback.CursorPos
  end
  return 0
end

local function renderTextField()
  local style = im.GetStyle()
  local setScrollDown = newMessageReceived and (im.GetScrollMaxY() == 0 or im.GetScrollY()/im.GetScrollMaxY() > 0.95)
  im.SetWindowFontScale(0.9)
  for i = #receivedMessages, 1, -1 do
    local msg = receivedMessages[i]
    if msg.isPing then -- this means we need to pre-calc literally everything, unfortunately...
      local topLeft = im.GetCursorScreenPos()
      topLeft.x = topLeft.x - style.ItemSpacing.x
      topLeft.y = topLeft.y - style.ItemSpacing.y

      local bottomRight = im.ImVec2(topLeft.x, topLeft.y)
      bottomRight.x = bottomRight.x + im.GetContentRegionAvailWidth() + style.ItemSpacing.x
      im.PushFont3("cairo_regular")
      local playerNameSize = im.CalcTextSize(msg.player.name..": ").x
      im.PopFont()
      bottomRight.y = bottomRight.y+im.CalcTextSize(msg.message, nil, nil, im.GetContentRegionAvailWidth()-style.ItemSpacing.x*3-playerNameSize).y + style.ItemSpacing.y*2

      im.ImDrawList_AddRectFilled(im.GetWindowDrawList(), topLeft, bottomRight, im.GetColorU321(im.Col_SliderGrabActive, 0.4))
    end

    im.PushFont3("cairo_regular")
    ngmp_ui.TextU(msg.player.name..": ")
    im.PopFont()
    im.SameLine()
    ngmp_ui.TextU(msg.message)
  end
  if setScrollDown then
    im.SetScrollHereY()
    newMessageReceived = false
  end
end

local function render(dt)
  local style = im.GetStyle()
  im.SetWindowFontScale(0.85)
  im.SetNextWindowBgAlpha(0.6)
  im.BeginChild1("ChatContent##NGMPUI", im.ImVec2(im.GetContentRegionAvailWidth(), im.GetContentRegionAvail().y-im.GetTextLineHeightWithSpacing()-style.WindowPadding.y*2), true)
  im.SetWindowFontScale(1)
  im.PushTextWrapPos(im.GetContentRegionAvailWidth())
  renderTextField()
  im.PopTextWrapPos()
  im.EndChild()

  im.SetNextWindowBgAlpha(0.6)
  im.BeginChild1("NewMessage##NGMPUI", im.GetContentRegionAvail(), true, im.WindowFlags_NoScrollbar)
  if refocusText == 2 then -- set focus on text
    im.SetKeyboardFocusHere()
    refocusText = 1
  end

  im.SetWindowFontScale(0.9)
  im.SetNextItemWidth(im.GetContentRegionAvailWidth()- ngmp_ui.calculateButtonSize(ngmp_ui_translate("ui.chat.send")).x-style.ItemSpacing.x*2)
  im.SetWindowFontScale(1)

  local send = im.InputText(
    "##NewMessageInput##NGMPUI",
    newMessage, 512,
    im.InputTextFlags_EnterReturnsTrue + im.InputTextFlags_CallbackHistory + im.InputTextFlags_CallbackAlways,
    ffi.C.ImGuiInputTextCallbackLua, ffi.cast("void*", callbackName)) and not isPinging and refocusText == 0

  if isPinging then
    im.SetNextWindowPos(im.GetCursorScreenPos())
    im.Begin("ChatPingPopup##NGMPUI", nil, im.WindowFlags_NoFocusOnAppearing+im.WindowFlags_Tooltip+im.WindowFlags_NoTitleBar+im.WindowFlags_AlwaysAutoResize)
    im.SetWindowFontScale(0.8)
    for i=1, #pingNames do
      im.Selectable1(pingNames[i], i == pingName)
    end
    im.SetWindowFontScale(1)
    if im.IsKeyPressed(im.Key_Enter) then
      local finalStr = ffi.string(newMessage)
      if not im.IsItemActive() then
        refocusTextAtPos = isPingingAtChar-#pingNameSearch + #pingNames[pingName] + 1
        refocusText = 2
      end

      finalStr = finalStr:sub(1,isPingingAtChar-#pingNameSearch)..pingNames[pingName].." "..finalStr:sub(isPingingAtChar+1)
      ffi.copy(newMessage, finalStr)

      isPinging = false
    end
    im.End()
  end

  im.SameLine()
  im.SetWindowFontScale(0.9)
  if ngmp_ui.primaryButton(ngmp_ui_translate("ui.chat.send")) or send then
    refocusText = 2
    sendMessage(ffi.string(newMessage))
    ffi.copy(newMessage, "")
  end
  im.SetWindowFontScale(1)
  im.EndChild()
end

local function onNGMPUI(dt)
  if M.notifications > 0 then
    chatWindowHandle.suffix = ngmp_ui_translate("ui.chat.notifications", {count = M.notifications})
  else
    chatWindowHandle.suffix = nil
  end

  im.SetNextWindowBgAlpha(0.25)
  chatWindowHandle:render(dt, render)
end

local function onNGMPSettingsChanged()
  chatWindowHandle.transparency = ngmp_settings.get("windowTransparency", {"ui","generic"})
end

local function onExtensionLoaded()
  setExtensionUnloadMode(M, "manual")

  rawset(_G, callbackName, inputCallbackFunc)
end

M.receiveMessage = receiveMessage
M.directMessage = directMessage

M.onExtensionLoaded = onExtensionLoaded
M.onNGMPUI = onNGMPUI
M.onNGMPSettingsChanged = onNGMPSettingsChanged


return M
