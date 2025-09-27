@echo off
echo ===============================================
echo           VAGABONDS ^& VALLEYS
echo ===============================================
echo.
echo === MALHA HEXAGONAL EXPANDIDA (GIRADA 60°) ===
echo 37 pontos, diametro 7, terreno aleatorio, rotacao padrao, cores saturadas
echo Hover sobre pontos e arestas para destaque magenta
echo Clique em pontos magentas para mover a unit
echo Tipos de terreno: Field (move+ve), Forest (move), Mountain (bloqueado), Water (ve)
echo Proporcoes: Field 50%, Forest/Water/Mountain 16.7% cada
echo Pressione ESPACO para alternar fog of war (debug)
echo Hover em elementos nao renderizados os mostra em magenta
echo Duas unidades: Vermelha e Violeta (emojis coloridos, spawn oficial em pontos de 6 arestas)
echo Dominios hexagonais: contorno grosso, raio=distancia real entre pontos, revelam terreno
echo Propriedades de dominio: 7 pontos + 12 arestas sempre visiveis para o dono, separados por time
echo Sistema de turnos: apenas jogador atual pode se mover
echo Skip Turn troca jogador e restaura acoes
echo Unidades ficam ocultas uma da outra a menos que estejam em ponto visivel
echo Terreno aleatorio gerado automaticamente a cada inicio
echo.
echo Iniciando...
echo.
cd /d "%~dp0\SKETCH"
"C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe" --path . minimal_triangle.tscn
pause