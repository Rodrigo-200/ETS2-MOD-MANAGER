@echo off
setlocal enabledelayedexpansion
cls

REM ==========================================
REM ETS2 MOD MANAGER - UNIVERSAL INSTALLER
REM Auto-updating, dependency-managing installer
REM ==========================================

echo ==========================================
echo 🚛 ETS2 MOD MANAGER - UNIVERSAL INSTALLER
echo ==========================================
echo Version 1.0.0
echo.

REM GitHub Repository Configuration
set GITHUB_USER=rodri-ets2
set GITHUB_REPO=ets2-mod-manager
set GITHUB_API_URL=https://api.github.com/repos/%GITHUB_USER%/%GITHUB_REPO%
set GITHUB_RAW_URL=https://raw.githubusercontent.com/%GITHUB_USER%/%GITHUB_REPO%/main

REM Step 1: Check for updates
echo 🔄 Checking for updates...
echo.

REM Check if curl is available for update checking
curl --version >nul 2>&1
if %errorlevel% equ 0 (
    echo 🌐 Checking GitHub for latest version...
    
    REM Download version info
    curl -s "%GITHUB_RAW_URL%/version.json" -o temp_version.json 2>nul
    if exist temp_version.json (
        REM Parse version using Python if available
        python --version >nul 2>&1
        if !errorlevel! equ 0 (
            python -c "import json; v=json.load(open('temp_version.json')); print('LATEST:' + v.get('version', '1.0.0')); print('DOWNLOAD:' + v.get('download_url', ''))" > version_check.txt 2>nul
            if exist version_check.txt (
                for /f "tokens=2 delims=:" %%a in ('findstr "LATEST:" version_check.txt') do set LATEST_VERSION=%%a
                for /f "tokens=2 delims=:" %%a in ('findstr "DOWNLOAD:" version_check.txt') do set DOWNLOAD_URL=%%a
                
                if not "!LATEST_VERSION!" == "1.0.0" (
                    echo 📥 New version available: !LATEST_VERSION!
                    echo 🔗 Download URL: !DOWNLOAD_URL!
                    echo.
                    choice /c YN /m "Download and install latest version? (Y/N)"
                    if !errorlevel! equ 1 (
                        echo 📥 Downloading latest version...
                        if not "!DOWNLOAD_URL!" == "" (
                            curl -L "!DOWNLOAD_URL!" -o latest_installer.zip
                            if exist latest_installer.zip (
                                echo ✅ Downloaded! Please extract and run the new installer.
                                pause
                                exit /b 0
                            )
                        )
                    )
                ) else (
                    echo ✅ You have the latest version
                )
            )
            del version_check.txt >nul 2>&1
        )
        del temp_version.json >nul 2>&1
    ) else (
        echo ⚠️  Could not check for updates (no internet or GitHub unavailable)
    )
) else (
    echo ⚠️  Update checking disabled (curl not available)
)

echo.

REM Step 2: Python Detection and Installation
echo 🔍 Step 2: Checking Python installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ❌ PYTHON NOT FOUND
    echo.
    echo 📥 Python is required but not installed or not in PATH.
    echo.
    echo 🔗 DOWNLOAD PYTHON:
    echo    https://www.python.org/downloads/
    echo.
    echo ⚠️  INSTALLATION REQUIREMENTS:
    echo    ✅ Check "Add Python to PATH"
    echo    ✅ Check "Install pip"
    echo.
    choice /c YN /m "Open Python download page? (Y/N)"
    if !errorlevel! equ 1 (
        start https://www.python.org/downloads/
    )
    echo.
    echo 🔄 After installing Python, restart this installer.
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo ✅ Python !PYTHON_VERSION! detected

REM Step 3: Dependency Management
echo.
echo 🔍 Step 3: Checking dependencies...

