@echo off
echo ===============================================
echo           VAGABONDS ^& VALLEYS
echo ===============================================
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