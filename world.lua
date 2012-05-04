
World = Object:clone {
  priority = 10
}

function World:init( filename )
  self.tileLayer = TileLayer.loadMap( filename, 8, 8, (320-16), (240-16) )
  self.tileLayer:setSpriteWorld( self )

  self.sprites = {}
  self.spatialHash = {}
  self.logicQueue = {}

  self.player = Player( 64, 64, 129 )
  print("Player is", self.player)

  self:addSprite( self.player )
  self:addSprite( Enemy( 60, 60, 130 ) )
  self.tileLayer:followSprite( self.player.x, self.player.y )

  return self
end

function World:runAllLogic( keypress )
  local Q = self.logicQueue
  for _, spr in ipairs(self.sprites) do table.insert(Q, spr) end
  table.sort(Q, Sprite.sortingFunction)
  local N = #Q
  for i = 1, N do
    Q[i]:runLogic( keypress )
  end
  for i = 1, N do Q[i] = nil end

  self.tileLayer:followSprite( self.player.x, self.player.y )
end

function World:movePlayer( dx, dy )
  self.player:move( dx, dy )
  return self
end

function World:getSpriteAt( x, y )
  return self.spatialHash[ y * 1000 + x ]
end

function World:moveSprite( spr, dx, dy )
  self.spatialHash[ spr.y * 1000 + spr.x ] = nil
  spr.x = floor(spr.x + dx)
  spr.y = floor(spr.y + dy)
  self.spatialHash[ spr.y * 1000 + spr.x ] = spr
  return self
end

function World:addSprite( spr )
  for _, v in ipairs(self.sprites) do
    if v == spr then return self end
  end
  table.insert( self.sprites, spr )
  self.spatialHash[ spr.y * 1000 + spr.x ] = spr
  spr:setParent( self )
  return self
end

function World:removeSprite( spr )
  self.spatialHash[ spr.y * 1000 + spr.x ] = nil
  for i, v in ipairs(self.sprites) do
    if v == spr then
      table.remove( self.sprites, i )
      break
    end
  end
  return self
end

function World:getTileAt( x, y )
  return self.tileLayer:getTile(x, y)
end

function World:draw()
  self.tileLayer:draw()
end

function World:update(dt)
  self.tileLayer:update(dt)
end

--------------------------------------------------------------------------------

Player = Sprite:clone {
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

Enemy = Sprite:clone {}

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

