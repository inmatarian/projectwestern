
MenuScreenState = State:clone {}

function MenuScreenState:enter()
  print("MenuScreenState:enter")
  self.playerStats = PartyShortStatsWindow( -12, 2 )
  self.moneyWin = MoneyShortStatsWindow( 30, 25 )
  self.mainMenu = MenuScreenMainMenu( 2, 2, self, self.handleMainMenu )
  self.systemMenu = MenuScreenSystemMenu( 4, 3, self, self.handleSystemMenu )
  self.menuStack = { self.mainMenu }
  self:addLayer(self.playerStats, self.moneyWin, self.mainMenu)
end

function MenuScreenState:draw(dt)
  StateMachine:downsend( self, -1, "draw", dt )
  MenuScreenState:super().draw(self, dt)
end

function MenuScreenState:update(dt)
  if Input.tap.escape then
    self:popMenu()
    if #self.menuStack <= 0 then
      StateMachine:pop()
    end
  else
    self.menuStack[#self.menuStack]:update(dt)
  end
end

function MenuScreenState:pushMenu( menu )
  table.insert(self.menuStack, menu)
  self:addLayer(menu)
  return self
end

function MenuScreenState:popMenu()
  local menu = table.remove(self.menuStack)
  self:removeLayer(menu)
  return self
end

function MenuScreenState:handleMainMenu( index, option )
  if option == "System" then
    self:pushMenu( self.systemMenu )
  elseif option == "Items" then
    self:pushMenu( MenuScreenItemsMenu() )
  elseif option == "Status" then
    local x, y = self.mainMenu.x, self.mainMenu.y
    self:pushMenu( MenuScreenWhoMenu(x+2, y+2, self, self.handleStatusWhoMenu) )
  elseif option == "Learn" then
    local x, y = self.mainMenu.x, self.mainMenu.y
    self:pushMenu( MenuScreenWhoMenu(x+2, y+2, self, self.handleLearnWhoMenu) )
  elseif option == "Return" then
    StateMachine:pop()
  end
end

function MenuScreenState:handleStatusWhoMenu( index, option )
  self:popMenu()
  self:pushMenu( CharacterStatusWindow(Game.players[index], self, self.popMenu) )
end

function MenuScreenState:handleLearnWhoMenu( index, option )
  self:popMenu()
  self:pushMenu( CharacterLearnWindow(Game.players[index]) )
end

function MenuScreenState:handleSystemMenu( index, option )
  if option == "Back" then
    self:popMenu()
  end
end

----------------------------------------

MenuScreenWindow = TextWindow:clone {
  defaultChar = ASCII.Space,
}

function MenuScreenWindow:init( x, y )
  MenuScreenWindow:superinit(self, x, y)
  self:refresh()
  return self
end

----------------------------------------

CallbackMixin = {
  setCallback = function(self, parent, callback)
    self.callbackParent = parent
    self.callbackFunction = callback or NULLFUNC
    return self
  end,
  doCallback = function(self, ...)
    self.callbackFunction( self.callbackParent, ... )
    return self
  end
}

----------------------------------------

SelectionMixin = {
  initSelection = function(self, max, columns)
    self.selectionOption = 1
    self.selectionColumns = columns or 1
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
    elseif Input.tap.pageup then dist = -8 * col
    elseif Input.tap.pagedown then dist = 8 * col
    elseif Input.tap.home then dist = -9001
    elseif Input.tap["end"] then dist = 9001
    elseif Input.tap.enter then
      self:selected( self.selectionOption )
    end
    if dist ~= 0 then
      self.selectionOption = bound(1, self.selectionOption+dist, self.selectionMax)
      self:refresh()
    end
    return self
  end
}

----------------------------------------

PartyShortStatsWindow = MenuScreenWindow:clone {
  width = 10, height = 10, priority = 0
}

function PartyShortStatsWindow:drawCharacter( y, ps )
  self:printf(1, y, ps.name)
      :setColor(Color.CYAN)
      :set(6, y, ASCII.Delete)
      :printf(7, y, "%2i", ps.magicPoints )
      :setColor(Color.WHITE)
      :set(1, y+1, ASCII.Heart, Color.RED)
      :printf(2, y+1, "%3i/%i", ps.hitPoints, ps.maxHP)
  return self
end

function PartyShortStatsWindow:refresh()
  self:reset()
      :fill(ASCII.Space)
      :frame('single')
  for i, ps in ipairs(Game.players) do
    self:drawCharacter( 1 + ((i-1)*2), ps )
  end
  return self
end

----------------------------------------

MoneyShortStatsWindow = MenuScreenWindow:clone {
  width = 8, height = 3, priority = 1
}

function MoneyShortStatsWindow:refresh()
  self:reset()
      :frame('single')
      :printf(1, 1, "99999")
      :set(6, 1, ASCII.Dot, Color.YELLOW )
  return self
end

----------------------------------------

TestColorsWindow = MenuScreenWindow:clone {
  width = 24, height = 3, priority = 1,
}

function TestColorsWindow:refresh()
  self:reset():frame('single')
  local i = 1
  for _, v in pairs(Color) do
    self:set( i, 1, ASCII.Full_block, v )
    i = i + 1
  end
  return self
end

----------------------------------------

MenuScreenMenuList = TextWindow:clone {
  priority = 2, selection = 1,
  defaultChar = ASCII.Space,
  options = { "Return" }
}

MenuScreenMenuList:mixin( CallbackMixin, SelectionMixin )

function MenuScreenMenuList:init(x, y, parent, callback)

  self.height = 2 + #self.options
  self.width = 0
  for _, opt in ipairs(self.options) do
    self.width = math.max( self.width, 3 + #opt )
  end
  if self.title then
    self.height = self.height + 2
    self.width = math.max( self.width, 2 + #self.title )
  end

  MenuScreenMenuList:superinit(self, x, y)
  self:setCallback( parent, callback )
  self:initSelection( #self.options )
  self:refresh()
end

function MenuScreenMenuList:refresh()
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

  self:setColor(Color.WHITE, Color.BLACK)
      :set(1, startLine + self.selectionOption, ASCII.Right_fat_arrow)

  return self
end

function MenuScreenMenuList:update(dt)
  self:handleSelectionUpdate(dt)
end

function MenuScreenMenuList:selected( index )
  self:doCallback( index, self.options[index] )
end

----------------------------------------

MenuScreenMainMenu = MenuScreenMenuList:clone {
  priority = 2,
  options = { "Status", "Items", "Ability", "Equip", "Learn", "Order", "System" }
}

MenuScreenSystemMenu = MenuScreenMenuList:clone {
  priority = 3,
  title = "System",
  options = { "Save", "Reset", "Quit", "Back" }
}

MenuScreenWhoMenu = MenuScreenMenuList:clone {
  priority = 4,
  title = "Who?",
  init = function(self,...)
    local o = {}
    for _, ps in ipairs(Game.players) do
      o[#o+1] = ps.name
    end
    self.options = o
    return MenuScreenWhoMenu:superinit(self, ...)
  end
}

--------------------------------------------------------------------------------

MenuScreenDialog = MenuScreenWindow:clone()
MenuScreenDialog:mixin( CallbackMixin )

function MenuScreenDialog:init( x, y, parent, callback )
  self:setCallback(parent, callback)
  MenuScreenWindow:superinit(self, x, y)
  self:refresh()
  return self
end

function MenuScreenDialog:update(dt)
  if Input.tap.enter or Input.tap.escape then
    self:doCallback()
  end
end

----------------------------------------

CharacterStatusWindow = MenuScreenDialog:clone {
  width = 34, height = 24, priority = 10,
}

function CharacterStatusWindow:init(ps, ...)
  self.playerStats = ps
  return CharacterStatusWindow:superinit(self, "center", "center", ...)
end

function CharacterStatusWindow:refresh()
  local ps = self.playerStats
  self:reset()
      :fill(ASCII.Space)
      :frame('single')
      :horizLine('single', 0, 2, self.width)
      :vertLine('single', 7, 0, 3)
      :printf(2, 1, ps.name )

      :printf(2, 3, "HP: %3i/%3i", ps.hitPoints, ps.maxHP)
      :printf(2, 4, "Morale:  50")

--[[
      :printf(1, 1, "NAME" )
      :printf(2, 2, "HP: 999/999")
      :printf(2, 3, "Morale:  50")
      :printf(16, 1, "Vigor:  99")
      :printf(16, 2, "Acuity: 99")
      :printf(16, 3, "Speed:  99")
      :printf(2,  5, "Weapon: KickAssSwordYeah")
      :printf(2,  6, "Helmet: DontBashMyHeadIn")
      :printf(2,  7, "Armor:  ViolentChestBump")
      :printf(2,  8, "Extra:  RingOfFuckYouUp")
      :printf(2,  10, "Prepared Abilities:")
      :printf(3,  11, "ABCDEFGHIJKLMNOP")
      :printf(3,  12, "ABCDEFGHIJKLMNOP")
      :printf(3,  13, "ABCDEFGHIJKLMNOP")
      :printf(3,  14, "ABCDEFGHIJKLMNOP")
      :printf(3,  15, "ABCDEFGHIJKLMNOP")
      :printf(3,  16, "ABCDEFGHIJKLMNOP")
      :printf(3,  17, "ABCDEFGHIJKLMNOP")
      :printf(3,  18, "ABCDEFGHIJKLMNOP")

]]
  return self
end

----------------------------------------

CharacterLearnWindow = MenuScreenWindow:clone {
  width = 30, height = 20, priority = 10,

  classNames = {
    "Squire",
    "Knight",
    "Alchemist",
  }
}

CharacterLearnWindow:mixin( SelectionMixin )

function CharacterLearnWindow:init( ps, ... )
  self:initSelection( #self.classNames )
  self.playerStats = ps
  CharacterLearnWindow:superinit(self, "center", "center", ...)
  return self
end

function CharacterLearnWindow:refresh()
  self:reset()
      :fill(ASCII.Space)
      :frame('single')
      :horizLine('single', 0, 2, self.width)
      :printf(2, 1, self.playerStats.name)
      :printf(8, 1, "Level %2i", self.playerStats.techLevel)
      :printf(18, 1, "Pts %2i", self.playerStats.techPoints)
      :horizLine('single', 0, self.height-3, self.width)
      :printf(2, self.height-2, "Exp: 999999")
      :printf(16, self.height-2, "Next: 999999")
      :vertLine('single', 14, self.height-3, 3)

  for i, s in ipairs(self.classNames) do
    self:printf(3, 3+i, s)
    local val = self.playerStats.knowledge[i] or 0
    for j = 1, val do
      self:set( 19+j, 3+i, ASCII.Black_square )
    end
  end

  self:setColor(Color.WHITE, Color.BLACK)
      :set(2, 3+self.selectionOption, ASCII.Right_fat_arrow)
  return self
end

function CharacterLearnWindow:update(dt)
  self:handleSelectionUpdate(dt)
end

function CharacterLearnWindow:selected( index )
  print( "CharacterLearnWindow:selected", index, self.classNames[index] )
  local val = self.playerStats.knowledge[index]
  val = math.min((val or 0) + 1, 8)
  self.playerStats.knowledge[index] = val
  self:refresh()
end

--------------------------------------------------------------------------------

MenuScreenItemsMenu = MenuScreenWindow:clone {
  width = 38, height = 20, priority = 10,
}

MenuScreenItemsMenu:mixin( SelectionMixin )

function MenuScreenItemsMenu:init( ... )
  self:initSelection( Game.inventory.MAX, 2 )
  MenuScreenItemsMenu:superinit(self, "center", "center", ...)
  return self
end

function MenuScreenItemsMenu:itemLocation( index )
  return 1 + ((index-1)%2) * 18, 1 + floor((index-1)/2)
end

function MenuScreenItemsMenu:refresh()
  self:reset()
      :fill(ASCII.Space)
      :frame('single')
      :horizLine('single', 0, self.height-3, self.width)

  local inven = Game.inventory
  for i = 1, inven.MAX do
    local x, y = self:itemLocation(i)
    self:printf( x+1, y, "%-14s:%2i",
      inven:itemName(i):sub(1, 14), inven:quantity(i) )
  end

  self:printf(1, self.height-2, inven:itemDesc(self.selectionOption))

  local opt = self.selectionOption
  local sx, sy = self:itemLocation(opt)
  if self.firstPick then
    local fx, fy = self:itemLocation(self.firstPick)
    self:setColor(Color.WHITE, Color.BLACK)
        :set(fx, fy, ASCII.Right_fat_arrow)
        :setColor(Color.YELLOW, Color.BLACK)
        :set(sx, sy, ASCII.Right_fat_arrow)
  else
    self:setColor(Color.WHITE, Color.BLACK)
        :set(sx, sy, ASCII.Right_fat_arrow)
  end

  return self
end

function MenuScreenItemsMenu:update(dt)
  self:handleSelectionUpdate(dt)
end

function MenuScreenItemsMenu:selected( index )
  if not self.firstPick then
    self.firstPick = index
  else
    Game.inventory:swapItems( index, self.firstPick )
    self.firstPick = nil
  end
  self:refresh()
end


