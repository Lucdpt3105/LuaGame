-- HƯỚNG DẪN FIX LỖI FONT TIẾNG VIỆT

-- ❌ VẤN ĐỀ: Text tiếng Việt bị lỗi / hiển thị sai ký tự

-- ✅ GIẢI PHÁP:

-- 1️⃣ CÁCH NHANH (Khuyên dùng):
--    - Chạy file: assets/fonts/download-font.bat
--    - Hoặc tải font từ: https://fonts.google.com/noto/specimen/Noto+Sans
--    - Copy file NotoSans-Regular.ttf vào folder: assets/fonts/
--    - Chạy game lại

-- 2️⃣ CÁCH THỦ CÔNG:
--    - Nếu không thể download, dùng một font có sẵn trên hệ thống
--    - Sửa file: src/utils/fontManager.lua
--    - Thay đổi dòng:
--      fontManager.createFontFromFile("default", "NotoSans-Regular.ttf", 14)
--    - Thành:
--      fontManager.createFontFromFile("default", "YourFont.ttf", 14)

-- 3️⃣ NẾU VẪN KHÔNG ĐƯỢC:
--    - Kiểm tra tên file phải đúng (case-sensitive trên Mac/Linux)
--    - Đảm bảo file .ttf nằm trong folder: assets/fonts/
--    - Font phải hỗ trợ UTF-8 và có ký tự Việt

-- 4️⃣ CÓ THỂ DÙNG NHỮNG FONT NÀY:
--    ✓ NotoSans-Regular.ttf (KHUYÊN DÙNG)
--    ✓ DejaVuSans.ttf
--    ✓ Roboto-Regular.ttf
--    ✓ Arial.ttf (nếu có sẵn trên Windows)

-- 📚 TẢI FONT TỪ ĐÂU:
--    - Google Fonts: https://fonts.google.com
--    - DejaVu: https://dejavu-fonts.github.io/
--    - DaFont: https://www.dafont.com/

-- 🎉 XONG! Text Việt của bạn sẽ hiển thị đúng.
