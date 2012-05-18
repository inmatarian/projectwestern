
MenuScreenState = State:clone {}

function MenuScreenState:enter()
  print("MenuScreenState:enter")
  self.playerStats = PartyShortStatsWindow( -12, 2 )
  self.moneyWin = MoneyShortStatsWindow( 30, 25 )
  self.mainMenu = MenuScreenMainMenu( 2, 2, self )
  self.menuStack = {}
  self:addLayer(self.playerStats, self.moneyWin)
  self:pushMenu( self.mainMenu )
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
      collectgarbage()
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

function MenuScreenState:refresh()
  self.playerStats:refresh()
  self.moneyWin:refresh()
end

----------------------------------------

MenuScreenWindow = TextWindow:clone {
  defaultChar = ASCII.Space,
}

function MenuScreenWindow:init( x, y, parent )
  MenuScreenWindow:superinit(self, x, y)
  self.parent = parent
  self:refresh()
  return self
end

function MenuScreenWindow:pushMenu( menu )
  self.parent:pushMenu(menu)
  return self
end

function MenuScreenWindow:popMenu()
  self.parent:popMenu()
  return self
end

function MenuScreenWindow:refreshAll()
  self.parent:refresh()
  self:refresh()
end

----------------------------------------

PartyShortStatsWindow = MenuScreenWindow:clone {
  width = 10, height = 10, priority = 0
}

function PartyShortStatsWindow:drawCharacter( y, ps )
  self:printf(1, y, ps.name)
      :setColor(Color.CYAN)
      :set(6, y, ASCII.Delete)
      :printf(7, y, "%2i", ps.actionPoints )
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

----------------------------------------

MenuScreenMenuList = MenuScreenWindow:clone {
  priority = 2, selection = 1,
  defaultChar = ASCII.Space,
  options = { "Return" }
}

MenuScreenMenuList:mixin( SelectionMixin )

