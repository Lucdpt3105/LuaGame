-- src/utils/localization.lua
-- Hệ thống đa ngôn ngữ cho game

local localization = {
    current_language = "vi", -- Ngôn ngữ hiện tại
    
    -- Bảng dữ liệu translations
    strings = {
        vi = { -- Tiếng Việt
            -- Play State
            score = "Điểm",
            coins = "Vàng",
            enemies_killed = "Quái đã tiêu",
            
            -- Win State
            win_title = "CHIẾN THẮNG!",
            win_message = "Mày đã gom xong vàng và đã diệt quái",
            time = "Thời gian",
            seconds = "giây",
            replay_prompt = "NHẤN R ĐỂ CHƠI LẠI",
            
            -- Game Over State
            gameover_title = "Bị Tóm Rồi Con!",
            best_time = "Thời gian tốt nhất",
            best_score = "Điểm cao nhất",
            retry_prompt = "Nhấn R để thử lại",
        },
        
        en = { -- English (dành cho mở rộng sau)
            score = "Score",
            coins = "Coins",
            enemies_killed = "Enemies Killed",
            
            win_title = "YOU WIN!",
            win_message = "You collected all gold and defeated enemies",
            time = "Time",
            seconds = "seconds",
            replay_prompt = "PRESS R TO REPLAY",
            
            gameover_title = "Game Over!",
            best_time = "Best Time",
            best_score = "Best Score",
            retry_prompt = "Press R to retry",
        }
    }
}

-- Hàm lấy text theo key
function localization.getText(key)
    local lang = localization.strings[localization.current_language]
    if lang and lang[key] then
        return lang[key]
    end
    -- Nếu không tìm thấy, trả về key như một fallback
    return key
end

-- Hàm đặt ngôn ngữ
function localization.setLanguage(lang)
    if localization.strings[lang] then
        localization.current_language = lang
    end
end

-- Hàm lấy ngôn ngữ hiện tại
function localization.getLanguage()
    return localization.current_language
end

return localization
