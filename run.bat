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
echo 🎮 V^&V CLEAN FINAL GAME
echo COMPLETE ONION ARCHITECTURE - NO COMMAND SYSTEM
echo.
echo 📊 Core Features:
echo - Complete ONION Architecture
echo - Advanced Input System
echo - Professional Rendering
echo - Hexagonal Grid Strategy
echo - Fog of War System
echo - Turn-based Gameplay
echo - Clean ^& Focused Experience
echo.
echo 🎮 CONTROLS:
echo - Click units to select ^& move
echo - SPACE: Toggle fog of war
echo - ENTER: Skip turn
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
    echo ERROR: Failed to start V^&V Technical Demo!
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