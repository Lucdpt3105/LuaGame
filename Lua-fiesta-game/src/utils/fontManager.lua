-- src/utils/fontManager.lua
-- Quản lý font hỗ trợ UTF-8 cho tiếng Việt

local fontManager = {
    fonts = {},
    fontPath = "assets/fonts/",
    fallbackFontSize = 16
}

-- Danh sách font ưu tiên (theo thứ tự)
local preferredFonts = {
    "NotoSans-VariableFont_wdth,wght.ttf",
    "NotoSans-Italic-VariableFont_wdth,wght.ttf",
    "NotoSans-Regular.ttf",
    "DejaVuSans.ttf",
    "Roboto-Regular.ttf",
}

-- Hàm tìm font file có sẵn trong folder
function fontManager.findAvailableFont()
    for _, fontName in ipairs(preferredFonts) do
        local filepath = fontManager.fontPath .. fontName
        if love.filesystem.getInfo(filepath) then
            print("✓ Tìm thấy font: " .. fontName)
            return fontName
        end
    end
    print("⚠️ Không tìm thấy font nào trong assets/fonts/")
    return nil
end

-- Hàm tạo font từ file TTF
function fontManager.createFontFromFile(name, filename, size)
    size = size or 16
    
    local filepath = fontManager.fontPath .. filename
    local success, font = pcall(function()
        return love.graphics.newFont(filepath, size)
    end)
    
    if success and font then
        fontManager.fonts[name] = font
        print("✓ Load font thành công: " .. filename .. " (size: " .. size .. ")")
        return font
    end
    
    print("⚠️ Không load được font: " .. filepath)
    return nil
end

-- Hàm tạo font mặc định (hỗ trợ UTF-8 tốt nhất)
function fontManager.createFont(name, size)
    size = size or 16  -- Size lớn hơn giúp UTF-8 hiển thị tốt hơn
    
    local success, font = pcall(function()
        return love.graphics.newFont(size)
    end)
    
    if success and font then
        fontManager.fonts[name] = font
        return font
    end
    
    return nil
end

-- Lấy font
function fontManager.getFont(name)
    name = name or "default"
    return fontManager.fonts[name] or love.graphics.getFont()
end

-- Set font hiện tại
function fontManager.setFont(name)
    local font = fontManager.getFont(name)
    if font then
        love.graphics.setFont(font)
        return true
    end
    return false
end

-- Khởi tạo các font cần dùng
-- Ưu tiên load font TTF nếu có, nếu không thì dùng font mặc định
function fontManager.init()
    print("════ Khởi tạo hệ thống Font ════")
    
    -- Tìm font tốt nhất
    local foundFont = fontManager.findAvailableFont()
    
    if foundFont then
        -- Load từ file TTF
        fontManager.createFontFromFile("default", foundFont, 14)
        fontManager.createFontFromFile("large", foundFont, 18)
        fontManager.createFontFromFile("small", foundFont, 12)
        
        if fontManager.fonts["default"] then
            print("✓ Font đã load thành công! ✓")
            love.graphics.setFont(fontManager.fonts["default"])
            return
        end
    end
    
    -- Fallback: dùng font hệ thống
    print("⚠️ Dùng font hệ thống mặc định...")
    fontManager.createFont("default", 14)
    fontManager.createFont("large", 18)
    fontManager.createFont("small", 12)
    love.graphics.setFont(fontManager.fonts["default"])
end

return fontManager
