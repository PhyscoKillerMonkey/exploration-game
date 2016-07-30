function love.load()
  -- Keeps everything nice and pixely
  love.graphics.setDefaultFilter("nearest")
  
  -- Set the font
  love.graphics.setNewFont(20)
  
  -- Load the tilesheets
  tilesetImage = love.graphics.newImage("assets/medievalTileset.png")
  itemSheet = love.graphics.newImage("assets/items.png")
  tileSize = 16
  
  -- Background tiles
  bgTiles = {}
  bgTiles[1] = getQuad(1, 1, tilesetImage)
  bgTiles[2] = getQuad(3, 0, tilesetImage)
  bgTiles[3] = getQuad(3, 1, tilesetImage)
  
  -- Objects
  obTiles = {}
  obTiles[1] = getQuad(13, 5, tilesetImage)
  obTiles[2] = getQuad(9, 7, tilesetImage)
  
  -- Items
  items = {}
  items[1] = getQuad(0, 0, itemSheet)
  items[2] = getQuad(1, 0, itemSheet)
  
  -- Initalise the map
  mapWidth = 60
  mapHeight = 40
  
  tileScale = 4
  
  visibleTilesWidth = 15
  visibleTilesHeight = 11
  
  cameraX = 0
  cameraY = 0
  
  map = {}
  for x = 1, mapWidth do
    map[x] = {}
    for y = 1, mapHeight do
      map[x][y] = love.math.random(1, #bgTiles)
    end
  end
  
  objects = {}
  for x = 1, mapWidth do
    objects[x] = {}
    for y = 1, mapHeight do
      objects[x][y] = love.math.random(-10, #obTiles)
    end
  end
  
  groundItems = {}
  for x = 1, mapWidth do
    groundItems[x] = {}
    for y = 1, mapHeight do
      groundItems[x][y] = 0
    end
  end
  groundItems[2][3] = 1
  
  player = {
    x = 0,
    y = 0,
    moveCooldown = 0.2, -- In seconds
    moveTimer = 0,
    img = love.graphics.newImage("assets/player.png"),
    breakMode = false,
    inventory = {}
  }
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
  xOff = xOff or 0
  yOff = yOff or 0
  local o = objects[player.x+xOff+1]
  if o ~= nil then
    o = o[player.y+yOff+1]
    if o ~= nil and o > 0 then
      return true
    else
      return false
    end
  end
end

function love.update(dt)
  -- Exit on escape
  if love.keyboard.isDown("escape") then
    love.event.push("quit")
  end
  
  -- Player & camera movement
  playerXOffset = player.x - cameraX
  playerYOffset = player.y - cameraY
  
  if player.moveTimer >= player.moveCooldown and not player.breakMode then
    if love.keyboard.isDown("up") and not checkCollision(0, -1) then
      player.y = player.y - 1
      if player.y < 0 then player.y = 0 end
      
      if playerYOffset <= 5 then cameraY = cameraY - 1 end
      if cameraY < 0 then
        cameraY = 0
      end
      
      player.moveTimer = 0
    end
    
    if love.keyboard.isDown("right") and not checkCollision(1, 0) then
      player.x = player.x + 1
      if player.x >= mapWidth then player.x = mapWidth-1 end
      
      if playerXOffset >= 7 then cameraX = cameraX + 1 end
      if cameraX > mapWidth - visibleTilesWidth then
        cameraX = mapWidth - visibleTilesWidth
      end
      
      player.moveTimer = 0
    end
    
    if love.keyboard.isDown("down") and not checkCollision(0, 1) then
      player.y = player.y + 1
      if player.y >= mapHeight then player.y = mapHeight-1 end
      
      if playerYOffset >= 5 then cameraY = cameraY + 1 end
      if cameraY > mapHeight - visibleTilesHeight then
        cameraY = mapHeight - visibleTilesHeight
      end
      
      player.moveTimer = 0
    end
    
    if love.keyboard.isDown("left") and not checkCollision(-1, 0) then
      player.x = player.x - 1
      if player.x < 0 then player.x = 0 end
      
      if playerXOffset <= 7 then cameraX = cameraX - 1 end
      if cameraX < 0 then
        cameraX = 0
      end
      
      player.moveTimer = 0
    end
  end
  
  -- See if there is an item to pick up
  if groundItems[player.x+1][player.y+1] > 0 then
    table.insert(player.inventory, groundItems[player.x+1][player.y+1])
    groundItems[player.x+1][player.y+1] = 0
  end
    
  -- Check if in break mode
  if love.keyboard.isDown("x") then
    player.breakMode = true
  else
    player.breakMode = false 
  end
  
  if player.breakMode then
    local bx, by = 0
    
    if love.keyboard.isDown("up") and player.y > 0 then
      bx = player.x+1
      by = player.y
      objects[bx][by] = 0
      groundItems[bx][by] = 2
    end
    
    if love.keyboard.isDown("right") and player.x < mapWidth - 1 then
      bx = player.x+2
      by = player.y+1
      objects[bx][by] = 0
      groundItems[bx][by] = 2
    end
    
    if love.keyboard.isDown("down") and player.y < mapHeight - 1 then
      bx = player.x+1
      by = player.y+2
      objects[bx][by] = 0
      groundItems[bx][by] = 2
    end
    
    if love.keyboard.isDown("left") and player.x > 0 then
      bx = player.x
      by = player.y+1
      objects[bx][by] = 0
      groundItems[bx][by] = 2
    end
  end

  -- Update the player move timer
  player.moveTimer = player.moveTimer + dt
end

function love.draw()
  local tileDisplaySize = tileSize * tileScale
  
  for x = 1, visibleTilesWidth do
    for y = 1, visibleTilesHeight do
      -- Draw background
      love.graphics.draw(tilesetImage, bgTiles[map[x+cameraX][y+cameraY]], (x-1) * tileDisplaySize, (y-1) * tileDisplaySize, 0, tileScale, tileScale)
      
      -- Draw objects
      object = objects[x+cameraX][y+cameraY]
      if object > 0 then
        love.graphics.draw(tilesetImage, obTiles[object], (x-1) * tileDisplaySize, (y-1) * tileDisplaySize, 0, tileScale, tileScale)
      end
      
      -- Draw items
      item = groundItems[x+cameraX][y+cameraY]
      if item > 0 then
        love.graphics.draw(itemSheet, items[item], (x-1) * tileDisplaySize, (y-1) * tileDisplaySize, 0, tileScale, tileScale)
      end
    end
  end
  
  -- Draw player
  love.graphics.draw(player.img, (player.x-cameraX) * tileDisplaySize, (player.y-cameraY) * tileDisplaySize, 0, tileScale, tileScale)
  
  if player.breakMode then
    -- Draw break halo
    love.graphics.rectangle("line", (player.x-cameraX) * tileDisplaySize, (player.y-cameraY-1) * tileDisplaySize, tileDisplaySize, tileDisplaySize)
    love.graphics.rectangle("line", (player.x-cameraX+1) * tileDisplaySize, (player.y-cameraY) * tileDisplaySize, tileDisplaySize, tileDisplaySize)
    love.graphics.rectangle("line", (player.x-cameraX) * tileDisplaySize, (player.y-cameraY+1) * tileDisplaySize, tileDisplaySize, tileDisplaySize)
    love.graphics.rectangle("line", (player.x-cameraX-1) * tileDisplaySize, (player.y-cameraY) * tileDisplaySize, tileDisplaySize, tileDisplaySize)
  end
  
  -- Write debug text
  love.graphics.print("PX: " .. player.x .. " PY: " .. player.y .. " SX: " .. cameraX .. " SY: " .. cameraY, 10, 10)
  
  local inv = "Inventory: "
  if (#player.inventory > 0) then
    for i,v in ipairs(player.inventory) do
      inv = inv .. i .. "[" .. v .. "] "
    end
  else
    inv = inv .. "Empty"
  end
  love.graphics.print(inv, 10, 40)
end