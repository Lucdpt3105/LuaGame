local MapData = require("src.world.map_data")

local Map = {}
Map.__index = Map

-- ── Static helpers (no instance needed) ─────────────────────
function Map.getCoinCount(mapIndex)
    return #MapData.COINS[mapIndex]
end

function Map.getEnemyCount(mapIndex)
    return #MapData.ENEMIES[mapIndex]
end

function Map.getNumMaps()
    return MapData.NUM_MAPS
end

-- ── Constructor ──────────────────────────────────────────────
function Map.new(mapIndex)
    local self = setmetatable({}, Map)
    self.mapIndex = mapIndex or 1
    self.tiles    = MapData.MAPS[self.mapIndex]
    self.tileSize = MapData.TILE_SIZE
    self.width    = #self.tiles[1] * self.tileSize
    self.height   = #self.tiles   * self.tileSize
    self.groundImage = love.graphics.newImage("assets/tiles/ground.png")
    self.treeImage  = love.graphics.newImage("assets/tiles/tree.png")
    self.treeScaleX = self.tileSize / self.treeImage:getWidth()
    self.treeScaleY = self.tileSize / self.treeImage:getHeight()
    return self
end

-- ── Helpers used by states ───────────────────────────────────
function Map:getWidth()  return self.width  end
function Map:getHeight() return self.height end

function Map:isInside(px, py, padding)
    padding = padding or 0
    return px >= -padding and py >= -padding
        and px <= self.width + padding and py <= self.height + padding
end

function Map:getTileAt(px, py)
    local tx = math.floor(px / self.tileSize) + 1
    local ty = math.floor(py / self.tileSize) + 1
    return self.tiles[ty] and self.tiles[ty][tx]
end

function Map:getPortalDest()
    return MapData.PORTAL_DEST[self.mapIndex]
end

function Map:getCoinPositions()
    local out = {}
    for _, c in ipairs(MapData.COINS[self.mapIndex]) do
        table.insert(out, {
            x = (c[1] - 1) * self.tileSize + self.tileSize / 2,
            y = (c[2] - 1) * self.tileSize + self.tileSize / 2,
        })
    end
    return out
end

function Map:getEnemyPositions()
    return MapData.ENEMIES[self.mapIndex]
end

-- ── Draw ─────────────────────────────────────────────────────
function Map:draw()
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
