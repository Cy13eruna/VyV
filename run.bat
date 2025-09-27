@echo off
echo ===============================================
echo           VAGABONDS ^& VALLEYS
echo ===============================================
cd /d "%~dp0\SKETCH"

REM Delete Godot cache to force reload
if exist ".godot" (
    echo Clearing Godot cache...
    rmdir /s /q ".godot"
)

"C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe" --path . minimal_triangle_fixed.tscn
pause