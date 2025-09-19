@echo off
echo ===============================================
echo           VAGABONDS ^& VALLEYS
echo ===============================================
echo.
echo === CONFIGURACAO DE SPAWN ===
echo Quantos dominios voce deseja spawnar?
echo.
echo [1] - 1 dominio
echo [2] - 2 dominios  
echo [3] - 3 dominios
echo [4] - 4 dominios
echo [5] - 5 dominios
echo [6] - 6 dominios (padrao)
echo.
set /p choice="Digite sua escolha (1-6) ou pressione Enter para padrao: "

if "%choice%"=="" set choice=6
if "%choice%"=="1" goto start
if "%choice%"=="2" goto start
if "%choice%"=="3" goto start
if "%choice%"=="4" goto start
if "%choice%"=="5" goto start
if "%choice%"=="6" goto start
echo Escolha invalida, usando padrao (6)
set choice=6

:start
echo.
echo *** ZOOM DEFINITIVO - DUAS ETAPAS: CENTRALIZAR + ZOOM ***
echo Iniciando jogo com %choice% dominios...
echo.
cd /d "%~dp0\SKETCH"
"C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe" --path . scenes\star_click_demo.tscn --domain-count=%choice%
pause