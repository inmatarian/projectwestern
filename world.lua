
World = Object:clone {
  priority = 10
}

function World:init( filename )
  self.spriteWorld = SpriteWorld()
  self.tileLayer = TileLayer.loadMap( filename, 8, 8, (320-16), (240-16) )
  self.tileLayer:setSpriteWorld( self.spriteWorld )
  self.spriteWorld:setTileLayer( self.tileLayer )

  self.player = Player( 64, 64 )
  print("Player is", self.player)

  self.spriteWorld:addSprite( self.player )
  self.spriteWorld:addSprite( Enemy( 60, 60 ) )
  self.tileLayer:followSprite( self.player.x, self.player.y )

  return self
end

function World:runAllLogic( keypress )
  self.spriteWorld:runAllLogic( keypress )
  self.tileLayer:followSprite( self.player.x, self.player.y )
end

function World:movePlayer( dx, dy )
  self.player:move( dx, dy )
  return self
end

function World:getSpriteAt( x, y )
  return self.spriteWorld:getSpriteAt(x, y)
end

function World:getTileAt( x, y )
  return self.tileLayer:getTile(x, y)
end

function World:draw(dt)
  self.tileLayer:draw(dt)
end

function World:update(dt)
  self.tileLayer:update(dt)
end

--------------------------------------------------------------------------------

Player = Sprite:clone {
  tile = 129,
  priority = 2993,
}

function Player:runLogic( key )
  if key == "up" then
    self:move( 0, -1 )
  elseif key == "down" then
    self:move( 0, 1 )
  elseif key == "left" then
    self:move( -1, 0 )
  elseif key == "right" then
    self:move( 1, 0 )
  end
end

Enemy = Sprite:clone {
  tile = 130
}

function Enemy:runLogic()
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

