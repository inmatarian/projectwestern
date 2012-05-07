
BattleState = State:clone {}

function BattleState:enter()
  self.screen = TextWindow( 0, 0, 30, floor(Graphics.gameHeight/8) )
  self.screen:frame("double", Color.GRAY)

  self.spriteWorld = SpriteWorld()
  self.world = TileLayer.loadMap("level/testbattle.lua", 8, 8, 224, 224)
  self.world:selfCenter():setSpriteWorld(self.spriteWorld)
  self.spriteWorld:setTileLayer( self.world )

  self.sprites = {
    BattlePlayer( 4, 5 ),
    BattleEnemy( 8, 5 )
  }

  for _, spr in ipairs(self.sprites) do
    self.spriteWorld:addSprite(spr)
  end

  self.turn = 1
  self.sprites[1].selected = true

  self.stats = BattleStatsWindow( 30, 0, 10, 30 )
  self:addLayer(self.screen, self.world, self.stats, Snitch())
end

function BattleState:keypressed(key)
  if key == "escape" then
    StateMachine:pop()
  end
end

function BattleState:update(dt)
  local who = self.sprites[self.turn]
  local done = who:runLogic(dt)
  if done then self:advanceTurn() end
end

function BattleState:advanceTurn()
  self.sprites[self.turn].selected = false
  self.turn = self.turn + 1
  if self.turn > #self.sprites then self.turn = 1 end
  self.sprites[self.turn].selected = true
end

BattleStatsWindow = TextWindow:clone {}

function BattleStatsWindow:init(...)
  BattleStatsWindow:superinit(self, ...)
  return self:refresh()
end

function BattleStatsWindow:refresh()
  self:reset()
      :fill(ASCII.Space)
      :frame('single')
      :drawCharacter(1, "HUGO", Game.Hugo )
  return self
end

function BattleStatsWindow:drawCharacter( y, name, ps )
  self:printf(1, y, name)
      :setColor(Color.CYAN)
      :set(6, y, ASCII.Delete)
      :printf(7, y, "%2i", ps.magicPoints )
      :setColor(Color.WHITE)
      :set(1, y+1, ASCII.Heart, Color.RED)
      :printf(2, y+1, "%3i/%i", ps.hitPoints, ps:maxHP())
  return self
end

BattleSprite = Sprite:clone {
  selectedTile = 0,
  baseTile = 0,
  selected = false
}

function BattleSprite:draw(x, y, dt)
  self.dt = (self.dt or 0) + dt
  if self.selected and math.floor(self.dt*3) % 2 == 1 then
    self.tile = self.selectedTile
  else
    self.tile = self.baseTile
  end
  BattleSprite:super().draw(self, x, y, dt)
end

BattlePlayer = BattleSprite:clone {
  baseTile = 129
}

function BattlePlayer:runLogic()
  if Input.tap.up then
    self:move( 0, -1 )
    return true
  elseif Input.tap.down then
    self:move( 0, 1 )
    return true
  elseif Input.tap.left then
    self:move( -1, 0 )
    return true
  elseif Input.tap.right then
    self:move( 1, 0 )
    return true
  elseif Input.tap.space then
    return true
  end
end

BattleEnemy = BattleSprite:clone {
  baseTile = 130
}

function BattleEnemy:runLogic(dt)
  self.waitTimer = (self.waitTimer or math.random(2,5)/4) - dt
  if self.waitTimer > 0 then return false end
  self.waitTimer = nil
  local dir = math.random(1, 5)
  if dir == 1 then
    self:move( 0, -1 )
  elseif dir == 2 then
    self:move( 0, 1 )
  elseif dir == 3 then
    self:move( -1, 0 )
  elseif dir == 4 then
    self:move( 1, 0 )
  end
  return true
end

