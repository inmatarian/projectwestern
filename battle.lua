
BattleState = State:clone {}

function BattleState:enter()
  self.screen = TextWindow( 0, 0, 30, floor(Graphics.gameHeight/8) )
  self.screen:frame("double", Color.GRAY)

  self.spriteWorld = SpriteWorld()
  self.world = TileLayer.loadMap("level/testbattle.lua", 8, 8, 224, 224)
  self.world:selfCenter():setSpriteWorld(self.spriteWorld)
  self.spriteWorld:setTileLayer( self.world )

  self.sprites = {
    BattlePlayer( 4, 5, self ),
    BattleEnemy( 8, 5, self )
  }

  for _, spr in ipairs(self.sprites) do
    self.spriteWorld:addSprite(spr)
  end

  self.turn = 1
  self.roster = {}
  for _, ps in ipairs(Game.players) do
    self.roster[#self.roster+1] = ps:clone()
  end

  self.stats = BattleStatsWindow( self.roster )
  self:addLayer(self.screen, self.world, self.stats, Snitch())
end

function BattleState:update(dt)
  if Input.tap.escape then
    StateMachine:pop()
  else
    local who = self.sprites[self.turn]
    if not who.selected then
      who.selected = true
      who:startTurn()
    end
    local done = who:runLogic(dt)
    if done then self:advanceTurn() end
  end
end

function BattleState:advanceTurn()
  self.sprites[self.turn].selected = false
  self.turn = self.turn + 1
  if self.turn > #self.sprites then self.turn = 1 end
end

----------------------------------------

BattleStatsWindow = TextWindow:clone {
  x = 30, y = 0, width = 10, height = 30
}

function BattleStatsWindow:init(roster)
  BattleStatsWindow:superinit(self)
  self.roster = roster
  return self:refresh()
end

function BattleStatsWindow:refresh()
  self:reset()
      :fill(ASCII.Space)
      :frame('single')
      :horizLine('single', 0, 9, self.width)
      :horizLine('single', 0, 24, self.width)

  for i, ps in ipairs(Game.players) do
    self:drawCharacter( 1 + ((i-1)*2), ps )
  end

  self:drawMenu()

  return self
end

function BattleStatsWindow:drawCharacter( y, ps )
  self:printf(1, y, ps.name)
      :setColor(Color.CYAN)
      :set(6, y, ASCII.Delete)
      :printf(7, y, "%2i", ps.actionPoints )
      :setColor(Color.WHITE)
      :set(1, y+1, ASCII.Heart, Color.RED)
      :printf(2, y+1, "%3i/%i", ps.hitPoints, ps.maxHP)
  return self
end

function BattleStatsWindow:drawMenu()
  self:printf(2, 25, "Action")
  self:printf(2, 26, "Move")
  self:printf(2, 27, "Switch")
  self:printf(2, 28, "End")
  return self
end

----------------------------------------

local dist, seek, lineup
do
  local abs = math.abs

  function dist(x1, y1, x2, y2)
    return abs(x2-x1) + abs(y2-y1)
  end

  function seek(sx, sy, tx, ty)
    local dx, dy = tx - sx, ty - sy
    local ax = ((( dx < 0 ) and -1) or (( dx > 0 ) and 1)) or 0
    local ay = ((( dy < 0 ) and -1) or (( dy > 0 ) and 1)) or 0
    if abs(dx) > abs(dy) then
      return ax, 0
    else
      return 0, ay
    end
  end

  function lineup(sx, sy, tx, ty)
    local ax, ay = abs(tx-sx), abs(ty-sy)
    if ax > ay then
      return ( tx < sx ) and -1 or 1, 0
    else
      return 0, ( ty < sy ) and -1 or 1
    end
  end
end

----------------------------------------

BattleSprite = Sprite:clone {
  selectedTile = 0,
  baseTile = 0,
  selected = false,
  runLogic = NULLFUNC
}

function BattleSprite:init(x, y, parent)
  self.parent = parent
  BattleSprite:superinit(self, x, y)
  return self
end

function BattleSprite:draw(x, y, dt)
  self.dt = (self.dt or 0) + dt
  if self.selected and math.floor(self.dt*4) % 4 == 1 then
    self.tile = self.selectedTile
  else
    self.tile = self.baseTile
  end
  BattleSprite:super().draw(self, x, y, dt)
end

function BattleSprite:startTurn()
  self.baseX, self.baseY = self.x, self.y
end

function BattleSprite:tryMove( dx, dy )
  local newX, newY = self.x + dx, self.y + dy
  if dist( newX, newY, self.baseX, self.baseY ) > 3 then return false end
  self:move(dx, dy)
  return (self.x == newX) and (self.y == newY)
end

----------------------------------------

BattlePlayer = BattleSprite:clone {
  baseTile = 129
}

function BattlePlayer:startTurn()
  BattlePlayer:super().startTurn(self)
end

function BattlePlayer:runLogic()
  if Input.tap.up then
    self:tryMove( 0, -1 )
  elseif Input.tap.down then
    self:tryMove( 0, 1 )
  elseif Input.tap.left then
    self:tryMove( -1, 0 )
  elseif Input.tap.right then
    self:tryMove( 1, 0 )
  elseif Input.tap.enter then
    return true
  end
end

----------------------------------------

BattleStrategy = {
  Random = {
    strategyStart = function(self)
      self.targetX = self.x + Game.random(-3, 3)
      self.targetY = self.y + Game.random(-3, 3)
      self.moves = 3
    end,
    strategyLogic = function(self)
      local dx, dy = seek(self.x, self.y, self.targetX, self.targetY)
      self:tryMove( dx, dy )
      self.moves = self.moves - 1
      return (self.moves <= 0)
    end
  };
}

----------------------------------------

BattleEnemy = BattleSprite:clone {
  baseTile = 130,
}
BattleEnemy:mixin(BattleStrategy.Random)

function BattleEnemy:startTurn()
  BattleEnemy:super().startTurn(self)
  self.waitTimer = Game.random(3,15) / 8
  return self:strategyStart()
end

function BattleEnemy:runLogic(dt)
  self.waitTimer = self.waitTimer - dt
  if self.waitTimer > 0 then return false end
  self.waitTimer = Game.random(2, 4) / 8
  return self:strategyLogic()
end

