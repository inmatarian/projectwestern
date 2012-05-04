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
  "tilelayer", "tile", "sprite", "world", "menuscreen"
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

function Snitch:update (dt)
  if not self.visible then return end
  dt = dt + Snitch.dt
  if dt >= 1 then
    dt = dt - 1
    local fps = love.timer.getFPS()
    local garbage = collectgarbage("count")
    self:writeln("FPS:", fps, "Mem:", math.floor(garbage).."k")
  end
  Snitch.dt = dt
end

--------------------------------------------------------------------------------

PlayState = State:clone {}

function PlayState:enter()
  self.screen = TextWindow( 0, 0, floor(Graphics.gameWidth/8), floor(Graphics.gameHeight/8) )
  self.screen:frame("double", Color.GRAY)
  self.world = World("level/testworld.lua")
  self:addLayer(self.screen, self.world, Snitch())
end

function PlayState:yield()
  while true do
    local lastKey = coroutine.yield(true)
    if lastKey then
      return lastKey
    end
  end
end

function PlayState:keypressed(key)
  if key == "enter" then
    StateMachine:push( MenuScreenState() )
  elseif key == "f7" then
    StateMachine:push( BattleState() )
  else
    self.world:runAllLogic( key )
    Game.Hugo:recoverMagicStep(1.0)
    Game.Hugo:recoverHealthStep(1.0)
  end
end

--------------------------------------------------------------------------------

BattleState = State:clone {


}

function BattleState:enter()
  self.screen = TextWindow( 0, 0, 30, floor(Graphics.gameHeight/8) )
  self.screen:frame("double", Color.GRAY)
  self.world = TileLayer.loadMap("level/testbattle.lua", 8, 8, 224, 224)
  self.world:selfCenter()
  self.stats = BattleStatsWindow( 30, 0, 10, 30 )
  self:addLayer(self.screen, self.world, self.stats, Snitch())
end

function BattleState:keypressed(key)
  if key == "escape" then
    StateMachine:pop()
  end
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

Game = {}

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
  StateMachine:push( PlayState() )
end

function love.update(dt)
  StateMachine:send( E.update, dt )
end

function love.draw()
  Graphics:start()
  StateMachine:send( E.draw, dt )
  Graphics:stop()
end

function love.keypressed(k, u)
  local key = Input:translate(k, u)

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

function love.focus(f)
  StateMachine:send( E.focus, f )
end
