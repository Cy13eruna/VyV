@echo off
echo ===============================================
echo           VAGABONDS ^& VALLEYS
echo ===============================================
echo.
echo === SISTEMA DE MAPA BASEADO EM DOMINIOS ===
echo Quantos dominios voce deseja?
echo.
echo [2] - 2 dominios (mapa 7x7)
echo [3] - 3 dominios (mapa 9x9)
echo [4] - 4 dominios (mapa 13x13)
echo [5] - 5 dominios (mapa 15x15)
echo [6] - 6 dominios (mapa 19x19) [PADRAO]
echo.
set /p choice="Digite sua escolha (2-6) ou pressione Enter para padrao: "

if "%choice%"=="" set choice=6
if "%choice%"=="2" goto start
if "%choice%"=="3" goto start
if "%choice%"=="4" goto start
if "%choice%"=="5" goto start
if "%choice%"=="6" goto start
echo Escolha invalida, usando padrao (6)
set choice=6

:start
echo.
echo Executando 5 passos do sistema...
echo 0. Input via console: %choice% dominios
echo 1. Renderizar tabuleiro
echo 2. Mapear estrelas
echo 3. Posicionar dominios
echo 4. Ajustar zoom
echo.
cd /d "%~dp0\SKETCH"
"C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe" --path . scenes\star_click_demo.tscn --domain-count=%choice%
pause