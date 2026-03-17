local Map = {}
Map.__index = Map

-- ── Tile legend ─────────────────────────────────────────────
--   0 = floor   1 = tree/wall   2 = portal (passable, triggers map switch)
-- ────────────────────────────────────────────────────────────

-- Two 20-column × 16-row maps.  Both are larger than the 320×288 viewport,
-- so a scrolling camera is needed (handled in main.lua).
local MAPS = {
    -- MAP 1 : green forest.  Portal at row 8, col 19 → leads to map 2.
    {
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,1,1,0,0,0,0,1,0,0,0,0,1,1,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,1,0,0,0,1,1,0,0,0,0,1,0,0,0,1,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,1,0,0,0,0,0,1,1,0,0,0,0,1,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,1},
        {1,0,1,1,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,1,0,0,0,1,1,0,0,0,0,0,0,1,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,1,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,1},
        {1,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    },
    -- MAP 2 : darker forest.  Portal at row 8, col 1 → leads back to map 1.
    {
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,1,1,1,0,0,0,0,1,1,1,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1},
        {1,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,1},
        {1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,1,0,0,1},
        {2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,1,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1,0,1},
        {1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,1},
        {1,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    },
}

-- Gold-coin spawn positions per map, stored as {tileCol, tileRow} (1-indexed).
-- All positions verified to be floor tiles (0).
local MAP_COINS = {
    { {5,4},{9,5},{13,7},{3,10},{7,12},{15,4},{17,10},{11,13},{4,6},{16,8},{8,11},{12,3} },
    { {3,2},{8,2},{12,4},{18,4},{6,6},{14,6},{3,10},{15,10},{7,12},{17,12},{6,14},{13,14} },
}

-- Enemy spawn positions per map as world coordinates {wx, wy}.
local MAP_ENEMIES = {
    { {11*32+16, 6*32+16}, {7*32+16, 11*32+16} },
    { {9*32+16,  5*32+16}, {14*32+16, 12*32+16} },
}

-- Where the player arrives after stepping through a portal.
-- mapIndex = destination map;  spawnX/Y = world spawn position in that map.
local PORTAL_DEST = {
    { mapIndex = 2, spawnX = 3*32+16, spawnY = 8*32-16 },   -- map 1 → map 2
    { mapIndex = 1, spawnX = 16*32+16, spawnY = 8*32-16 },  -- map 2 → map 1
}

-- ── Static helpers (no instance needed) ─────────────────────
function Map.getCoinCount(mapIndex)
    return #MAP_COINS[mapIndex]
end

function Map.getEnemyCount(mapIndex)
    return #MAP_ENEMIES[mapIndex]
end

-- ── Constructor ──────────────────────────────────────────────
function Map.new(mapIndex)
    local self = setmetatable({}, Map)
    self.mapIndex = mapIndex or 1
    self.tiles    = MAPS[self.mapIndex]
    self.tileSize = 32
    self.width    = #self.tiles[1] * self.tileSize
    self.height   = #self.tiles   * self.tileSize
    self.groundImage = love.graphics.newImage("ground.png")
    self.treeImage  = love.graphics.newImage("tree.png")
    self.treeScaleX = self.tileSize / self.treeImage:getWidth()
    self.treeScaleY = self.tileSize / self.treeImage:getHeight()
    return self
end

-- ── Helpers used by main.lua ─────────────────────────────────
function Map:getWidth()  return self.width  end
function Map:getHeight() return self.height end

function Map:isInside(px, py, padding)
    padding = padding or 0
    return px >= -padding and py >= -padding
        and px <= self.width + padding and py <= self.height + padding
end

-- Returns the tile value at world position (px, py), or nil if out-of-bounds.
function Map:getTileAt(px, py)
    local tx = math.floor(px / self.tileSize) + 1
    local ty = math.floor(py / self.tileSize) + 1
    return self.tiles[ty] and self.tiles[ty][tx]
end

-- Returns the portal destination table for the current map.
function Map:getPortalDest()
    return PORTAL_DEST[self.mapIndex]
end

-- Returns a list of {x, y} world-centre positions for coin spawns.
function Map:getCoinPositions()
    local out = {}
    for _, c in ipairs(MAP_COINS[self.mapIndex]) do
        table.insert(out, {
            x = (c[1] - 1) * self.tileSize + self.tileSize / 2,
            y = (c[2] - 1) * self.tileSize + self.tileSize / 2,
        })
    end
    return out
end

-- Returns a list of {wx, wy} world positions for enemy spawns.
function Map:getEnemyPositions()
    return MAP_ENEMIES[self.mapIndex]
end

-- ── Draw ─────────────────────────────────────────────────────
function Map:draw()
    -- Ground background (map 1 = bright green, map 2 = darker olive)
    if self.mapIndex == 1 then
        love.graphics.setColor(0.35, 0.58, 0.26)
    else
        love.graphics.setColor(0.25, 0.42, 0.22)
    end
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    local groundW = self.groundImage:getWidth()
    local groundH = self.groundImage:getHeight()
    love.graphics.setColor(1, 1, 1, self.mapIndex == 1 and 0.22 or 0.16)
    for drawY = 0, self.height, groundH - 32 do
        for drawX = 0, self.width, groundW - 64 do
            love.graphics.draw(self.groundImage, drawX, drawY)
        end
    end

    for row = 1, #self.tiles do
        for col = 1, #self.tiles[row] do
            local tile  = self.tiles[row][col]
            local drawX = (col - 1) * self.tileSize
            local drawY = (row - 1) * self.tileSize

            if tile == 1 then
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(self.treeImage, drawX, drawY, 0,
                    self.treeScaleX, self.treeScaleY)
            elseif tile == 2 then
                -- Portal: glowing crystal gate
                local pulse = 0.5 + 0.5 * math.sin((love.timer and love.timer.getTime() or 0) * 4)
                love.graphics.setColor(0.26, 0.12, 0.36)
                love.graphics.rectangle("fill", drawX + 5, drawY + 6, self.tileSize - 10, self.tileSize - 6, 8, 8)
                love.graphics.setColor(0.7, 0.5, 1.0, 0.25 + 0.35 * pulse)
                love.graphics.circle("fill", drawX + self.tileSize / 2, drawY + self.tileSize / 2, 12 + pulse * 3)
                love.graphics.setColor(0.85, 0.74, 1.0)
                love.graphics.rectangle("line", drawX + 5, drawY + 6, self.tileSize - 10, self.tileSize - 6, 8, 8)
            end
        end
    end
    love.graphics.setColor(1, 1, 1)
end

-- ── Collision ────────────────────────────────────────────────
-- Only tile == 1 (tree/wall) is solid; tile == 2 (portal) is passable.
function Map:collides(px, py, size)
    local half   = size / 2
    local left   = px - half
    local right  = px + half
    local top    = py - half
    local bottom = py + half
    local ts     = self.tileSize

    local function solid(wx, wy)
        local tx = math.floor(wx / ts) + 1
        local ty = math.floor(wy / ts) + 1
        return (self.tiles[ty] and self.tiles[ty][tx]) == 1
    end

    return solid(left, top) or solid(right, top)
        or solid(left, bottom) or solid(right, bottom)
end

return Map
