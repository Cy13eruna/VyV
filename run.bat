@echo off
echo ===============================================
echo           VAGABONDS ^& VALLEYS
echo        🏆 COMPLETE ONION ARCHITECTURE 🏆
echo          ✅ ALL 5 PHASES RESTORED ✅
echo ===============================================
cd /d "%~dp0\SKETCH"

REM Delete Godot cache to force reload
if exist ".godot" (
    echo Clearing Godot cache...
    rmdir /s /q ".godot"
)

REM Also clear any import cache
if exist ".import" (
    echo Clearing import cache...
    rmdir /s /q ".import"
)

REM Wait a moment for file system
timeout /t 1 /nobreak >nul

echo.
echo Starting V^&V Final Game...
echo - Complete hexagonal strategy game
echo - Full ONION architecture implementation
echo - Professional UI and visual effects
echo - All 5 restoration phases complete
echo.
echo 🎮 CONTROLS:
echo - Click units to select ^& move
echo - SPACE: Toggle fog of war
echo - ENTER: Skip turn
echo - F1: Debug info ^| F2: Grid stats
echo - ESC: Quit game
echo.

"C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe" --path .

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Failed to start game!
    echo Check if Godot is installed at the correct path.
    echo Current path: "C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe"
    echo.
    echo Alternative: Open SKETCH folder in Godot Editor and press F5
    echo.
)

pause