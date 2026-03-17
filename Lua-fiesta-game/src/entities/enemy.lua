local Enemy = {}
Enemy.__index = Enemy

local image
local quads
local FRAME_FPS = 5

local function ensureAssets()
    if not image then
        image = love.graphics.newImage("assets/sprites/enemies/enemy.png")
        local frameH = image:getHeight()
        local frameW = frameH
        local count  = math.floor(image:getWidth() / frameW)
        quads = {}
        for i = 0, count - 1 do
            quads[i + 1] = love.graphics.newQuad(
                i * frameW, 0, frameW, frameH,
                image:getWidth(), image:getHeight()
            )
        end
    end
end

function Enemy.new(x, y)
    ensureAssets()
    local self = setmetatable({}, Enemy)
    self.x     = x
    self.y     = y
    self.speed = 45
    self.size  = 20
    self.hp    = 3
    self.maxHp = 3

    local angle       = math.random() * math.pi * 2
    self.dirX         = math.cos(angle)
    self.dirY         = math.sin(angle)
    self.changeTimer  = math.random() * 1.5 + 0.5
    self.animTimer    = math.random() * 2
    self.facing       = 1
    self.hitFlash     = 0

    self.frameH = image:getHeight()
    self.drawScale = self.size / self.frameH * 1.6
    self.ox = self.frameH / 2
    self.oy = self.frameH / 2
    return self
end

function Enemy:update(dt, map)
    if not self:isAlive() then return end

    self.changeTimer = self.changeTimer - dt
    self.animTimer   = self.animTimer + dt
    self.hitFlash    = math.max(0, self.hitFlash - dt)

    if self.changeTimer <= 0 then
        local angle  = math.random() * math.pi * 2
        self.dirX    = math.cos(angle)
        self.dirY    = math.sin(angle)
        self.changeTimer = math.random() * 1.5 + 0.8
    end

    local newX = self.x + self.dirX * self.speed * dt
    local newY = self.y + self.dirY * self.speed * dt

    if not map:collides(newX, self.y, self.size) then
        self.x = newX
    else
        self.dirX = -self.dirX
        self.changeTimer = 0.2
    end
    if not map:collides(self.x, newY, self.size) then
        self.y = newY
    else
        self.dirY = -self.dirY
        self.changeTimer = 0.2
    end

    if self.dirX ~= 0 then
        self.facing = self.dirX > 0 and 1 or -1
    end
end

function Enemy:draw()
    if not self:isAlive() then return end

    local frameIndex = math.floor(self.animTimer * FRAME_FPS) % #quads + 1

    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.ellipse("fill", self.x, self.y + 12, 10, 3)

    if self.hitFlash > 0 then
        love.graphics.setColor(1, 0.4, 0.4)
    else
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.draw(
        image, quads[frameIndex],
        self.x, self.y + 2,
        0,
        self.facing * self.drawScale, self.drawScale,
        self.ox, self.oy
    )

    -- HP bar
    if self.hp < self.maxHp then
        local barW = 20
        local barH = 3
        local bx   = self.x - barW / 2
        local by   = self.y - 18
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", bx, by, barW, barH)
        love.graphics.setColor(0.9, 0.25, 0.2)
        love.graphics.rectangle("fill", bx, by, barW * (self.hp / self.maxHp), barH)
    end
end

function Enemy:hit()
    self.hp = self.hp - 1
    self.hitFlash = 0.15
    return self.hp <= 0
end

function Enemy:touches(player)
    if not self:isAlive() then return false end
    local dx = self.x - player.x
    local dy = self.y - player.y
    return math.sqrt(dx * dx + dy * dy) < (self.size * 0.5 + player.size * 0.5)
end

function Enemy:isAlive()
    return self.hp > 0
end

function Enemy:kill()
    self.hp = 0
end

function Enemy:getHitRadius()
    return self.size * 0.5
end

return Enemy
