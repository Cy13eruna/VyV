@echo off
echo ===============================================
echo           VAGABONDS & VALLEYS
echo ===============================================
echo ULTRA SIMPLE VERSION - Only current player generates power...
cd /d "%~dp0\SKETCH"

REM Delete Godot cache to force reload
if exist ".godot" (
    echo Clearing Godot cache...
    rmdir /s /q ".godot"
)

echo Starting FIXED version...
"C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe" --path . minimal_triangle_fixed.tscn
pause