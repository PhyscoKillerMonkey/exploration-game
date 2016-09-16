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
table.print = print_r

-- KeyPressed and released detection
love.keyboard.keysPressed = {}
love.keyboard.keysReleased = {}

function love.keyboard.wasPressed(key)
  if love.keyboard.keysPressed[key] then
    return true
  end
  return false
end

function love.keyboard.wasReleased(key)
  if love.keyboard.keysReleased[key] then
    return true
  end
  return false
end

function love.keypressed(key, scancode, isrepeat)
  love.keyboard.keysPressed[key] = true
end

function love.keyreleased(key)
  love.keyboard.keysReleased[key] = true
end

function love.keyboard.updateKeys()
  love.keyboard.keysPressed = {}
  love.keyboard.keysReleased = {}
end



-- Class stuff
function createClass(class, parent)
  class.__index = class
  parent = parent or child
  setmetatable(class, {
    __index = parent,
    __call = function (cls, ...)
      local self = setmetatable({}, cls)
      self:new(...)
      return self
    end
  })
end

local Sprite = {}
createClass(Sprite)
function Sprite:new(x, y, sheet)
  self.sheet = sheet
  self.quad = getQuad(x, y, sheet)
end
function Sprite:draw(x, y)
  love.graphics.draw(self.sheet, self.quad, x, y, 0, tileScale, tileScale)
end

local AnimatedSprite = {}
createClass(AnimatedSprite, Sprite)
function AnimatedSprite:new(x, y, sheet)
  Sprite:new(x, y, sheet)
  self.frameTimer = 0
  self.currentAnimation = ""
  self.animationNames = {}
  self.animationFrames = {}
  self.animationDurations = {}
end
function AnimatedSprite:addAnimation(name, frameDuration, frames)
  table.insert(self.animationNames, name)
  self.animationFrames[name] = {}
  self.animationDurations[name] = frameDuration
  for i, v in ipairs(frames) do
    table.insert(self.animationFrames[name], getQuad(v[1], v[2], self.sheet))
  end
end
function AnimatedSprite:updateFrame(dt)
  local name = self.currentAnimation
  if name ~= "" then
    self.frameTimer = self.frameTimer + dt
    local frames = self.animationFrames[name]
    local duration = self.animationDurations[name]
    if self.frameTimer > duration * #frames then
      self.frameTimer = 0.0001 -- Cant be 0 cause division by 0
    end
    local frame = math.ceil(self.frameTimer / duration)
    self.quad = frames[frame]
  else
    print("No animation assigned")
  end
end

Tile = {}
createClass(Tile)
function Tile:new(x, y, background)
  self.x = x
  self.y = y
  self.background = background
  self.object = nil
  self.items = {}
end

Object = {}
createClass(Object)
function Object:new(sprite, onBreak, blocking)
  self.sprite = sprite
  self.onBreak = onBreak
  self.blocking = blocking
end

Item = {}
createClass(Item)
function Item:new(sprite, name)
  self.sprite = sprite
  self.name = name
end