REM Create dependency installer
echo import sys, subprocess, importlib > install_deps.py
echo. >> install_deps.py
echo def install_package(package): >> install_deps.py
echo     try: >> install_deps.py
echo         subprocess.check_call([sys.executable, '-m', 'pip', 'install', package, '--quiet']) >> install_deps.py
echo         return True >> install_deps.py
echo     except: >> install_deps.py
echo         return False >> install_deps.py
echo. >> install_deps.py
echo def check_module(module_name, package_name=None): >> install_deps.py
echo     if package_name is None: >> install_deps.py
echo         package_name = module_name >> install_deps.py
echo     try: >> install_deps.py
echo         importlib.import_module(module_name) >> install_deps.py
echo         print(f'✅ {module_name}') >> install_deps.py
echo         return True >> install_deps.py
echo     except ImportError: >> install_deps.py
echo         print(f'❌ {module_name} - Installing...') >> install_deps.py
echo         if install_package(package_name): >> install_deps.py
echo             print(f'✅ {module_name} - Installed') >> install_deps.py
echo             return True >> install_deps.py
echo         else: >> install_deps.py
echo             print(f'❌ {module_name} - Failed') >> install_deps.py
echo             return False >> install_deps.py
echo. >> install_deps.py
echo modules = ['json', 'os', 'sys', 'shutil', 'getpass', 're', 'pathlib', 'dataclasses', 'typing', 'datetime'] >> install_deps.py
echo all_ok = True >> install_deps.py
echo for module in modules: >> install_deps.py
echo     if not check_module(module): >> install_deps.py
echo         all_ok = False >> install_deps.py
echo. >> install_deps.py
echo # Try to install requests for future updates >> install_deps.py
echo try: >> install_deps.py
echo     check_module('requests') >> install_deps.py
echo except: >> install_deps.py
echo     pass >> install_deps.py
echo. >> install_deps.py
echo if all_ok: >> install_deps.py
echo     print('SUCCESS') >> install_deps.py
echo     sys.exit(0) >> install_deps.py
echo else: >> install_deps.py
echo     print('FAILED') >> install_deps.py
echo     sys.exit(1) >> install_deps.py

python install_deps.py
set DEP_RESULT=%errorlevel%
del install_deps.py >nul 2>&1

if !DEP_RESULT! neq 0 (
    echo.
    echo ❌ DEPENDENCY INSTALLATION FAILED
    echo.
    echo 🆘 Try running as Administrator or check your internet connection
    pause
    exit /b 1
)

REM Step 4: Package Verification
echo.
echo 🔍 Step 4: Verifying package...

set REQUIRED_FILES=ETS2_Mod_Manager.py load_order.json manifest_cache.json
set PACKAGE_OK=1

for %%f in (%REQUIRED_FILES%) do (
    if not exist "%%f" (
        echo ❌ Missing: %%f
        set PACKAGE_OK=0
    ) else (
        echo ✅ Found: %%f
    )
)

if !PACKAGE_OK! equ 0 (
    echo.
    echo ❌ PACKAGE INCOMPLETE - Please re-download
    pause
    exit /b 1
)

REM Step 5: Package Information
echo.
echo 📦 Package Information:
python -c "import json; m=json.load(open('manifest_cache.json')); print('Mods:', m.get('total_mods', 'Unknown')); print('Source:', m.get('source_profile', 'Unknown')); print('Version:', m.get('version', 'Unknown'))" 2>nul

REM Step 6: ETS2 Process Check
echo.
echo 🔍 Step 6: Checking ETS2 status...
powershell -Command "Get-Process eurotrucks2 -ErrorAction SilentlyContinue" >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  ETS2 IS RUNNING - Please close it first!
    choice /c YN /m "Continue anyway? (NOT RECOMMENDED) (Y/N)"
    if !errorlevel! equ 2 (
        echo Installation cancelled.
        pause
        exit /b 1
    )
) else (
    echo ✅ ETS2 is not running
)

REM Step 7: Final Confirmation
echo.
echo 🎮 READY FOR INSTALLATION
echo.
echo The installer will:
echo ✅ Scan for ETS2 profiles
echo ✅ Let you choose which profile to modify
echo ✅ Create backup (.backup)
echo ✅ Install mod collection
echo.
choice /c YN /m "Begin installation? (Y/N)"
if !errorlevel! equ 2 (
    echo Installation cancelled.
    pause
    exit /b 0
)

REM Step 8: Installation
echo.
echo ==========================================
echo 🚀 INSTALLING MODS...
echo ==========================================
echo.

python ETS2_Mod_Manager.py

set INSTALL_RESULT=%errorlevel%

REM Step 9: Results
echo.
echo ==========================================
if !INSTALL_RESULT! equ 0 (
    echo 🎉 INSTALLATION SUCCESSFUL!
    echo.
    echo ✅ Mods installed
    echo ✅ Profile backed up
    echo ✅ Ready to play!
    echo.
    echo 🎮 Launch ETS2 and enjoy your mods!
) else (
    echo ❌ INSTALLATION FAILED
    echo.
    echo 🆘 Troubleshooting:
    echo - Close ETS2 completely
    echo - Run as Administrator
    echo - Check antivirus settings
    echo - Verify write permissions
)
echo.
echo ==========================================
pause
