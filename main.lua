--[[----------------------------------------------------------------------------
-- PROJECT WESTERN
-- INNY IS WORKING ON THIS
-- STEAL MY CODE AND DIE IN A FIRE
-- ... because the code is bad, your computer will set on fire while trying
-- to run it. Seriously, I care about your safety, please be careful.
--]]----------------------------------------------------------------------------

floor = math.floor
function NULLFUNC() end
function sign(x) return (((x==0) and 0) or ((x>0) and 1)) or -1 end
function bound(a, b, c) return (((b<a) and a) or (b>c) and c) or b end

--------------------------------------------------------------------------------

for _, M in ipairs {
  "util", "ascii", "object", "graphics", "input", "statemachine", "textwindow",
  "tilelayer", "tile", "sprite", "explorer", "menuscreen", "battle"
}
do require(M) end

--------------------------------------------------------------------------------

E = Util.symbol()

--------------------------------------------------------------------------------

Snitch = ScrollingWindow:clone {
  dt = 1, visible = false
}

function Snitch:init()
  Snitch:superinit(self, 0, 0, 40, 1, 2993)
  return self:writeln("-")
end

function Snitch:toggle()
  Snitch.visible = not Snitch.visible
  Snitch.dt = 0.99
end

function Snitch:draw(dt)
  if not self.visible then return end
  dt = dt + Snitch.dt
  if dt >= 1 then
    dt = dt - 1
    local fps = love.timer.getFPS()
    local garbage = collectgarbage("count")
    self:writeln("FPS:", fps, "Mem:", math.floor(garbage).."k")
  end
  Snitch.dt = dt
  Snitch:super().draw(self, dt)
end

--------------------------------------------------------------------------------

PlayerStats = Object:clone ()

function PlayerStats:maxHP()
  return math.max(15, math.min(999, 6*(self.vitality+1) + 4*(self.strength+1)))
end

function PlayerStats:recoverHealthStep( fraction )
  local hp, max = self.hitPoints, self:maxHP()
  local charge = math.max(0.5, math.min(32, hp/2)) * fraction
  local newhp = math.min( max, hp + charge )
  self.hitPoints = newhp
  -- print('Hp:', hp, max, charge, newhp)
end

function PlayerStats:recoverMagicStep( fraction )
  local mp, max = self.magicPoints, self.intelligence*1.15
  local charge = math.max((max-mp)/10, 0.01) * fraction
  local newmp = math.min( 99, mp + charge )
  self.magicPoints = newmp
  -- print('Mp:', mp, max, charge, newmp)
end

--------------------------------------------------------------------------------

Game = {
  deltaTime = 0
}

Game.Hugo = PlayerStats:clone {
  hitPoints = 0,
  magicPoints = 0,
  strength = 10,
  intelligence = 10,
  vitality = 10,
  agility = 10,
}

--------------------------------------------------------------------------------

function love.load()
  Graphics:init()
  Input:init()
  StateMachine:push( ExplorerState() )
end

function love.update(dt)
  Graphics.deltaTime = dt
  Game.deltaTime = dt
  StateMachine:send( E.update, dt )
  Input:update(dt)
end

function love.draw()
  Graphics:start()
  StateMachine:send( E.draw, Graphics.deltaTime )
  Graphics:stop()
end

function love.keypressed(k, u)
  key = Input:keypressed(k, u)

  if key == 'f2' then
    Graphics:saveScreenshot()
  elseif key == 'f3' then
    Snitch:toggle()
  elseif key == 'f5' then
    Graphics:setNextScale()
  elseif key == 'f8' then
    collectgarbage()
  elseif key == 'f10' then
    love.event.quit()
  elseif key == 'f9' then
    error("Debug crash!")
  elseif k then
    StateMachine:send( E.keypressed, key )
  end
end

function love.keyreleased(k)
  Input:keyreleased(k)
end

function love.focus(f)
  StateMachine:send( E.focus, f )
end

