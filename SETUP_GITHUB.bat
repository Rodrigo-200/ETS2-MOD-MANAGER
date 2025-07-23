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

REM Push to GitHub
echo.
echo 📤 Pushing to GitHub...
git branch -M main
git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo 🎉 SUCCESS! Repository setup complete!
    echo.
    echo 🔗 Your repository: %REPO_URL%
    echo.
    echo 📋 NEXT STEPS:
    echo 1. Go to your GitHub repository
    echo 2. Create a new release (Releases → Create a new release)
    echo 3. Tag version: v1.0.0
    echo 4. Upload the zip file of this folder
    echo 5. Publish the release
    echo.
    echo ✅ Your installer will now auto-update from GitHub!
    echo.
    choice /c YN /m "Open repository in browser? (Y/N)"
    if !errorlevel! equ 1 (
        start %REPO_URL%
    )
) else (
    echo.
    echo ❌ Failed to push to GitHub
    echo.
    echo 🆘 Common issues:
    echo - Check your repository URL
    echo - Make sure you have push permissions
    echo - Repository might need to be created first
    echo.
)

echo.
pause
