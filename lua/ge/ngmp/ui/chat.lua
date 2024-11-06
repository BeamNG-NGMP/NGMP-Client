
local M = {}

local im = ui_imgui
local imguiUtils = require('ui/imguiUtils')
local chatWindowHandle = rerequire("ngmp/ui/genericWindow")("chatUiConvPublic", "ui.chat.name")
M.dependencies = {"ngmp_main", "ngmp_ui", "ngmp_playerData", "ngmp_settings"}

M.notifications = 0
local playerNames = {
  "Zeit",
  "Name",
  "Another Name"
}

local newMessage = im.ArrayChar(512)
local callbackName = "chatTextCallbackNGMP"
local pingChar = "@"
local isPinging = false
local isPingingAtChar
local refocusText = 0
local refocusTextAtPos = 0

local pingNameSearch = ""
local pingName = 1
local pingNames = playerNames
local maxSize = im.ImVec2(100,100)
local collapsedWidth = 100

local inputCallback = nil

local function renderTextField()
  im.SetWindowFontScale(0.9)
  im.PushFont3("cairo_regular")
  ngmp_ui.TextU("Zeit: ")
  im.PopFont()
  im.SameLine()
  ngmp_ui.TextU("Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.")
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

local function onExtensionLoaded()
  setExtensionUnloadMode(M, "manual")

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
