-- src/systems/hud.lua
-- HUD overlay drawing

local HUD = {}

function HUD.draw(virtualW, virtualH, surviveTime, score, map, progress)
    local collectedCoins, totalCoins, killedMonsters, totalMonsters = 
        progress.collectedCoins, progress.totalCoins, 
        progress.killedMonsters, progress.totalMonsters

    love.graphics.setColor(0.08, 0.11, 0.09, 0.85)
    love.graphics.rectangle("fill", 6, 6, virtualW - 12, 28, 8, 8)
    love.graphics.rectangle("fill", 6, virtualH - 30, virtualW - 12, 18, 8, 8)

    love.graphics.setColor(0.95, 0.96, 0.88)
    love.graphics.print(string.format("Time %.1fs", surviveTime), 14, 14)

    love.graphics.setColor(1, 0.84, 0.18)
    love.graphics.print("Score " .. score, 88, 14)

    love.graphics.setColor(0.97, 0.4, 0.33)
    love.graphics.print("Kill " .. killedMonsters .. "/" .. totalMonsters, 160, 14)

    love.graphics.setColor(0.77, 0.67, 1)
    love.graphics.print("Map " .. map.mapIndex .. "/" .. progress.numMaps, 240, 14)

    love.graphics.setColor(0.95, 0.96, 0.88)
    love.graphics.print("WASD move  Arrows shoot", 12, virtualH - 26)

    love.graphics.setColor(1, 0.85, 0.18)
    love.graphics.print(collectedCoins .. "/" .. totalCoins .. " coins", virtualW - 72, virtualH - 26)
end

return HUD
