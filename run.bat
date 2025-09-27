@echo off
echo ===============================================
echo           VAGABONDS ^& VALLEYS
echo ===============================================
cd /d "%~dp0\SKETCH"
"C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe" --path . minimal_triangle.tscn
pause