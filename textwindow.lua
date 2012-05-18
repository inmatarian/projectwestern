
TextWindow = Object:clone {
  defaultChar = 0,
  x = 0, y = 0,
  width = 5, height = 5,
  priority = 0,
  visible = true,
  foreground = Color.WHITE,
  background = Color.BLACK
}

local maxWidth, maxHeight = floor(Graphics.gameWidth/8), floor(Graphics.gameHeight/8)

function TextWindow:init(x, y, w, h, priority, defaultChar)
  if w then self.width = w end
  if h then self.height = h end

  if x == "center" then
    self.x = floor((maxWidth-self.width)/2)
  elseif type(x)=="number" then
    self.x = (x >= 0) and x or maxWidth+x
  end
  if y == "center" then
    self.y = floor((maxHeight-self.height)/2)
  elseif type(y)=="number" then
    self.y = (y >= 0) and y or maxHeight+y
  end

  if priority then self.priority = priority end
  if defaultChar then self.defaultChar = defaultChar end
  local size = self.width * self.height
  self.grid = Util.array( size, self.defaultChar )
  self.forecolor = Util.array( size, self.foreground )
  self.backcolor = Util.array( size, self.background )
  return self
end

function TextWindow:setColor( c, b )
  if c then self.foreground = c end
  if b then self.background = b end
  return self
end

function TextWindow:reset()
  self.foreground = self:super().foreground
  self.background = self:super().background
  return self
end

function TextWindow:set(x, y, t, c, b)
  c, b = c or self.foreground, b or self.background
  if (y >= 0) and (y < self.height) and (x >= 0) and (x < self.width) then
    local pos = 1+(y*self.width+x)
    if t then self.grid[pos] = t end
    if c then self.forecolor[pos] = c end
    if b then self.backcolor[pos] = b end
  end
  return self
end

function TextWindow:get(x, y)
  if (y >= 0) and (y < self.height) and (x >= 0) and (x < self.width) then
    local pos = 1+(y*self.width+x)
    return self.grid[pos], self.forecolor[pos], self.backcolor[pos]
  end
end

function TextWindow:printf(x, y, s, ...)
  local c, b = self.foreground, self.background
  local s = s:format(...)
  local i = 0
  for ch in s:gmatch(".") do
    if ch == '\n' then
      i, y = 0, y+1
    else
      self:set( x+i, y, string.byte(ch), c, b )
      i = i + 1
    end
  end
  return self
end

function TextWindow:fill( t, c, b )
  c, b = c or self.foreground, b or self.background
  for x = 0, self.width-1 do
    for y = 0, self.height-1 do
      self:set( x, y, t, c, b )
    end
  end
  return self
end

TextWindow.frameStyles = {
  single = {
    tl = ASCII.Box_drawings_light_down_and_right,
    tr = ASCII.Box_drawings_light_down_and_left,
    bl = ASCII.Box_drawings_light_up_and_right,
    br = ASCII.Box_drawings_light_up_and_left,
    l = ASCII.Box_drawings_light_vertical,
    r = ASCII.Box_drawings_light_vertical,
    u = ASCII.Box_drawings_light_horizontal,
    d = ASCII.Box_drawings_light_horizontal,
    horiz = ASCII.Box_drawings_light_horizontal,
    vert = ASCII.Box_drawings_light_vertical,
    right = ASCII.Box_drawings_light_vertical_and_left,
    left = ASCII.Box_drawings_light_vertical_and_right,
    bottom = ASCII.Box_drawings_light_up_and_horizontal,
    top = ASCII.Box_drawings_light_down_and_horizontal,
  };
  double = {
    tl = ASCII.Box_drawings_double_down_and_right,
    tr = ASCII.Box_drawings_double_down_and_left,
    bl = ASCII.Box_drawings_double_up_and_right,
    br = ASCII.Box_drawings_double_up_and_left,
    l = ASCII.Box_drawings_double_vertical,
    r = ASCII.Box_drawings_double_vertical,
    u = ASCII.Box_drawings_double_horizontal,
    d = ASCII.Box_drawings_double_horizontal,
    horiz = ASCII.Box_drawings_double_horizontal,
    vert = ASCII.Box_drawings_double_vertical,
    right = ASCII.Box_drawings_double_vertical_and_left,
    left = ASCII.Box_drawings_double_vertical_and_right,
    bottom = ASCII.Box_drawings_double_up_and_horizontal,
    top = ASCII.Box_drawings_double_down_and_horizontal,
  }
}

