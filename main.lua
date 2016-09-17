local util = require "util"
table.print = util.printTable
love.keyboard.wasPressed = util.wasPressed
love.keyboard.wasReleased = util.wasReleased
love.keyboard.updateKeys = util.updateKeys

local c = require "classes"



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
  bgTiles[1] = c.Sprite(0, 0, tileSheet)
  bgTiles[2] = c.Sprite(1, 0, tileSheet)
  bgTiles[3] = c.Sprite(2, 0, tileSheet)
  bgTiles[4] = c.Sprite(3, 0, tileSheet)
  bgTiles[5] = c.Sprite(4, 0, tileSheet)
  bgTiles[6] = c.Sprite(5, 0, tileSheet)

  -- Items
  items = {}
  items[1] = c.Item(c.Sprite(0, 0, itemSheet), "Stick")
  items[2] = c.Item(c.Sprite(1, 0, itemSheet), "Log")

  -- Objects
  objects = {}
  objects[1] = c.Object(c.Sprite(0, 2, tileSheet), items[2], true)
  objects[2] = c.Object(c.Sprite(1, 2, tileSheet), items[2], true)
  objects[3] = c.Object(c.Sprite(4, 2, tileSheet), items[2], false)
  objects[3.1] = c.Object(c.Sprite(4, 3, tileSheet), items[2], true)

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
      map[x][y] = c.Tile(x, y, bgTiles[love.math.random(1, #bgTiles)])
    end
  end

  for x = 1, mapWidth do
    for y = 1, mapHeight do
      -- Object selection
      local num = love.math.random(-20, #objects)
      if num > 0 and map[x][y].object == nil then
        map[x][y].object = objects[num]
        if num == 3 and y < mapHeight then
          map[x][y+1].object = objects[3.1]
          local xx, yy = x, y
          map[x][y].links = {map[x][y+1]}
          map[x][y+1].links = {map[x][y]}
        end
      end
    end
  end

  table.insert(map[2][3].items, items[1])

  player = require "player"
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
    if ob and ob.object and ob.object.blocking then
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

    if map[bx][by].object then
      local s = { map[bx][by] }
      if s[1].links then
        for i, v in ipairs(s[1].links) do
          table.insert(s, v)
        end
      end

      for i, v in ipairs(s) do
        if v.object and v.object.onBreak then
          table.insert(v.items, v.object.onBreak)
          v.object = nil
        end
      end
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
  local x = math.floor(cameraX / tileDisplaySize) + 1
  local y = math.floor(cameraY / tileDisplaySize) + 1

  for x = x, x + visibleTilesWidth do
    for y = y, y + visibleTilesHeight do
      local tile = map[x][y]
      local drawX = (x-1) * tileDisplaySize - cameraX
      local drawY = (y-1) * tileDisplaySize - cameraY

      -- Draw background
      local bg = tile.background
      bg:draw(drawX, drawY)
    end
  end

  -- Draw player
  player.sprite:draw((player.x-1+player.offX) * tileDisplaySize - cameraX,
  (player.y-1+player.offY) * tileDisplaySize - cameraY)

  for x = x, x + visibleTilesWidth do
    for y = y, y + visibleTilesHeight do
      local tile = map[x][y]
      local drawX = (x-1) * tileDisplaySize - cameraX
      local drawY = (y-1) * tileDisplaySize - cameraY

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
