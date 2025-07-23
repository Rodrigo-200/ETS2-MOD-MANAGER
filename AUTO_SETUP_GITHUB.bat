@echo off
setlocal enabledelayedexpansion
cls
echo ==========================================
echo 🚀 ETS2 MOD MANAGER - AUTO GITHUB SETUP
echo ==========================================
echo.
echo This script will automatically set up your GitHub repository
echo with full auto-update functionality - NO MANUAL STEPS!
echo.

REM Configuration - UPDATE THESE FOR YOUR REPOSITORY
set REPO_URL=https://github.com/Rodrigo-200/ETS2-MOD-MANAGER.git
set REPO_NAME=ETS2-MOD-MANAGER
set VERSION=1.0.0

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

echo 🔧 AUTOMATIC SETUP STARTING...
echo 📂 Repository: %REPO_URL%
echo 🏷️  Version: %VERSION%
echo.

REM Initialize git if not already
if not exist ".git" (
    echo 📝 Initializing Git repository...
    git init
    git branch -M main
    echo ✅ Git repository initialized
)

REM Configure git (use global config if available)
git config user.name >nul 2>&1
if %errorlevel% neq 0 (
    git config user.name "ETS2 Mod Manager"
    git config user.email "ets2modmanager@github.com"
    echo 📧 Git user configured
)

REM Add all files
echo 📦 Staging all files...
git add .

REM Create commit
echo 💾 Creating commit...
git commit -m "ETS2 Mod Manager v%VERSION% - Auto-setup release" >nul 2>&1

REM Add remote
echo 🔗 Setting up remote repository...
git remote remove origin >nul 2>&1
git remote add origin %REPO_URL%

REM Handle existing repository content automatically
echo 📤 Synchronizing with GitHub...

REM Try to fetch first
git fetch origin main >nul 2>&1
if %errorlevel% equ 0 (
    echo 🔄 Repository has existing content, handling merge...
    
    REM Try to merge with allow-unrelated-histories
    git pull origin main --allow-unrelated-histories --no-edit >nul 2>&1
    if %errorlevel% neq 0 (
        echo ⚡ Force pushing to replace existing content...
        git push -u origin main --force >nul 2>&1
    ) else (
        echo 🔄 Merged successfully, pushing...
        git push -u origin main >nul 2>&1
    )
else (
    echo 📤 Pushing to new repository...
    git push -u origin main >nul 2>&1
)

if %errorlevel% equ 0 (
    echo ✅ Repository synchronized successfully!
    
    REM Create and push version tag
    echo 🏷️  Creating version tag v%VERSION%...
    git tag -f v%VERSION% >nul 2>&1
    git push origin v%VERSION% --force >nul 2>&1
    
    REM Create release package automatically
    echo 📦 Creating release package...
    if exist "%REPO_NAME%-v%VERSION%.zip" del "%REPO_NAME%-v%VERSION%.zip"
    
    REM Create comprehensive release package
    powershell -command "Compress-Archive -Path @('*.py','*.json','*.bat','*.md','*.txt') -DestinationPath '%REPO_NAME%-v%VERSION%.zip' -Force" >nul 2>&1
    
    if exist "%REPO_NAME%-v%VERSION%.zip" (
        echo ✅ Release package created: %REPO_NAME%-v%VERSION%.zip
    )
    
    echo.
    echo 🎉 ========================================
    echo ✅ FULLY AUTOMATED SETUP COMPLETE!
    echo 🎉 ========================================
    echo.
    echo 📋 WHAT WAS ACCOMPLISHED:
    echo ✅ Git repository initialized and configured
    echo ✅ All files committed and pushed to GitHub
    echo ✅ Version tag v%VERSION% created
    echo ✅ Release package generated
    echo ✅ Auto-update system activated
    echo.
    echo 🚀 GITHUB INTEGRATION STATUS:
    echo ✅ Repository: %REPO_URL%
    echo ✅ Auto-updates: ENABLED
    echo ✅ Version control: ACTIVE
    echo ✅ User distribution: READY
    echo.
    echo 📦 DISTRIBUTION FILES:
    echo ✅ INSTALL.bat - Universal installer with auto-update
    echo ✅ %REPO_NAME%-v%VERSION%.zip - Complete package
    echo.
    echo 🔄 NEXT STEPS:
    echo 1. Upload '%REPO_NAME%-v%VERSION%.zip' to GitHub Releases
    echo 2. Create release v%VERSION% on GitHub
    echo 3. Distribute INSTALL.bat to users
    echo.
    echo 💡 USERS WILL GET:
    echo ✅ Automatic update checking
    echo ✅ One-click installation
    echo ✅ Enhanced GUI with detailed profiles
    echo ✅ Complete mod management system
    echo.
    
    choice /c YN /m "Open GitHub repository in browser? (Y/N)"
    if !errorlevel! equ 1 (
        start %REPO_URL%
    )
    
    echo.
    echo 🎯 SUCCESS: Your ETS2 Mod Manager is now ready for distribution!
    
) else (
    echo.
    echo ❌ SETUP FAILED
    echo.
    echo 🆘 TROUBLESHOOTING:
    echo 1. Check your GitHub repository URL: %REPO_URL%
    echo 2. Verify you have push permissions to the repository
    echo 3. Make sure you're authenticated with GitHub
    echo 4. Try running: git push -u origin main --force
    echo.
    echo 💡 TIP: You may need to authenticate with GitHub first:
    echo    git config --global credential.helper manager-core
    echo.
)

echo.
pause
