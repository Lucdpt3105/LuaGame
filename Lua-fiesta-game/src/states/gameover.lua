-- src/states/gameover.lua
-- Game over screen state

local VIRTUAL_W, VIRTUAL_H = 320, 288

local GameOverState = {}
local data = {}

function GameOverState.enter(params)
    data = params or {}
end

function GameOverState.update(dt)
    if love.keyboard.isDown("r") then
        return "play"
    end
    return nil
end

function GameOverState.draw()
    local scaleX = love.graphics.getWidth() / VIRTUAL_W
    local scaleY = love.graphics.getHeight() / VIRTUAL_H
    love.graphics.push()
    love.graphics.scale(scaleX, scaleY)

    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", 0, 0, VIRTUAL_W, VIRTUAL_H)

    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.printf("CAUGHT!", 0, 85, VIRTUAL_W, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(string.format("Time:  %.1f s", data.surviveTime or 0),  0, 118, VIRTUAL_W, "center")
    love.graphics.printf("Score: " .. (data.score or 0),                          0, 138, VIRTUAL_W, "center")
    love.graphics.printf(string.format("Best Time:  %.1f s", data.bestTime or 0), 0, 162, VIRTUAL_W, "center")
    love.graphics.printf("Best Score: " .. (data.bestScore or 0),                 0, 182, VIRTUAL_W, "center")

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf("Press R to retry", 0, 210, VIRTUAL_W, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.pop()
end

return GameOverState
