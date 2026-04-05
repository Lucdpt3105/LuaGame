@echo off
REM Script download Noto Sans font cho game Lua

echo Dang tai Noto Sans font (Vi.ttf support)...

REM Tai font tu Google Fonts CDN
powershell -Command "& {
    $url = 'https://github.com/googlei18n/noto-fonts/raw/main/hinted/NotoSans-Regular.ttf'
    $output = '%~dp0NotoSans-Regular.ttf'
    
    try {
        Write-Host 'Dang tai ...'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        (New-Object System.Net.WebClient).DownloadFile($url, $output)
        Write-Host 'Tai thanh cong! ^_^' -ForegroundColor Green
    } catch {
        Write-Host 'Tai that bai. Vui long tai thu cong tu: https://fonts.google.com/noto/specimen/Noto+Sans' -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
}"

pause
