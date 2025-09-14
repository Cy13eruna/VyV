@echo off
echo Executando Vagabonds ^& Valleys...
cd /d "%~dp0\SKETCH\ZERO"
"C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe" --path . scenes\hex_grid_scene.tscn
pause