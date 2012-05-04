
Input = {}

function Input:init()
  print("Input:init()")
  love.keyboard.setKeyRepeat( 0.500, 0.125 )
end

function Input:translate(k, u)
  local key

  if type(u) == "number" and u > 32 and u < 127 then
    key = string.char(u)
  elseif k~="rshift" and k~="lshift" and k~="ralt" and k~="lalt" then

    if k == " " then
      key = "space"
    elseif k == "return" then
      key = "enter"
    else
      key = k
    end
  end

  if key and love.keyboard.isDown("lalt", "ralt") then
    key = "alt_" .. key
  end

  return key
end

