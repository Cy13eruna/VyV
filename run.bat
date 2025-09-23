@echo off
echo ===============================================
echo           VAGABONDS ^& VALLEYS
echo ===============================================
echo.
echo === SISTEMA DE MAPA BASEADO EM DOMINIOS ===
echo Quantos dominios voce deseja?
echo.
echo [2] - 2 dominios (mapa pequeno)
echo [3] - 3 dominios (mapa medio) [PADRAO]
echo [4] - 4 dominios (mapa grande)
echo [5] - 5 dominios (mapa muito grande)
echo [6] - 6 dominios (mapa maximo)
echo.
set /p choice="Digite sua escolha (2-6) ou pressione Enter para padrao: "

if "%choice%"=="" set choice=3
if "%choice%"=="2" goto start
if "%choice%"=="3" goto start
if "%choice%"=="4" goto start
if "%choice%"=="5" goto start
if "%choice%"=="6" goto start
echo Escolha invalida, usando padrao (3)
set choice=3

:start
echo.
echo Iniciando jogo com %choice% jogadores...
echo.
cd /d "%~dp0\SKETCH"
"C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe" --path . scenes\main_game.tscn --domain-count=%choice%
pause