function love.load()
  -- Keeps everything nice and pixely
  love.graphics.setDefaultFilter("nearest")

  -- Set the font
  love.graphics.setNewFont(20)

  -- Load the tilesheets
  tileSheet = love.graphics.newImage("assets/tiles.png")
  itemSheet = love.graphics.newImage("assets/items.png")
  playerSheet = love.graphics.newImage("assets/player.png")

  tileSize = 16
  tileScale = 4
  tileDisplaySize = tileSize * tileScale

  -- Background tiles
  bgTiles = {}
  bgTiles[1] = Sprite(0, 0, tileSheet)
  bgTiles[2] = Sprite(1, 0, tileSheet)
  bgTiles[3] = Sprite(2, 0, tileSheet)
  bgTiles[4] = Sprite(3, 0, tileSheet)
  bgTiles[5] = Sprite(4, 0, tileSheet)
  bgTiles[6] = Sprite(5, 0, tileSheet)

  -- Items
  items = {}
  items[1] = Item(Sprite(0, 0, itemSheet), "Stick")
  items[2] = Item(Sprite(1, 0, itemSheet), "Log")

  -- Objects
  objects = {}
  objects[1] = Object(Sprite(0, 2, tileSheet), items[2], false)
  --objects[2] = getQuad(1, 2, tileSheet)

  -- Initalise the map
  mapWidth = 60
  mapHeight = 40

  visibleTilesWidth = 15
  visibleTilesHeight = 11

  cameraX = 1
  cameraY = 1

  map = {}
  for x = 1, mapWidth do
    map[x] = {}
    for y = 1, mapHeight do
      -- Background tile selection
      map[x][y] = Tile(x, y, bgTiles[love.math.random(1, #bgTiles)])

      -- Object selection
      local num = love.math.random(-10, #objects)
      if num > 0 then
        map[x][y].object = objects[num]
      end
    end
  end

  table.insert(map[2][3].items, items[1])

  player = {
    x = 8,
    y = 6,
    facing = 0,

    offX = 0,
    offY = 0,

    moving = "none",
    nextMove = "none",
    lastMove = "none",
    timer = 0,
    turnDuration = 0.1, -- Seconds before starting to walk

    sprite = AnimatedSprite(0, 0, playerSheet),
    breakMode = false,
    invOpen = false,
    inventory = {}
  }

  function player:update(dt)
    -- Update the turn timer
    self.timer = self.timer - dt

    for i, v in ipairs({"up", "right", "down", "left"}) do
      if love.keyboard.wasPressed(v) then
        self.lastMove = self.nextMove
        self.nextMove = v
        print(self.lastMove .. " " .. self.nextMove)
      end
      if love.keyboard.wasReleased(v) then
        self.nextMove = self.lastMove
        self.lastMove = "none"
        print(self.lastMove .. " " .. self.nextMove)
      end
    end

    if self.moving == "none" and self.nextMove ~= "none" then
      if self.nextMove == "up" then
        if self.facing ~= "up" then
          self.timer = self.turnDuration
          self.facing = "up"
        elseif self.timer <= 0 and not checkCollision(0, -1) then
          self.moving = "up"
          self.y = self.y - 1
          self.offY = 1
        end

      elseif self.nextMove == "right" then
        if self.facing ~= "right" then
          self.timer = self.turnDuration
          self.facing = "right"
        elseif self.timer <= 0 and not checkCollision(1, 0) then
          self.moving = "right"
          self.x = self.x + 1
          self.offX = -1
        end

      elseif self.nextMove == "down" then
        if self.facing ~= "down" then
          self.timer = self.turnDuration
          self.facing = "down"
        elseif self.timer <= 0 and not checkCollision(0, 1) then
          self.moving = "down"
          self.y = self.y + 1
          self.offY = -1
        end

      elseif self.nextMove == "left" then
        if self.facing ~= "left" then
          self.timer = self.turnDuration
          self.facing = "left"
        elseif self.timer <= 0 and not checkCollision(-1, 0) then
          self.moving = "left"
          self.x = self.x - 1
          self.offX = 1
        end
      end
    end

    local step = 0.05
    if self.moving == "up" then
      self.offY = self.offY - step
      self.sprite.currentAnimation = "walkU"
      if self.offY <= 0 then self.moving = "none" end

    elseif self.moving == "right" then
      self.offX = self.offX + step
      self.sprite.currentAnimation = "walkR"
      if self.offX >= 0 then self.moving = "none" end

    elseif self.moving == "down" then
      self.offY = self.offY + step
      self.sprite.currentAnimation = "walkD"
      if self.offY >= 0 then self.moving = "none" end

    elseif self.moving == "left" then
      self.offX = self.offX - step
      self.sprite.currentAnimation = "walkL"
      if self.offX <= 0 then self.moving = "none" end

    elseif self.moving == "none" then
      self.offX = 0
      self.offY = 0

      if self.facing == "up" then
        self.sprite.currentAnimation = "idleU"
      elseif self.facing == "right" then
        self.sprite.currentAnimation = "idleR"
      elseif self.facing == "down" then
        self.sprite.currentAnimation = "idleD"
      elseif self.facing == "left" then
        self.sprite.currentAnimation = "idleL"
      end
    end
  end

  player.sprite:addAnimation("idleD", 0.8, {{0, 0}, {1, 0}})
  player.sprite:addAnimation("walkD", 0.16, {{0, 1}, {0, 0}, {1, 1}, {0, 0}})
  player.sprite:addAnimation("idleR", 0.8, {{2, 0}, {3, 0}})
  player.sprite:addAnimation("walkR", 0.16, {{2, 1}, {2, 0}, {3, 1}, {2, 0}})
  player.sprite:addAnimation("idleU", 0.8, {{0, 2}, {1, 2}})
  player.sprite:addAnimation("walkU", 0.16, {{0, 3}, {0, 2}, {1, 3}, {0, 2}})
  player.sprite:addAnimation("idleL", 0.8, {{2, 2}, {3, 2}})
  player.sprite:addAnimation("walkL", 0.16, {{2, 3}, {2, 2}, {3, 3}, {2, 2}})
  player.sprite.currentAnimation = "idleU"

  for i = 1, 5 do
    player.inventory[i] = { item = nil, count = 0 }
  end
end

function getQuad(x, y, image)
  return love.graphics.newQuad(
    x * tileSize,
    y * tileSize,
    tileSize,
    tileSize,
    image:getWidth(),
    image:getHeight())
end

function checkCollision(xOff, yOff)
  x = player.x + (xOff or 0)
  y = player.y + (yOff or 0)

  -- Check that isnt out of the map
  if x < 1 or x > mapWidth or y < 1 or y > mapHeight then return true end

  if map[x] then
    local ob = map[x][y]
    if ob and ob.object then
      return true
    end
    return false
  end
  return false
end



function love.update(dt)
  -- Exit on escape
  if love.keyboard.isDown("escape") then
    love.event.push("quit")
  end

  -- Player movement
  player.sprite:updateFrame(dt)
  player:update(dt)

  -- Position the camera correctly
  if player.x >= 8 and player.x <= mapWidth - 7 then
    cameraX = (player.x - 8 + player.offX) * tileDisplaySize
    if cameraX < 0 then cameraX = 0 end
    if cameraX > (mapWidth - 15) * tileDisplaySize then cameraX = (mapWidth - 15) * tileDisplaySize end
  end
  if player.y >= 6 and player.y <= mapHeight - 5 then
    cameraY = (player.y - 6 + player.offY) * tileDisplaySize
    if cameraY < 0 then cameraY = 0 end
    if cameraY > (mapHeight - 11) * tileDisplaySize then cameraY = (mapHeight - 11) * tileDisplaySize end
  end

  -- See if there is an item to pick up
  local square = map[player.x][player.y]
  for i = #square.items, 1, -1 do
    local item = square.items[i]
    print(i, item)

    local firstSame, firstEmpty = 0, 0
    -- Loop through the inventory finding the first occurance of this item and first empty slot
    for slot, v in ipairs(player.inventory) do
      if v.item and v.item.name == item.name and firstSame == 0 then
        firstSame = slot
      elseif v.item == nil and firstEmpty == 0 then
        firstEmpty = slot
      end
    end

    if firstSame > 0 then
      -- If the item is somewhere in the inventory then put it there and remove from the floor
      player.inventory[firstSame].count = player.inventory[firstSame].count + 1
      table.remove(square.items, #square.items)
    elseif firstEmpty > 0 then
      -- Else put it in the first empty slot and remove from the floor
      local slot = player.inventory[firstEmpty]
      slot.item = item
      slot.count = 1
      table.remove(square.items, #square.items)
    end
  end

  -- Check if we should break a block
  if love.keyboard.wasPressed("x") then
    local bx = player.x
    local by = player.y
    if player.facing == "up" and player.y > 1 then
      by = player.y - 1

    elseif player.facing == "right" and player.x < mapWidth then
      bx = player.x + 1

    elseif player.facing == "down" and player.y < mapHeight then
      by = player.y + 1

    elseif player.facing == "left" and player.x > 1 then
      bx = player.x - 1
    end

    print("Break " .. bx .. " " .. by)

    local square = map[bx][by]
    if square.object and square.object.onBreak then
      table.insert(square.items, square.object.onBreak)
      square.object = nil
    end
  end

  -- Toggle inventory
  if love.keyboard.wasPressed("z") then
    player.invOpen = not player.invOpen
  end

  -- Reset the key pressed/released lists
  love.keyboard.updateKeys()
end



function love.draw()
  for x = 1, mapWidth do
    for y = 1, mapHeight do
      local tile = map[x][y]
      local drawX = (x-1) * tileDisplaySize - cameraX
      local drawY = (y-1) * tileDisplaySize - cameraY
      --[[
      table.print(tile)
      error()]]
      -- Draw background
      local bg = tile.background
      bg:draw(drawX, drawY)

      -- Draw object
      local ob = tile.object
      if ob then
        ob.sprite:draw(drawX, drawY)
      end

      -- Draw items
      for i, v in ipairs(tile.items) do
        v.sprite:draw(drawX, drawY)
      end
    end
  end

  -- Draw player
  player.sprite:draw((player.x-1+player.offX) * tileDisplaySize - cameraX,
  (player.y-1+player.offY) * tileDisplaySize - cameraY)

  if player.breakMode then
    -- Draw break halo
    love.graphics.rectangle("line", (player.x-cameraX) * tileDisplaySize, (player.y-cameraY-1) * tileDisplaySize, tileDisplaySize, tileDisplaySize)
    love.graphics.rectangle("line", (player.x-cameraX+1) * tileDisplaySize, (player.y-cameraY) * tileDisplaySize, tileDisplaySize, tileDisplaySize)
    love.graphics.rectangle("line", (player.x-cameraX) * tileDisplaySize, (player.y-cameraY+1) * tileDisplaySize, tileDisplaySize, tileDisplaySize)
    love.graphics.rectangle("line", (player.x-cameraX-1) * tileDisplaySize, (player.y-cameraY) * tileDisplaySize, tileDisplaySize, tileDisplaySize)
  end

  if player.invOpen then
    -- Draw the inventory
    local invXOff = 200
    local invYOff = 200
    local invSize = 72
    local invPadding = (invSize - tileDisplaySize) / 2

    local invMargin = 12
    for i = 1, 5 do
      local sx = invXOff + (i-1) * (invSize + invMargin)
      local sy = invYOff
      love.graphics.setColor(180, 180, 180, 200)
      love.graphics.rectangle("fill", sx, sy, invSize, invSize)
      love.graphics.setColor(255, 255, 255)
      local slot = player.inventory[i]
      local item = slot.item
      if item then
        item.sprite:draw(sx+invPadding, sy+invPadding)
        love.graphics.print(slot.count, sx, sy, 0, 1, 1)
      end
    end
  end

  -- Write debug text
  love.graphics.print("PX: " .. player.x .. " PY: " .. player.y .. " SX: " .. cameraX .. " SY: " .. cameraY, 10, 10)

  --[[
  local inv = "Inventory: "
  for i,v in ipairs(player.inventory) do
    if v.item then
      inv = inv .. i .. "[" .. v.item.name .. " x " .. v.count .. "] "
    else
      inv = inv .. i .. "[" .. "Empty] "
    end
  end
  love.graphics.print(inv, 10, 40)
  --]]
end
