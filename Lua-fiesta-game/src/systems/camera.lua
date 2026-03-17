-- src/systems/camera.lua
-- Camera system with follow + clamping

local Camera = {}
Camera.__index = Camera

function Camera.new(virtualW, virtualH)
    local self = setmetatable({}, Camera)
    self.x = 0
    self.y = 0
    self.virtualW = virtualW
    self.virtualH = virtualH
    return self
end

function Camera:follow(target, mapWidth, mapHeight)
    local maxCamX = math.max(0, mapWidth - self.virtualW)
    local maxCamY = math.max(0, mapHeight - self.virtualH)
    self.x = target.x - self.virtualW / 2
    self.y = target.y - self.virtualH / 2
    self.x = math.max(0, math.min(self.x, maxCamX))
    self.y = math.max(0, math.min(self.y, maxCamY))
end

function Camera:apply()
    love.graphics.push()
    love.graphics.translate(-self.x, -self.y)
end

function Camera:release()
    love.graphics.pop()
end

return Camera
