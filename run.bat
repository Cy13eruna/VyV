@echo off
echo ===============================================
echo           VAGABONDS ^& VALLEYS
echo        MODULAR ONION ARCHITECTURE
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
echo Starting V^&V Game...
echo - Hexagonal strategy game
echo - ONION architecture
echo - Multiplayer-ready design
echo.
echo CONTROLS:
echo - Click units to select
echo - Click valid points to move
echo - SPACE: Toggle fog of war
echo - ENTER: Skip turn
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