function print_r ( t )
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end



-- KeyPressed and released detection
local keysPressed = {}
local keysReleased = {}

function wasPressed(key)
  if keysPressed[key] then
    return true
  end
  return false
end

function wasReleased(key)
  if keysReleased[key] then
    return true
  end
  return false
end

function love.keypressed(key, scancode, isrepeat)
  keysPressed[key] = true
end

function love.keyreleased(key)
  keysReleased[key] = true
end

function updateKeys()
  keysPressed = {}
  keysReleased = {}
end



local util = {
  printTable = print_r,
  wasPressed = wasPressed,
  wasReleased = wasReleased,
  updateKeys = updateKeys
}
return util
