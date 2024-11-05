
local M = {}

local im = ui_imgui
local imguiUtils = require('ui/imguiUtils')
M.dependencies = {"ngmp_main", "ngmp_ui", "ngmp_playerData", "ngmp_settings"}

M.notifications = 0
local playerNames = {
  "Zeit",
  "Name",
  "Another Name"
}

local windowSize = im.ImVec2(unpack(ngmp_settings.get("chatSize", {"ui","chat"})))

local newMessage = im.ArrayChar(512)
local callbackName = "chatTextCallbackNGMP"
local pingChar = "@"
local isPinging = false
local isPingingAtChar
local refocusText = 0
local refocusTextAtPos = 0

local isCollapsed = false
local isPinned = false

local pingNameSearch = ""
local pingName = 1
local pingNames = playerNames
local maxSize = im.ImVec2(100,100)
local collapsedWidth = 100

local inputCallback = nil

local keyboardArrow
local pin
local unpin

local function renderPlayers()
  im.Text("Players")
  im.Separator()
  if ngmp_playerData.getOwnData() then
    ngmp_playerData.renderData(ngmp_playerData.getOwnData())
  end
end

local function renderTextField()
  im.SetWindowFontScale(0.9)
  im.PushFont3("cairo_regular")
  im.Text("Zeit: ")
  im.PopFont()
  im.SameLine()
  im.Text("Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.")
end

local function setCollapsed(bool)
  local style = im.GetStyle()
  if isCollapsed and not bool then
    local newSize = im.GetWindowSize()
    windowSize = im.ImVec2(unpack(ngmp_settings.get("chatSize", {"ui","chat"})))
    im.SetWindowSize1(windowSize)
  elseif not isCollapsed and bool then
    local newSize = im.GetWindowSize()
    ngmp_settings.set("chatSize", {newSize.x, newSize.y}, {"ui","chat"})
    windowSize = im.ImVec2(collapsedWidth+style.WindowPadding.x, im.GetTextLineHeight()+style.WindowPadding.y*2)
  end
  isCollapsed = bool
end

local function onNGMPUI(dt)
  local style = im.GetStyle()
  im.SetNextWindowBgAlpha(0.25)
  im.Begin("Chat##NGMPUI", nil,
    im.WindowFlags_NoDocking+
    im.WindowFlags_NoScrollbar+
    im.WindowFlags_NoBringToFrontOnFocus+
    im.WindowFlags_NoTitleBar+
    (isCollapsed and im.WindowFlags_NoResize or 0)+
    (isPinned and im.WindowFlags_NoMove or 0)
  )

  im.SetWindowFontScale(0.5)
  im.PushFont3("cairo_bold")
  if not isPinned and im.IsMouseHoveringRect(im.GetWindowPos(), im.ImVec2(im.GetWindowPos().x+maxSize.x, im.GetWindowPos().y+im.GetTextLineHeight()+style.WindowPadding.y*2)) then
    im.SetMouseCursor(im.MouseCursor_ResizeAll)
  end
  local size = im.ImVec2(im.GetTextLineHeight(), im.GetTextLineHeight())
  if pin and unpin then
    im.Image(isPinned and unpin.texId or pin.texId, size)
    if im.IsItemHovered() then
      im.SetMouseCursor(im.MouseCursor_Hand)
      if im.IsMouseClicked(0) then
        isPinned = not isPinned
      end
    end
  elseif ngmp_ui.Button("Pin") then
    isPinned = not isPinned
  end
  im.SameLine()
  if keyboardArrow then
    im.Image(keyboardArrow.texId, size,
      isCollapsed and im.ImVec2(0,0) or im.ImVec2(0,1),
      isCollapsed and im.ImVec2(1,1) or im.ImVec2(1,0)
    )
    if im.IsItemHovered() then
      im.SetMouseCursor(im.MouseCursor_Hand)
      if im.IsMouseClicked(0) then
        setCollapsed(not isCollapsed)
      end
    end
  elseif ngmp_ui.Button("Collapse") then
    setCollapsed(not isCollapsed)
  end
  im.SameLine()
  im.SetCursorPosY(im.GetCursorPosY()-ngmp_ui.uiscale*4)
  im.SetWindowFontScale(0.85)
  im.Text(ngmp_ui_translate("ui.chat.name"))
  if M.notifications > 0 then
    im.SameLine()
    im.SetCursorPosY(im.GetCursorPosY()-ngmp_ui.uiscale*4)
    im.Text(ngmp_ui_translate("ui.chat.notifications", {count = #M.notifications}))
  end
  im.PopFont()
  im.SetWindowFontScale(1)
  im.SameLine()
  collapsedWidth = im.GetCursorPosX()
  im.NewLine()

  if isCollapsed then
    im.SetWindowSize1(windowSize)
    return
  end

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
  if refocusText == 2 then
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
    ffi.copy(newMessage, "")
  end
  im.SetWindowFontScale(1)
  im.EndChild()

  im.SetWindowFontScale(1)
  im.End()
end

local function onExtensionLoaded()
  setExtensionUnloadMode(M, "manual")

  keyboardArrow = FS:fileExists("/art/ngmpui/keyboard_arrow.png") and imguiUtils.texObj("/art/ngmpui/keyboard_arrow.png")
  pin = FS:fileExists("/art/ngmpui/pin.png") and imguiUtils.texObj("/art/ngmpui/pin.png")
  unpin = FS:fileExists("/art/ngmpui/unpin.png") and imguiUtils.texObj("/art/ngmpui/unpin.png")
  rawset(_G, callbackName, function(data)
    inputCallback = ffi.cast("ImGuiInputTextCallbackData*", data)

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
      pingNameSearch = inputCallback.Buf:match(pingChar.."(%w*)$") or ""

      isPinging = inputCallback.Buf:sub(inputCallback.CursorPos-#pingNameSearch, inputCallback.CursorPos-#pingNameSearch) == pingChar and #pingNames>0
      isPingingAtChar = inputCallback.CursorPos

      if lastPingName ~= pingNameSearch then
        pingNames = {}
        for i = 1, #playerNames do
          if (playerNames[i]:lower()):match("^"..(pingNameSearch:lower())) then
            pingNames[#pingNames+1] = playerNames[i]
          end
        end
        pingName = 1
      end
    end
    return 0
  end)
end

M.onExtensionLoaded = onExtensionLoaded
M.onNGMPUI = onNGMPUI

return M
