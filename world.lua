
World = Object:clone {
  priority = 10
}

function World:init( filename )


  return self
end

function World:runAllLogic( keypress )
end


function World:draw(dt)
  self.tileLayer:draw(dt)
end

function World:update(dt)

  self.tileLayer:update(dt)
end

--------------------------------------------------------------------------------


