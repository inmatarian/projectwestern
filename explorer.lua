
ExplorerState = State:clone {}

function ExplorerState:enter()
  self.screen = TextWindow( 0, 0, floor(Graphics.gameWidth/8), floor(Graphics.gameHeight/8) )
  self.screen:frame("double", Color.GRAY)

  self.spriteWorld = SpriteWorld()
  self.tileLayer = TileLayer.loadMap( "level/testworld.lua", 8, 8, (320-16), (240-16) )
  self.tileLayer:setSpriteWorld( self.spriteWorld )
  self.spriteWorld:setTileLayer( self.tileLayer )

  self.player = ExplorerPlayer( 64, 64 )
  print("Player is", self.player)

  self.spriteWorld:addSprite( self.player )
  self.spriteWorld:addSprite( ExplorerEnemy( 60, 60 ) )
  self.tileLayer:followSprite( self.player.x, self.player.y )

  self:addLayer(self.screen, self.tileLayer, Snitch())
end

function ExplorerState:yield()
  while true do
    local lastKey = coroutine.yield(true)
    if lastKey then
      return lastKey
    end
  end
end

function ExplorerState:update(dt)
  if Input.tap.enter then
    StateMachine:enqueue( MenuScreenState() )
  elseif Input.tap.f7 then
    StateMachine:enqueue( BattleState() )
  else
    self:checkPlayerInput()
    self.tileLayer:update(dt)
    Game.Hugo:recoverMagicStep(1.0)
    Game.Hugo:recoverHealthStep(1.0)
  end
end

function ExplorerState:checkPlayerInput()
  if Input.tap.up then
    self:movePlayer( 0, -1 )
  elseif Input.tap.down then
    self:movePlayer( 0, 1 )
  elseif Input.tap.left then
    self:movePlayer( -1, 0 )
  elseif Input.tap.right then
    self:movePlayer( 1, 0 )
  end
end

function ExplorerState:movePlayer( dx, dy )
  self.player:move( dx, dy )
  self.spriteWorld:runAllLogic( keypress )
  self.tileLayer:followSprite( self.player.x, self.player.y )
  return self
end

function ExplorerState:getSpriteAt( x, y )
  return self.spriteWorld:getSpriteAt(x, y)
end

function ExplorerState:getTileAt( x, y )
  return self.tileLayer:getTile(x, y)
end

------------------------------------------------------------

ExplorerPlayer = Sprite:clone {
  tile = 129,
  priority = 2993,
}

ExplorerEnemy = Sprite:clone {
  tile = 130
}

function ExplorerEnemy:runLogic()
  local dir = math.random(1, 5)
  if dir == 2 then
    self:move( 0, -1 )
  elseif dir == 3 then
    self:move( 0, 1 )
  elseif dir == 4 then
    self:move( -1, 0 )
  elseif dir == 5 then
    self:move( 1, 0 )
  end
end

