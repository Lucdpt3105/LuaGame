-- src/states/win.lua
-- Win screen state

local VIRTUAL_W, VIRTUAL_H = 320, 288

local WinState = {}
local data = {}

function WinState.enter(params)
    data = params or {}
end

function WinState.update(dt)
    if love.keyboard.isDown("r") then
        return "play"
    end
    return nil
end

function WinState.draw()
    local scaleX = love.graphics.getWidth() / VIRTUAL_W
    local scaleY = love.graphics.getHeight() / VIRTUAL_H
    love.graphics.push()
    love.graphics.scale(scaleX, scaleY)

    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", 0, 0, VIRTUAL_W, VIRTUAL_H)

    love.graphics.setColor(0.2, 1, 0.3)
    love.graphics.printf("YOU WIN!", 0, 80, VIRTUAL_W, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("All coins collected & monsters slain!", 0, 110, VIRTUAL_W, "center")
    love.graphics.printf(string.format("Time: %.1f s", data.surviveTime or 0), 0, 140, VIRTUAL_W, "center")
    love.graphics.printf("Score: " .. (data.score or 0), 0, 160, VIRTUAL_W, "center")

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf("Press R to play again", 0, 195, VIRTUAL_W, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.pop()
end

return WinState
