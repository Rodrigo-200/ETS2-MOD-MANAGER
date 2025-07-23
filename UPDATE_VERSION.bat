@echo off
cls
echo ==========================================
echo 📝 ETS2 MOD MANAGER - VERSION UPDATER
echo ==========================================
echo.

REM Get current version
python -c "import json; v=json.load(open('version.json')); print('Current version:', v.get('version', '1.0.0'))" 2>nul

echo.
set /p NEW_VERSION="Enter new version (e.g., 1.1.0): "

if "%NEW_VERSION%"=="" (
    echo ❌ No version provided
    pause
    exit /b 1
)

echo.
set /p CHANGELOG="Enter changelog entry: "

echo.
echo 📝 Updating version.json...

REM Update version.json
python -c "
import json
from datetime import datetime

try:
    with open('version.json', 'r') as f:
        data = json.load(f)
except:
    data = {}

data['version'] = '%NEW_VERSION%'
data['release_date'] = datetime.now().strftime('%%Y-%%m-%%d')
data['last_updated'] = datetime.now().isoformat()

if 'changelog' not in data:
    data['changelog'] = []

if '%CHANGELOG%':
    data['changelog'].insert(0, '%CHANGELOG%')

# Keep only last 10 changelog entries
data['changelog'] = data['changelog'][:10]

with open('version.json', 'w') as f:
    json.dump(data, f, indent=2)

print('✅ Version updated to %NEW_VERSION%')
"

if %errorlevel% equ 0 (
    echo.
    echo 🔄 Committing changes to Git...
    
    git add .
    git commit -m "Update to version %NEW_VERSION%: %CHANGELOG%"
    git tag v%NEW_VERSION%
    git push origin main --tags
    
    if !errorlevel! equ 0 (
        echo.
        echo 🎉 SUCCESS! Version %NEW_VERSION% published!
        echo.
        echo 📋 NEXT STEPS:
        echo 1. Go to your GitHub repository
        echo 2. Draft a new release for tag v%NEW_VERSION%
        echo 3. Upload updated ZIP file
        echo 4. Publish the release
        echo.
        echo ✅ Users will now get the update automatically!
    ) else (
        echo ❌ Failed to push to GitHub
    )
) else (
    echo ❌ Failed to update version file
)

echo.
pause
