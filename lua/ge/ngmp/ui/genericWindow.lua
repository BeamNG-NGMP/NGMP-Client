
local C = {}

local im = ui_imgui
local imguiUtils = require('ui/imguiUtils')

local windowSize = im.ImVec2(unpack(ngmp_settings.get("chatSize", {"ui","chat"})))

local keyboardArrow
local pin
local unpin

function C:setCollapsed(bool)
  local style = im.GetStyle()
  if self.isCollapsed and not bool then
    self.windowSize = self.maxSize
  elseif not self.isCollapsed and bool then
    self.windowSize = im.ImVec2(self.collapsedWidth+style.WindowPadding.x, im.GetTextLineHeight()+style.WindowPadding.y*2)
  end
  im.SetWindowSize1(self.windowSize)
  self.isCollapsed = bool
end

function C:render(dt, renderFunc)
  local style = im.GetStyle()
  im.SetNextWindowBgAlpha(0.25)
  im.Begin(self.name.."##NGMPUI", nil,
    im.WindowFlags_NoDocking+
    im.WindowFlags_NoScrollbar+
    im.WindowFlags_NoBringToFrontOnFocus+
    im.WindowFlags_NoTitleBar+
    (self.isCollapsed and im.WindowFlags_NoResize or 0)+
    (self.isPinned and im.WindowFlags_NoMove or 0)
  )

  im.SetWindowFontScale(0.5)
  im.PushFont3("cairo_bold")
  if not self.isPinned and im.IsMouseHoveringRect(im.GetWindowPos(), im.ImVec2(im.GetWindowPos().x+self.maxSize.x, im.GetWindowPos().y+im.GetTextLineHeight()+style.WindowPadding.y*2)) then
    im.SetMouseCursor(im.MouseCursor_ResizeAll)
  end
  local size = im.ImVec2(im.GetTextLineHeight(), im.GetTextLineHeight())
  if pin and unpin then
    im.Image(self.isPinned and unpin.texId or pin.texId, size)
    if im.IsItemHovered() then
      im.SetMouseCursor(im.MouseCursor_Hand)
      if im.IsMouseClicked(0) then
        self.isPinned = not self.isPinned
      end
    end
  elseif ngmp_ui.Button(self.name.."Pin") then
    self.isPinned = not self.isPinned
  end
  im.SameLine()
  if keyboardArrow then
    im.Image(keyboardArrow.texId, size,
      self.isCollapsed and im.ImVec2(0,0) or im.ImVec2(0,1),
      self.isCollapsed and im.ImVec2(1,1) or im.ImVec2(1,0)
    )
    if im.IsItemHovered() then
      im.SetMouseCursor(im.MouseCursor_Hand)
      if im.IsMouseClicked(0) then
        self:setCollapsed(not self.isCollapsed)
      end
    end
  elseif ngmp_ui.Button(self.name.."Collapse") then
    self:setCollapsed(not self.isCollapsed)
  end
  im.SameLine()
  im.SetCursorPosY(im.GetCursorPosY()-ngmp_ui.uiscale*4)
  im.SetWindowFontScale(0.85)
  ngmp_ui.TextU(self.suffix and self.translation.txt.." "..self.suffix.txt or self.translation.txt)
  im.PopFont()
  im.SetWindowFontScale(1)
  im.SameLine()
  self.collapsedWidth = im.GetCursorPosX()
  im.NewLine()

  if self.isCollapsed then
    return
  else
    self.maxSize = im.GetWindowSize()
  end

  renderFunc(dt)

  im.End()
end

function C:init(name, translationId)
  self.isCollapsed = false
  self.isPinned = false

  self.name = name
  self.translation = ngmp_ui_translate(translationId)

  self.maxSize = im.ImVec2(100,100)
  self.collapsedWidth = 100

  -- these are shared variables: BeamNG caches them C++ -side so we can safely do this every window init
  keyboardArrow = FS:fileExists("/art/ngmpui/keyboard_arrow.png") and imguiUtils.texObj("/art/ngmpui/keyboard_arrow.png")
  pin = FS:fileExists("/art/ngmpui/pin.png") and imguiUtils.texObj("/art/ngmpui/pin.png")
  unpin = FS:fileExists("/art/ngmpui/unpin.png") and imguiUtils.texObj("/art/ngmpui/unpin.png")
end

return function(...)
  local o = {}
  setmetatable(o, C)
  C.__index = C
  o:init(...)
  return o
end