function TextWindow:frame( style, color, back )
  local t = self.frameStyles[style] or self.frameStyles.single
  local w, h = self.width, self.height
  color = color or self.foreground
  back = back or self.background
  for i = 1, w-2 do
    self:set( i,   0, t.u, color, back )
    self:set( i, h-1, t.d, color, back )
  end
  for i = 1, h-2 do
    self:set(  0, i, t.l, color, back )
    self:set( w-1, i, t.r, color, back )
  end
  self:set( 0, 0, t.tl, color, back )
  self:set( w-1, 0, t.tr, color, back )
  self:set( 0, h-1, t.bl, color, back )
  self:set( w-1, h-1, t.br, color, back )
  return self
end

function TextWindow:horizLine( style, x, y, w )
  local t = self.frameStyles[style] or self.frameStyles.single
  local color, back = self.foreground, self.background
  for i = x+1, x+w-2 do
    self:set( i, y, t.horiz, color, back )
  end
  self:set( x, y, t.left, color, back )
  self:set( x+w-1, y, t.right, color, back )
  return self
end

function TextWindow:vertLine( style, x, y, h )
  local t = self.frameStyles[style] or self.frameStyles.single
  local color, back = self.foreground, self.background
  for i = y+1, y+h-2 do
    self:set( x, i, t.vert, color, back )
  end
  self:set( x, y, t.top, color, back )
  self:set( x, y+h-1, t.bottom, color, back )
  return self
end

TextWindow.update = NULLFUNC

function TextWindow:draw(dt)
  if not self.visible then return end
  local x, y = self.x, self.y
  local w, h = self.width, self.height
  Graphics:setClipping( x*8, y*8, w*8, h*8 )
  for yy = 0, h-1 do
    for xx = 0, w-1 do
      local t, c, b = self:get(xx, yy)
      t = t or self.defaultChar
      if t ~= 0 then
        Graphics:drawChar(x+xx, y+yy, t or 0, c or Color.BLACK, b or Color.BLACK)
      end
    end
  end
end

--------------------------------------------------------------------------------

ScrollingWindow = TextWindow:clone {
  row = 0,
  column = 0,
  defaultChar = string.byte(' ')
}

function ScrollingWindow:rawText(s)
  local x, y = self.column, self.row
  local c, b = self.foreground, self.background
  for ch in tostring(s):gmatch(".") do
    if y >= self.height then
      for yy = 1, self.height-1 do
        for xx = 0, self.width-1 do
          local tt, cc, bb = self:get( xx, yy )
          self:set( xx, yy-1, tt, cc, bb )
        end
      end
      for xx = 0, self.width-1 do
        self:set( xx, self.height-1, 0, c, b )
      end
      y = self.height-1
    end
    if ch == '\n' then
      x, y = 0, y+1
    else
      self:set( x, y, string.byte(ch), c, b )
      x = x + 1
    end
    if x >= self.width then
      x, y = 0, y+1
    end
    self.column, self.row = x, y
  end
end

function ScrollingWindow:write(...)
  for i = 1, select('#', ...) do
    if i ~= 1 then self:rawText(' ') end
    local str = select(i, ...)
    self:rawText(str)
  end
  return self
end

function ScrollingWindow:writeln(...)
  return self:write(...):write( "\n" )
end

--------------------------------------------------------------------------------

SelectionMixin = {

  initSelection = function(self, max, columns, rows)
    self.selectionOption = 1
    self.selectionFirst = 1
    self.selectionColumns = columns or 1
    self.selectionRows = rows or max
    self.selectionMax = max
    return self
  end,

  handleSelectionUpdate = function(self, dt)
    local dist = 0
    local col = self.selectionColumns
    if Input.tap.up then dist = -col
    elseif Input.tap.down then dist = col
    elseif Input.tap.left then dist = -1
    elseif Input.tap.right then dist = 1
    elseif Input.tap.pageup then dist = -(self.selectionRows-1) * col
    elseif Input.tap.pagedown then dist = (self.selectionRows-1) * col
    elseif Input.tap.home then dist = -9001
    elseif Input.tap["end"] then dist = 9001
    elseif Input.tap.enter then
      self:selected( self.selectionOption )
    end
    if dist ~= 0 then
      self.selectionOption = bound(1, self.selectionOption+dist, self.selectionMax)
      if self.selectionOption > (self.selectionFirst+self.selectionRows-1) then
        self.selectionFirst = self.selectionOption - self.selectionRows+1
      elseif self.selectionOption < self.selectionFirst then
        self.selectionFirst = self.selectionOption
      end
      self:refresh()
    end
    return self
  end
}

