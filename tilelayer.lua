
TileLayer = Object:clone {
  priority = 0
}

function TileLayer:init(x, y, w, h, vw, vh, pri, data)
  print("TileLayer:init", x, y, w, h, vw, vh, pri, data)
  self.x, self.y = x, y
  self.width, self.height = w, h
  self.centerX, self.centerY = 0, 0
  self.viewWidth, self.viewHeight = vw, vh
  self.offsetX, self.offsetY = 0, 0
  self.grid = data or Util.array( w*h, 1 )
  self.visi = Util.array( w*h, 100 )
  self.priority = pri or self.priority
  return self
end

function TileLayer.loadMap( filename, x, y, viewWidth, viewHeight )
  local map = love.filesystem.load( filename )()
  local data, w, h
  for i, v in ipairs(map.layers) do
    if v.type=="tilelayer" then
      data, w, h = v.data, v.width, v.height
      break
    end
  end
  return TileLayer( x, y, w, h, viewWidth, viewHeight, 50, data )
end

function TileLayer:setCenter(x, y)
  local sx, sy = sign(x-self.centerX), sign(y-self.centerY)
  self.offsetX = self.offsetX + (sx * 16)
  self.offsetY = self.offsetY + (sy * 16)
  self.fixedOffsetX, self.fixedOffsetY = 0, 0
  self.centerX, self.centerY = x, y
  return self
end

function TileLayer:selfCenter()
  local x, y = (self.width+1)/2, (self.height+1)/2
  local cx, cy = floor(x), floor(y)
  local ox, oy = x-cx, y-cy
  self.offsetX, self.offsetY = 0, 0
  self.fixedOffsetX, self.fixedOffsetY = floor(16*ox), floor(16*oy)
  self.centerX, self.centerY = cx, cy
  return self
end

function TileLayer:followSprite(x, y)
  self:setCenter( x, y )
  self:calcVisi( x, y )
  return self
end

function TileLayer:setSpriteWorld( sprWorld )
  self.spriteWorld = sprWorld
  return self
end

function TileLayer:scroll(dx, dy)
  self.centerX, self.centerY = self.centerX + dx, self.centerY + dy
  return self
end

function TileLayer:set(x, y, t)
  x, y = floor(x), floor(y)
  if (y >= 0) and (y < self.height) and (x >= 0) and (x < self.width) then
    local pos = 1+(y*self.width+x)
    self.grid[pos] = t
  end
  return self
end

function TileLayer:get(x, y)
  x, y = floor(x), floor(y)
  if (y >= 0) and (y < self.height) and (x >= 0) and (x < self.width) then
    local pos = 1+(y*self.width+x)
    return self.grid[pos]
  end
  return 0
end

function TileLayer:getTile(x, y)
  local id = self:get(x, y)
  return Tile:getTile( id )
end

function TileLayer:getSpriteAt(x, y)
  if self.spriteWorld then
    return self.spriteWorld:getSpriteAt(x, y)
  end
end

function TileLayer:getDrawingParameters()
  local vw, vh = self.viewWidth, self.viewHeight
  local cx, cy = self.centerX, self.centerY
  local left, top = cx-floor(vw/32)-1, cy-floor(vh/32)-1
  local right, bottom = cx+floor(vw/32)+1, cy+floor(vh/32)+1
  return left, top, right, bottom
end

function TileLayer:screenPositionTile( x, y )
  local ox, oy = self.fixedOffsetX + self.offsetX, self.offsetY + self.fixedOffsetY
  local l = floor((self.centerX*16+8) - self.viewWidth/2)
  local u = floor((self.centerY*16+8) - self.viewHeight/2)
  return self.x + (x*16-l) + ox, self.y + (y*16-u) + oy
end

