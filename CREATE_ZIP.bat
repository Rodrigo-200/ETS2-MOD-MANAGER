@echo off
cls
echo ==========================================
echo 📦 ETS2 MOD MANAGER - CREATE DISTRIBUTION
echo ==========================================
echo.

echo 🔧 Creating distribution ZIP...

REM Get version from version.json
for /f "tokens=*" %%i in ('python -c "import json; print(json.load(open('version.json')).get('version', '1.0.0'))"') do set VERSION=%%i

set ZIP_NAME=ETS2-Mod-Manager-v%VERSION%.zip

echo 📝 Version: %VERSION%
echo 📦 Creating: %ZIP_NAME%
echo.

REM Create ZIP using PowerShell
powershell -Command "Compress-Archive -Path '*.bat', '*.py', '*.json', '*.md', '*.txt', '.github', '.gitignore' -DestinationPath '%ZIP_NAME%' -Force"

if %errorlevel% equ 0 (
    echo ✅ SUCCESS! Distribution created: %ZIP_NAME%
    echo.
    echo 📋 TO SHARE WITH FRIENDS:
    echo 1. Send them %ZIP_NAME%
    echo 2. They extract and run INSTALL.bat
    echo 3. Universal installer handles everything!
    echo.
    echo 📤 TO PUBLISH UPDATE:
    echo 1. Upload %ZIP_NAME% to GitHub releases
    echo 2. Tag as v%VERSION%
    echo 3. Users get auto-update notifications
    echo.
    choice /c YN /m "Open folder to see the ZIP file? (Y/N)"
    if !errorlevel! equ 1 (
        explorer .
    )
) else (
    echo ❌ Failed to create ZIP file
    echo.
    echo Try creating it manually or check permissions
)

echo.
pause