--------------------------------------------------------------------------------

WindowWidget = TextWindow:clone {
  defaultChar = ASCII.Space,
}

function WindowWidget:init( x, y, parent )
  WindowWidget:superinit(self, x, y)
  self.parent = parent
  self.focused = false
  self:refresh()
  return self
end

function WindowWidget:pushMenu( menu )
  self.parent:pushMenu(menu)
  return self
end

function WindowWidget:popMenu()
  self.parent:popMenu()
  return self
end

function WindowWidget:refreshAll()
  self.parent:refresh()
  self:refresh()
  return self
end

function WindowWidget:loseFocus()
  self.focused = false
  self:refresh()
  return self
end

function WindowWidget:gainFocus()
  self.focused = true
  self:refresh()
  return self
end

--------------------------------------------------------------------------------

MenuListWidget = WindowWidget:clone {
  priority = 2,
  options = { "Return" }
}

MenuListWidget:mixin( SelectionMixin )

function MenuListWidget:init(x, y, parent, signal)
  self.signal = signal
  self:initSelection( #self.options )
  self:recalculateSize()
  return MenuListWidget:superinit(self, x, y, parent)
end

function MenuListWidget:recalculateSize()
  self.height = 2 + #self.options
  self.width = 0
  for _, opt in ipairs(self.options) do
    self.width = math.max( self.width, 3 + #opt )
  end
  if self.title then
    self.height = self.height + 2
    self.width = math.max( self.width, 2 + #self.title )
  end
  return self
end

function MenuListWidget:refresh()
  self:reset()
      :fill(ASCII.Space)
      :frame('single')

  local startLine = 0
  if self.title then
    self:printf(1, 1, self.title)
    self:horizLine('single', 0, 2, self.width)
    startLine = 2
  end

  for i, opt in ipairs(self.options) do
    local back = (i==self.selectionOption) and Color.MIDNIGHT or Color.BLACK
    self:setColor(Color.WHITE, back):printf(2, startLine + i, opt)
  end

  if self.firstPick then
    self:setColor(Color.WHITE, Color.BLACK)
        :set(1, startLine + self.firstPick, ASCII.Right_fat_arrow)
        :setColor(Color.YELLOW, Color.BLACK)
        :set(1, startLine + self.selectionOption, ASCII.Right_fat_arrow)
  else
    self:setColor(Color.WHITE, Color.BLACK)
        :set(1, startLine + self.selectionOption, ASCII.Right_fat_arrow)
  end

  return self
end

function MenuListWidget:update(dt)
  self:handleSelectionUpdate(dt)
end

function MenuListWidget:selected( index )
  self.signal( index, self.options[index] )
end

--------------------------------------------------------------------------------

MenuStackMixin = {

  initMenuStack = function( self )
    self.menuStack = {}
  end,

  pushMenu = function( self, menu )
    local N = #self.menuStack
    if N > 0 then self.menuStack[N]:loseFocus() end
    table.insert(self.menuStack, menu)
    self:addLayer(menu)
    self.menuStack[N+1]:gainFocus()
    return self
  end,

  popMenu = function( self )
    local N = #self.menuStack
    self.menuStack[N]:loseFocus()
    local menu = table.remove(self.menuStack)
    self:removeLayer(menu)
    if N > 1 then self.menuStack[N-1]:gainFocus() end
    return self
  end,

  popAllMenus = function( self, stop )
    local i, N = 1, #self.menuStack
    if stop then
      while i <= N do
        if self.menuStack[i] == stop then i = i + 1; break end
        i = i + 1
      end
    end
    while N >= i do
      self.menuStack[N]:loseFocus()
      local menu = table.remove(self.menuStack)
      self:removeLayer(menu)
      N = N - 1
    end
    if N > 0 then self.menuStack[N]:gainFocus() end
    return self
  end,

  updateMenu = function( self, ... )
    self.menuStack[#self.menuStack]:update(...)
    return self
  end,

  menuStackEmpty = function( self )
    return (#self.menuStack <= 0)
  end
}

--------------------------------------------------------------------------------

