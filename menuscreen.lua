
MenuScreenState = State:clone {}

function MenuScreenState:enter()
  print("MenuScreenState:enter")
  self.playerStats = PartyShortStatsWindow( -12, 2 )
  self.moneyWin = MoneyShortStatsWindow( 30, 25 )
  self.mainMenu = MenuScreenMainMenu( 2, 2, self, self.handleMainMenu )
  self.systemMenu = MenuScreenSystemMenu( 26, 4, self, self.handleSystemMenu )
  self.menuStack = { self.mainMenu }
  local test = TestColorsWindow( 2, 15 )
  self:addLayer(self.playerStats, self.moneyWin, self.mainMenu, test)
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

function MenuScreenState:handleMainMenu( option )
  if option == "System" then
    self:pushMenu( self.systemMenu )
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

function MenuScreenState:handleStatusWhoMenu(option)
  self:popMenu()
  self:pushMenu( CharacterStatusWindow(5, 5, self, self.popMenu) )
end

function MenuScreenState:handleLearnWhoMenu(option)
  self:popMenu()
  self:pushMenu( CharacterLearnWindow(5, 5) )
end

function MenuScreenState:handleSystemMenu( option )
  if option == "Back" then
    self:popMenu()
  end
end

----------------------------------------

MenuScreenWindow = TextWindow:clone {
  defaultChar = ASCII.Space
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
  initSelection = function(self, max)
    self.selectionOption = 1
    self.selectionMax = max
    return self
  end,
  handleSelectionUpdate = function(self, dt)
    local dist = 0
    if Input.tap.up or Input.tap.left then dist = -1
    elseif Input.tap.down or Input.tap.right then dist = 1
    elseif Input.tap.pageup then dist = -8
    elseif Input.tap.pagedown then dist = 8
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

function PartyShortStatsWindow:drawCharacter( y, name, ps )
  self:printf(1, y, name)
      :setColor(Color.CYAN)
      :set(6, y, ASCII.Delete)
      :printf(7, y, "%2i", ps.magicPoints )
      :setColor(Color.WHITE)
      :set(1, y+1, ASCII.Heart, Color.RED)
      :printf(2, y+1, "%3i/%i", ps.hitPoints, ps:maxHP())
  return self
end

function PartyShortStatsWindow:refresh()
  self:reset()
      :fill(ASCII.Space)
      :frame('single')
      :drawCharacter( 1, "HUGO", Game.Hugo )
      :drawCharacter( 3, "EVAN", Game.Hugo )
      :drawCharacter( 5, "ANNA", Game.Hugo )
      :drawCharacter( 7, "SARA", Game.Hugo )
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
  if self.orientation == "horizontal" then
    self.height = 3
    self.width = 2
    for _, opt in ipairs(self.options) do
      self.width = self.width + #opt + 1
    end
  else
    self.height = 2 + #self.options
    self.width = 0
    for _, opt in ipairs(self.options) do
      self.width = math.max( self.width, 3 + #opt )
    end
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

  if self.title then self:printf(1, 0, self.title) end

  if self.orientation == "horizontal" then
    local x = 1
    for i, opt in ipairs(self.options) do
      local selected = (i==self.selectionOption)
      local back = selected and Color.MIDNIGHT or Color.BLACK
      self:setColor(Color.WHITE, back):printf(x+1, 1, opt)
      if selected then self:set(x, 1, ASCII.Right_fat_arrow) end
      x = x + #opt + 1
    end
  else
    for i, opt in ipairs(self.options) do
      local back = (i==self.selectionOption) and Color.MIDNIGHT or Color.BLACK
      self:setColor(Color.WHITE, back):printf(2, i, opt)
    end
    self:setColor(Color.WHITE, Color.BLACK)
        :set(1, self.selectionOption, ASCII.Right_fat_arrow)
  end
  return self
end

function MenuScreenMenuList:update(dt)
  self:handleSelectionUpdate(dt)
end

function MenuScreenMenuList:selected( index )
  self:doCallback( self.options[index] )
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
  options = { "HUGO", "EVAN", "ANNA", "SARA" }
}

--------------------------------------------------------------------------------

MenuScreenDialog = MenuScreenWindow:clone()
MenuScreenDialog:mixin( CallbackMixin )

function MenuScreenDialog:init( x, y, parent, callback )
  MenuScreenWindow:superinit(self, x, y)
  self:setCallback(parent, callback)
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
  width = 28, height = 20, priority = 10,
}

function CharacterStatusWindow:refresh()
  self:reset()
      :fill(ASCII.Space)
      :frame('single')
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
  return self
end

----------------------------------------

CharacterLearnWindow = MenuScreenWindow:clone {
  width = 30, height = 20, priority = 10
}

CharacterLearnWindow:mixin( SelectionMixin )

function CharacterLearnWindow:init( x, y )
  self:initSelection( 12 )
  CharacterLearnWindow:superinit(self, x, y)
  self:refresh()
  return self
end

function CharacterLearnWindow:refresh()
  self:reset()
      :fill(ASCII.Space)
      :frame('single')
      :horizLine('single', 0, 2, self.width)
      :printf(2, 1, "NAME")
      :printf(10, 1, "Tech Level 000/255")
      :horizLine('single', 0, self.height-3, self.width)
      :printf(2, self.height-2, "Exp: 999999")
      :printf(16, self.height-2, "Next: 999999")
      :vertLine('single', 14, self.height-3, 3)
      :printf(3, 4, "ABCDEFGHIJKLMNOP")
      :printf(3, 5, "ABCDEFGHIJKLMNOP")
      :printf(3, 6, "ABCDEFGHIJKLMNOP")
      :printf(3, 7, "ABCDEFGHIJKLMNOP")
      :printf(3, 8, "ABCDEFGHIJKLMNOP")
      :printf(3, 9, "ABCDEFGHIJKLMNOP")
      :printf(3, 10, "ABCDEFGHIJKLMNOP")
      :printf(3, 11, "ABCDEFGHIJKLMNOP")
      :printf(3, 12, "ABCDEFGHIJKLMNOP")
      :printf(3, 13, "ABCDEFGHIJKLMNOP")
      :printf(3, 14, "ABCDEFGHIJKLMNOP")
      :printf(3, 15, "ABCDEFGHIJKLMNOP")
      :setColor(Color.WHITE, Color.BLACK)
      :set(2, 3+self.selectionOption, ASCII.Right_fat_arrow)
  return self
end

function CharacterLearnWindow:update(dt)
  self:handleSelectionUpdate(dt)
end

function CharacterLearnWindow:selected( index )
  print( "CharacterLearnWindow:selected", index )
end

