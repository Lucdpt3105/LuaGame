local MathUtils = require("src.utils.math")

local Arrow = {}
Arrow.__index = Arrow

local image

function Arrow.new(x, y, dirX, dirY)
    local self = setmetatable({}, Arrow)
    if not image then
        image = love.graphics.newImage("assets/sprites/player/Arrow.png")
    end

    local length = math.sqrt(dirX * dirX + dirY * dirY)
    if length == 0 then
        dirX, dirY, length = 1, 0, 1
    end

    self.x = x
    self.y = y
    self.dirX = dirX / length
    self.dirY = dirY / length
    self.speed = 360
    self.life = 1.25
    self.radius = 8
    self.image = image
    self.rotation = MathUtils.atan2(self.dirY, self.dirX)
    self.scale = 0.5
    self.ox = self.image:getWidth() / 2
    self.oy = self.image:getHeight() / 2
    return self
end

function Arrow:update(dt, map)
    self.life = self.life - dt
    self.x = self.x + self.dirX * self.speed * dt
    self.y = self.y + self.dirY * self.speed * dt

    if self.life <= 0 then
        return true
    end

    if not map:isInside(self.x, self.y, 8) then
        return true
    end

    return map:collides(self.x, self.y, self.radius * 2)
end

function Arrow:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        self.image,
        self.x,
        self.y,
        self.rotation,
        self.scale,
        self.scale,
        self.ox,
        self.oy
    )
end

function Arrow:touches(targetX, targetY, radius)
    local dx = self.x - targetX
    local dy = self.y - targetY
    return math.sqrt(dx * dx + dy * dy) <= (self.radius + radius)
end

return Arrow
