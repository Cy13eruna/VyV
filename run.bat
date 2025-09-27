@echo off
echo ===============================================
echo           VAGABONDS ^& VALLEYS
echo ===============================================
echo.
echo === HEXAGONO EQUILATERO ===
echo 7 pontos e 12 arestas
echo Hover sobre pontos e arestas para destaque magenta
echo Clique em pontos magentas para mover a unidade
echo.
echo Iniciando...
echo.
cd /d "%~dp0\SKETCH"
"C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe" --path . minimal_triangle.tscn
pause