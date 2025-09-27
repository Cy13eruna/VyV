@echo off
echo ===============================================
echo           VAGABONDS ^& VALLEYS
echo ===============================================
echo.
echo === HEXAGONO EQUILATERO ===
echo 7 pontos e 12 arestas
echo Hover sobre pontos e arestas para destaque magenta
echo Clique em pontos magentas para mover a unit
echo Tipos de arestas: Verde (move+ve), Verde acizentado (move), Amarelo acizentado (bloqueado), Ciano acizentado (ve)
echo Pressione ESPACO para gerar terreno aleatorio
echo Hover em elementos nao renderizados os mostra em magenta
echo Duas unidades: Vermelha (esquerda) e Violeta (direita)
echo Sistema de turnos: apenas jogador atual pode se mover
echo Skip Turn troca jogador e restaura acoes
echo Unidades ficam ocultas uma da outra a menos que estejam em ponto visivel
echo.
echo Iniciando...
echo.
cd /d "%~dp0\SKETCH"
"C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe" --path . minimal_triangle.tscn
pause