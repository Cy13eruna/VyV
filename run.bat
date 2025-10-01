@echo off
echo ===============================================
echo           VAGABONDS ^& VALLEYS
echo        🏆 COMPLETE TECHNICAL IMPLEMENTATION 🏆
echo          ✅ ALL ADVANCED SYSTEMS READY ✅
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
echo Starting V^&V Advanced Technical Demo...
echo - Complete hexagonal strategy game
echo - Full ONION architecture implementation
echo - Professional UI and visual effects
echo - Advanced technical systems integrated
echo.
echo 🎮 V^&V RESTORED GAMEPLAY - WORKING VERSION
echo ORIGINAL GAMEPLAY RESTORED WITH ALL REQUESTED CHANGES
echo.
echo 📊 Restored Features:
echo - ✅ Removed castle emojis
echo - ✅ Unit emojis painted with player colors
echo - ✅ Removed unit circles
echo - ✅ Adjusted path thickness (reduced 3x)
echo - ✅ New terrain colors (Field/Forest/Mountain/Water)
echo - ✅ Manual skip turn only (ENTER)
echo - ✅ Hexagonal domains (outline only)
echo - ✅ 30-degree board rotation
echo - ✅ Fixed click areas (rotation corrected)
echo - ✅ 2x larger unit size
echo - ✅ Units tinted with team colors (moved up)
echo - ✅ Domains hidden when out of visibility
echo - ✅ Random hexagon corner spawn (different each game)
echo - ✅ Completely manual turns (no auto skip)
echo - ✅ Mathematically accurate domain size (1 hex radius)
echo - ✅ Balanced power economy (start with 1 power)
echo - ✅ Domain occupation system (enemy units stop power)
echo - ✅ Strategic gameplay (control centers to deny power)
echo - ✅ Free movement when origin domain is occupied
echo - ✅ Resistance mechanic (escape without power cost)
echo - ✅ Precise visibility rules (individual team fog)
echo - ✅ Units: ONLY 6 adjacent hexes + 6 connecting paths
echo - ✅ Domains: ONLY 7 internal hexes + 12 internal paths
echo - ✅ No vision outside domain boundaries
echo - ✅ Mountains and forests block unit vision
echo - ✅ Tactical terrain usage for stealth
echo - ✅ Removed visibility bubbles (cleaner fog)
echo - ✅ Removed dark fog overlay (cleaner visuals)
echo - ✅ Forest blocks movement if enemy on other side
echo - ✅ Both units revealed when forest blocking occurs
echo - ✅ Action and power consumed even when blocked
echo - ✅ Movement allowed through forest (with blocking)
echo - ✅ Debug logs added for forest blocking system
echo - ✅ Movement validation logs added
echo - ✅ Forest exception detection logs added
echo - ✅ Point-only click system (no unit clicking)
echo - ✅ Intuitive interface (click hex to select/move)
echo - ✅ Debug logs added for movement system diagnosis
echo - ✅ Fixed movement logic (unit detection corrected)
echo - ✅ Fixed enemy unit interaction (allows forest blocking)
echo - ✅ Revealed units bypass forest blocking
echo - ✅ Exhausted units appear grayed out
echo - ✅ Magenta movement targets (no emojis)
echo - ✅ Cannot select units without actions
echo - ✅ Fixed script errors (property access corrected)
echo - ✅ Fixed unit overlap bug (proper occupation rules)
echo - ✅ Auto-clear selection when unit exhausted
echo - ✅ Movement breaks forest revelation (robust rule)
echo.
echo 🎮 CONTROLS:
echo - Click hex with unit to select, click hex to move
echo - SPACE: Toggle fog of war
echo - ENTER: Skip turn (MANUAL ONLY)
echo - F1: Debug info ^| F2: Grid stats
echo - ESC: Quit game
echo.
echo 📊 ARCHITECTURE LAYERS:
echo - Core: Entities ^& Value Objects
echo - Application: Services ^& Use Cases
echo - Infrastructure: Technical Systems
echo - Presentation: Game Coordinator
echo.

"C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe" --path .

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Failed to start V^&V Restored Gameplay!
    echo Check if Godot is installed at the correct path.
    echo Current path: "C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe"
    echo.
    echo Alternative: Open SKETCH folder in Godot Editor and press F5
    echo.
    echo 📊 TECHNICAL IMPLEMENTATION STATUS:
    echo ✅ Core Layer: 4 clean entities
    echo ✅ Application Layer: 3 services + 4 use cases
    echo ✅ Infrastructure Layer: 7 technical systems
    echo ✅ Presentation Layer: Complete game coordinator
    echo ✅ Total: 32+ files in ONION architecture
)

pause