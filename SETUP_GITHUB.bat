@echo off
cls
echo ==========================================
echo 🚀 ETS2 MOD MANAGER - GITHUB SETUP
echo ==========================================
echo.
echo This script will help you set up the GitHub repository
echo for auto-updating mod distribution.
echo.

REM Check if git is available
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Git is not installed or not in PATH
    echo.
    echo 📥 Please install Git from:
    echo    https://git-scm.com/downloads
    echo.
    pause
    exit /b 1
)

echo ✅ Git detected
echo.

echo 📋 SETUP INSTRUCTIONS:
echo.
echo 1. Go to https://github.com and create a new repository
echo 2. Repository name: ets2-mod-manager
echo 3. Description: Universal ETS2 mod installer with auto-update
echo 4. Make it public (so the installer can download updates)
echo 5. Don't initialize with README (we have our own)
echo.

set /p REPO_URL="Enter your GitHub repository URL (e.g., https://github.com/yourusername/ets2-mod-manager.git): "

if "%REPO_URL%"=="" (
    echo ❌ No repository URL provided
    pause
    exit /b 1
)

echo.
echo 🔧 Setting up Git repository...

REM Initialize git if not already
if not exist ".git" (
    git init
    echo ✅ Git repository initialized
)

REM Add all files
git add .
echo ✅ Files staged

REM Create initial commit
git commit -m "Initial release: ETS2 Mod Manager v1.0.0"
echo ✅ Initial commit created

REM Add remote
git remote remove origin >nul 2>&1
git remote add origin %REPO_URL%
echo ✅ Remote repository added

REM Handle existing repository content
echo.
echo 📤 Pushing to GitHub...
git branch -M main

REM Try to pull first in case repository has content
echo 🔄 Checking for existing content...
git fetch origin main >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  Repository has existing content, merging...
    git pull origin main --allow-unrelated-histories --no-edit >nul 2>&1
    if %errorlevel% neq 0 (
        echo 🔧 Force pushing (replacing existing content)...
        git push -u origin main --force
    ) else (
        echo 🔄 Merged successfully, pushing...
        git push -u origin main
    )
) else (
    echo 📤 Pushing to new repository...
    git push -u origin main
)

if %errorlevel% equ 0 (
    echo.
    echo 🎉 SUCCESS! Repository setup complete!
    echo.
    echo 🔗 Your repository: %REPO_URL%
    echo.
    echo � CREATING AUTOMATIC RELEASE...
    
    REM Create and push version tag
    git tag -a v1.0.0 -m "ETS2 Mod Manager v1.0.0 - Initial Release"
    git push origin v1.0.0
    
    REM Create release zip automatically
    echo 📦 Creating release package...
    if exist "ETS2-Mod-Manager-v1.0.0.zip" del "ETS2-Mod-Manager-v1.0.0.zip"
    
    REM Use PowerShell to create zip (Windows built-in)
    powershell -command "Compress-Archive -Path '*.py','*.json','*.bat','*.md' -DestinationPath 'ETS2-Mod-Manager-v1.0.0.zip' -Force"
    
    echo.
    echo ✅ FULLY AUTOMATED SETUP COMPLETE!
    echo.
    echo 📋 WHAT HAPPENED:
    echo ✅ Repository synchronized with GitHub
    echo ✅ Version tag v1.0.0 created
    echo ✅ Release package created: ETS2-Mod-Manager-v1.0.0.zip
    echo.
    echo 🔄 AUTO-UPDATE SYSTEM STATUS:
    echo ✅ Your installer will now auto-update from GitHub!
    echo ✅ Users will receive automatic updates
    echo ✅ No manual intervention required
    echo.
    echo 📂 Next: Upload 'ETS2-Mod-Manager-v1.0.0.zip' to GitHub Releases
    echo    (Or use GitHub CLI if available)
    echo.
    start %REPO_URL%
) else (
    echo.
    echo ❌ Failed to push to GitHub
    echo.
    echo 🆘 Common issues:
    echo - Check your repository URL
    echo - Make sure you have push permissions  
    echo - Check your GitHub authentication
    echo.
)

echo.
pause