function MenuScreenMenuList:init(x, y, parent, signal)
  self.signal = signal
  self:initSelection( #self.options )
  self:recalculateSize()
  return MenuScreenMenuList:superinit(self, x, y, parent)
end

function MenuScreenMenuList:recalculateSize()
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

function MenuScreenMenuList:update(dt)
  self:handleSelectionUpdate(dt)
end

function MenuScreenMenuList:selected( index )
  self.signal( index, self.options[index] )
end

----------------------------------------

MenuScreenMainMenu = MenuScreenMenuList:clone {
  priority = 2,
  options = { "Status", "Items", "Ability", "Equip", "Learn", "Order", "System" },
  handlers = {
    function(self, x, y) return MenuScreenWhoMenu(x+2, y+2, self, self.signals.statusWho) end;
    function(self, x, y) return MenuScreenItemsMenu(self) end;
    function(self, x, y) return end;
    function(self, x, y) return MenuScreenWhoMenu(x+2, y+2, self, self.signals.equipWho) end;
    function(self, x, y) return MenuScreenWhoMenu(x+2, y+2, self, self.signals.learnWho) end;
    function(self, x, y) return MenuScreenOrderMenu(x+4, y+4, self) end;
    function(self, x, y) return MenuScreenSystemMenu( 4, 3, self ) end;
  }
}

function MenuScreenMainMenu:init(x, y, parent)
  self.signals = {
    statusWho = Util.signal( self, self.handleStatusWhoMenu ),
    equipWho = Util.signal( self, self.handleEquipWhoMenu ),
    learnWho = Util.signal( self, self.handleLearnWhoMenu ),
  }
  return MenuScreenMainMenu:superinit(self, x, y, parent, Util.signal(self, self.handleMenu))
end

function MenuScreenMainMenu:handleMenu( index, option )
  local screen = self.handlers[index](self, self.x, self.y)
  if screen then
    self:pushMenu( screen )
  end
end

function MenuScreenMainMenu:handleStatusWhoMenu( index, option )
  self:popMenu():pushMenu( CharacterStatusWindow(Game.players[index], self) )
end

function MenuScreenMainMenu:handleLearnWhoMenu( index, option )
  self:popMenu():pushMenu( CharacterLearnWindow(Game.players[index], self) )
end

function MenuScreenMainMenu:handleEquipWhoMenu( index, option )
  self:popMenu():pushMenu( CharacterEquipWindow(Game.players[index], self) )
end

----------------------------------------

MenuScreenSystemMenu = MenuScreenMenuList:clone {
  priority = 3, title = "System",
  options = { "Save", "Reset", "Quit", "Back" },
}

function MenuScreenSystemMenu:selected( index )
  local option = self.options[index]
  if option == "Quit" then
    Game:quit()
  elseif option == "Reset" then
    Game:reset()
  elseif option == "Back" then
    self:popMenu()
  end
end

----------------------------------------

MenuScreenWhoMenu = MenuScreenMenuList:clone {
  priority = 4, title = "Who?"
}

function MenuScreenWhoMenu:init(...)
  local o = {}
  for _, ps in ipairs(Game.players) do
    o[#o+1] = ps.name
  end
  self.options = o
  return MenuScreenWhoMenu:superinit(self, ...)
end

----------------------------------------

MenuScreenOrderMenu = MenuScreenWhoMenu:clone {
  title = "Order"
}

function MenuScreenOrderMenu:selected(index)
  if self.firstPick then
    local gp = Game.players
    gp[self.firstPick], gp[index] = gp[index], gp[self.firstPick]
    self.firstPick = nil
    self:refreshAll()
  else
    self.firstPick = index
    self:refresh()
  end
end

----------------------------------------

CharacterStatusWindow = MenuScreenWindow:clone {
  width = 34, height = 24, priority = 10,
}

function CharacterStatusWindow:init(ps, parent)
  self.playerStats = ps
  return CharacterStatusWindow:superinit(self, "center", "center", parent)
end

function CharacterStatusWindow:refresh()
  local ps = self.playerStats
  self:reset()
      :fill(ASCII.Space)
      :frame('single')
      :horizLine('single', 0, 2, self.width)
      :vertLine('single', 7, 0, 3)
      :printf(2, 1, ps.name )

      :printf(2, 3, "Hit Points:     %3i/%-3i", ps.hitPoints, ps.maxHP)
      :printf(2, 4, "Action Points:   %2i/%-2i", ps.actionPoints, ps.maxAP)
      :printf(2, 5, "Armor Class: 5")

      :printf(2,  6, "Helmet:    DontBashMyHeadIn")
      :printf(2,  7, "Armor:     ViolentChestBump")
      :printf(2,  8, "Shield:    OhGodDontHitMe")
      :printf(2,  9, "Accessory: RingOfFuckYouUp")

      :printf(2,  10, "Items:")
      :printf(2,  11, "KickAssSwordYeah")
      :printf(3,  12, "ABCDEFGHIJKLMNOP")
      :printf(3,  13, "ABCDEFGHIJKLMNOP")
      :printf(3,  14, "ABCDEFGHIJKLMNOP")
      :printf(3,  15, "ABCDEFGHIJKLMNOP")
      :printf(3,  16, "ABCDEFGHIJKLMNOP")
      :printf(3,  17, "ABCDEFGHIJKLMNOP")
      :printf(3,  18, "ABCDEFGHIJKLMNOP")

  return self
end

function CharacterStatusWindow:update(dt)
  if Input.tap.enter or Input.tap.escape then
    self:popMenu()
  end
end

----------------------------------------

CharacterLearnWindow = MenuScreenWindow:clone {
  width = 30, height = 20, priority = 10,

  classNames = {
    "Swordplay", "Swordmanship", "Knighthood", "Knifeplay", "Dexterity",
    "Butchery", "Archery", "EagleEye", "Sharpshooter", "Cleaver", "Savage",
    "Barbaric", "Outfitter", "Defense", "Faith", "Wizardry", "Witchcraft",
    "Sorcery", "Healing", "Therapy", "Doctorate", "Juju", "Voodoo", "Shamanism",
    "Alchemy", "Stamina", "Agility", "Fortitude", "Vigor", "Immunity", "Feint",
    "Absorb", "Velocity", "Sprint", "Awareness",
  }
}

CharacterLearnWindow:mixin( SelectionMixin )

function CharacterLearnWindow:init( ps, parent )
  self:initSelection( #self.classNames, 1, 12 )
  self.playerStats = ps
  CharacterLearnWindow:superinit(self, "center", "center", parent)
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

  local y = 4
  for i = self.selectionFirst, self.selectionFirst + self.selectionRows - 1 do
    local s = self.classNames[i]
    self:printf(3, y, s)
    local val = self.playerStats.knowledge[i] or 0
    for j = 1, val do
      self:set( 19+j, y, ASCII.Black_square )
    end
    y = y + 1
  end

  self:setColor(Color.WHITE, Color.BLACK)
      :set(2, 4+self.selectionOption-self.selectionFirst, ASCII.Right_fat_arrow)
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

----------------------------------------

MenuScreenItemsMenu = MenuScreenWindow:clone {
  width = 38, height = 20, priority = 10,
}

MenuScreenItemsMenu:mixin( SelectionMixin )

function MenuScreenItemsMenu:init( parent )
  self:initSelection( Game.inventory.MAX, 2 )
  MenuScreenItemsMenu:superinit(self, "center", "center", parent)
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

----------------------------------------

CharacterEquipWindow = MenuScreenWindow:clone {
  width = 38, height = 20, priority = 10,
}

CharacterEquipWindow:mixin( SelectionMixin )

function CharacterEquipWindow:init( ps, parent )
  self.playerStats = ps
  self:initSelection( 1 )
  CharacterEquipWindow:superinit(self, "center", "center", parent)
  return self
end

function CharacterEquipWindow:refresh()
  self:reset()
      :fill(ASCII.Space)
      :frame('single')

  return self
end

function CharacterEquipWindow:update(dt)
  self:handleSelectionUpdate(dt)
end

function CharacterEquipWindow:selected(index)

end

