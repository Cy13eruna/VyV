@echo off
echo ===============================================
echo           VAGABONDS ^& VALLEYS
echo ===============================================
echo.
echo 🎮 LATEST IMPROVEMENTS:
echo - ✅ Console output cleaned (essential logs only)
echo - ✅ Remembered terrain with original colors
echo - ✅ Moderate remembered terrain (45%% blend, no transparency)
echo - ✅ Tinted emoji units (team colors, no background circles)
echo - ✅ Whitish exhausted units (clear visual feedback)
echo - ✅ Persistent map knowledge (paths stay visible)
echo - ✅ Forest blocking system (robust revelation pairs)
echo - ✅ Point-only click system (intuitive interface)
echo - ✅ Magenta movement targets (no emojis)
echo.
echo 🎮 CONTROLS:
echo - Click hex with unit to select, click hex to move
echo - SPACE: Toggle fog of war
echo - ENTER: Skip turn (MANUAL ONLY)
echo - F1: Debug info ^| F2: Grid stats
echo - ESC: Quit game
echo.
echo Starting game...
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

"C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe" --path .

pause