function TileLayer:draw(dt)
  self:animateScroll(dt)

  Graphics:setClipping( self.x, self.y, self.viewWidth, self.viewHeight )
  Graphics:setColor( 255, 255, 255 )

  local left, top, right, bottom = self:getDrawingParameters()
  for y = top, bottom do
    for x = left, right do
      local visi = tonumber(self:getVisi(x, y))
      if visi and (visi > 0) then
        local drawable = self:getSpriteAt(x, y)
        if not drawable then
          drawable = self:getTile(x, y)
        end
        local xx, yy = self:screenPositionTile( x, y )
        drawable:draw(xx, yy, dt)
      end
    end
  end
end

function TileLayer:setVisi(x, y, v)
  if (y >= 0) and (y < self.height) and (x >= 0) and (x < self.width) then
    local pos = 1+(y*self.width+x)
    self.visi[pos] = v
  end
  return self
end

function TileLayer:getVisi( x, y )
  if (y >= 0) and (y < self.height) and (x >= 0) and (x < self.width) then
    local pos = 1+(y*self.width+x)
    return self.visi[pos]
  end
  return 100
end

function TileLayer:calcVisi( cx, cy )
  local left, top, right, bottom = self:getDrawingParameters()
  for y = top, bottom do
    for x = left, right do
      self:setVisi( x, y, "dummy" )
    end
  end
  self:setVisi( cx, cy, 100 )
  for y = top, bottom do
    for x = left, right do
      self:visiCalcR( x, y, cx, cy )
    end
  end
end

function TileLayer:axialVisibilityDir( x, y, cx, cy )

  if y~=cy then y = y + ((y < cy) and 1 or -1) end
  return x, y
end

function TileLayer:visiCalcR( x, y, cx, cy )
  local visi = self:getVisi( x, y )
  if visi == "dummy" then
    local nx1 = x + ((x==cx) and 0 or ((x < cx) and 1 or -1))
    local ny1 = y + ((y==cy) and 0 or ((y < cy) and 1 or -1))
    local nx2, ny2
    if (x~=cx) or (y~=cy) then
      local ax, ay = math.abs(cx - x), math.abs(cy - y)
      if ax > ay then
        nx2, ny2 = x + ((x<cx) and 1 or -1), y
      elseif ax < ay then
        nx2, ny2 = x, y + ((y<cy) and 1 or -1)
      end
    end
    if (nx1 == cx and ny1 == cy) or (nx2 == cx and ny2 == cy) then
      visi = 100
    else
      local visi1 = self:visiCalcR(nx1, ny1, cx, cy)
      local visi2 = (nx2) and self:visiCalcR(nx2, ny2, cx, cy) or 0
      visi = math.max( visi1, visi2 )
    end
    self:setVisi( x, y, visi )
  end
  return math.max(0, visi-self:getTile(x, y):opaqueness())
end

function TileLayer:hasLineOfSight( sx, sy, tx, ty )
  local x, y = sx, sy

  local print = (sx == tx) and print or NULLFUNC

  while not ((x==tx) and (y==ty)) do
    local dx, dy = (x-tx), (y-ty)
    if math.abs(dx) >= math.abs(dy) then
      x = x + ( (dx < 0) and 1 or -1 )
    else
      y = y + ( (dy < 0) and 1 or -1 )
    end
    if (x==tx) and (y==ty) then break end
    if Tile:isOpaque( self:get(x, y) ) then
      return false
    end
  end
  return true
end

function TileLayer:animateScroll(dt)
  local ox, oy = self.offsetX, self.offsetY
  local sx, sy = sign(ox), sign(oy)
  local xspeed, yspeed = ox*6*dt, oy*6*dt
  ox, oy = ox - xspeed, oy - yspeed
  if (sx > 0 and ox < 0.25) or (sx < 0 and ox > -0.25) then ox = 0 end
  if (sy > 0 and oy < 0.25) or (sy < 0 and oy > -0.25) then oy = 0 end
  self.offsetX, self.offsetY = ox, oy
end

function TileLayer:update(dt) end

