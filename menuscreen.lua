
MenuScreenState = State:clone {}
MenuScreenState:mixin(MenuStackMixin)

function MenuScreenState:enter()
  print("MenuScreenState:enter")
  self.playerStats = PartyShortStatsWindow( -12, 2 )
  self.moneyWin = MoneyShortStatsWindow( 30, 25 )
  self.mainMenu = MenuScreenMainMenu( 2, 2, self )
  self:addLayer(self.playerStats, self.moneyWin)
  self:initMenuStack()
  self:pushMenu( self.mainMenu )
end

function MenuScreenState:draw(dt)
  StateMachine:downsend( self, -1, "draw", dt )
  MenuScreenState:super().draw(self, dt)
end

function MenuScreenState:update(dt)
  if Input.tap.escape then
    self:popMenu()
    if self:menuStackEmpty() then
      StateMachine:pop()
      collectgarbage()
    end
  else
    self:updateMenu(dt)
  end
end

function MenuScreenState:refresh()
  self.playerStats:refresh()
  self.moneyWin:refresh()
end

----------------------------------------

PartyShortStatsWindow = WindowWidget:clone {
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

MoneyShortStatsWindow = WindowWidget:clone {
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

MenuScreenMainMenu = MenuListWidget:clone {
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

MenuScreenSystemMenu = MenuListWidget:clone {
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

MenuScreenWhoMenu = MenuListWidget:clone {
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

CharacterStatusWindow = WindowWidget:clone {
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

CharacterLearnWindow = WindowWidget:clone {
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

MenuScreenItemsMenu = WindowWidget:clone {
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

CharacterEquipWindow = WindowWidget:clone {
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

