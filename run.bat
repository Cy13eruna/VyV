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
echo - ✅ Unique initial naming system (domains and units)
echo - ✅ Historical names (Avalon, Babylon, Camelot, etc.)
echo - ✅ Names below units and domains (bold AND ITALIC)
echo - ✅ Adjusted positions (units more up, domains more down)
echo - ✅ Properly centered text (calculated positioning)
echo - ✅ Removed yellow selection circle and white borders
echo - ✅ Blue team changed to purple (#8000FF)
echo - ✅ Diamond-shaped paths (acute tips, obtuse sides)
echo - ✅ Perfect mesh diamonds (width = half length)
echo - ✅ Female walking emoji (🚶🏻‍♀️)
echo - ✅ Thick dashed domain outlines (30° rotated)
echo - ✅ Domain radius adjusted (center-to-side = path length)
echo - ✅ White 6-pointed stars for grid points (30° rotated)
echo - ✅ Slightly thicker diamonds (60%% width)
echo - ✅ Enhanced emoji tinting (dual approach)
echo - ✅ Domain name SPACE star power (same line)
echo - ✅ Smart deselection system
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