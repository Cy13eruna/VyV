# V&V Game - Sistema de Instâncias por Jogador v2.0

## 🎯 Nova Arquitetura

O jogo foi refatorado para usar uma **arquitetura baseada em instâncias separadas** para cada jogador, preparando o sistema para multiplayer online e evitando conflitos entre jogadores.

## 🏗️ Estrutura do Sistema

```
GameServer (Coordenador Central)
├── PlayerInstance_1 (Jogador Azul)
│   ├── units: Array[Unit]
│   ├── domains: Array[Domain]
│   └── fog_of_war: FogOfWar
├── PlayerInstance_2 (Jogador Laranja)
├── PlayerInstance_3 (Jogador Vermelho)
└── SharedGameState (Estado Compartilhado)
    ├── hex_grid: HexGrid
    ├── star_mapper: StarMapper
    └── turn_manager: TurnManager
```

## 📁 Arquivos Principais

### Novos Arquivos (v2.0)
- `scripts/systems/player_instance.gd` - Instância individual de cada jogador
- `scripts/systems/game_server.gd` - Coordenador central do jogo
- `scripts/systems/shared_game_state.gd` - Estado compartilhado entre jogadores
- `scripts/star_click_demo_v2.gd` - Interface principal com nova arquitetura
- `scenes/star_click_demo_v2.tscn` - Cena atualizada
- `scripts/hex_grid_clean.gd` - HexGrid com logs limpos

### Arquivos Mantidos
- `scripts/unit.gd` - Sistema de unidades
- `scripts/domain.gd` - Sistema de domínios
- `scripts/fog_of_war.gd` - Sistema de fog of war
- `scripts/star_mapper.gd` - Mapeamento de estrelas
- `scripts/hex_grid_*.gd` - Sistema de grid hexagonal

## 🎮 Como Usar

### Executar o Jogo v2.0
```bash
godot --path SKETCH scenes/star_click_demo_v2.tscn --domain-count=3
```

### Parâmetros de Linha de Comando
- `--domain-count=N` - Número de jogadores (2-6, padrão: 3)

## 🔧 Funcionalidades

### ✅ Implementado
- **Instâncias Isoladas**: Cada jogador tem sua própria instância
- **Estado Compartilhado**: Tabuleiro e regras centralizados
- **Sistema de Turnos**: Alternância automática entre jogadores
- **Fog of War Individual**: Visibilidade por jogador
- **Movimento Tático**: Seleção e movimento de unidades
- **Interface Limpa**: Logs organizados e reduzidos
- **Zoom Inteligente**: Sistema de zoom simplificado

### 🎯 Controles
- **Clique Esquerdo**: Selecionar unidade / Mover
- **Scroll**: Zoom in/out
- **Botão "PRÓXIMO TURNO"**: Avançar turno

## 🚀 Vantagens da Nova Arquitetura

### 1. **Isolamento de Estado**
- Cada jogador tem suas próprias unidades e domínios
- Evita conflitos entre jogadores
- Facilita debugging

### 2. **Preparação para Multiplayer**
- Estrutura pronta para sistema online
- Comunicação centralizada via GameServer
- Estado sincronizado apenas quando necessário

### 3. **Performance Otimizada**
- Logs limpos e organizados
- Processamento distribuído por instância
- Renderização otimizada

### 4. **Escalabilidade**
- Fácil adicionar/remover jogadores
- Sistema modular e extensível
- Componentes reutilizáveis

## 🔍 Logs Limpos

### Antes (v1.0)
```
🔧 Criando novo StarMapper...
🔍 Verificação: StarMapper tem 133 estrelas mapeadas
🌫️ FogOfWar: referências configuradas
🎮 GameManager: referências configuradas
🔍 Estado do StarMapper: 133 estrelas
🔧 Reconfigurando referências do GameManager...
[... 50+ linhas de debug ...]
```

### Depois (v2.0)
```
V&V: Inicializando sistema com arquitetura por instâncias...
V&V: Configurando jogo para 3 jogadores
V&V: Jogador Azul posicionado na estrela 15
V&V: Sistema inicializado com sucesso!
V&V: Turno do jogador Azul
```

## 🎯 Próximos Passos

1. **Multiplayer Online**: Implementar comunicação via rede
2. **IA para Jogadores**: Sistema de inteligência artificial
3. **Salvamento de Partidas**: Persistência de estado
4. **Interface Avançada**: HUD melhorado
5. **Efeitos Visuais**: Animações e feedback

## 🐛 Debugging

### Verificar Estado do Jogo
```gdscript
# No console do Godot
print(game_server.get_game_stats())
```

### Logs Importantes
- `V&V: Sistema inicializado` - Sistema pronto
- `V&V: Turno do jogador X` - Mudança de turno
- `V&V: Unidade movida` - Movimento realizado

## 📊 Comparação v1.0 vs v2.0

| Aspecto | v1.0 | v2.0 |
|---------|------|------|
| Arquitetura | Monolítica | Instâncias Isoladas |
| Logs | 200+ linhas | 10-20 linhas |
| Multiplayer | Não preparado | Pronto para rede |
| Performance | Moderada | Otimizada |
| Debugging | Difícil | Simplificado |
| Escalabilidade | Limitada | Alta |

---

**Desenvolvido por V&V Game Studio**  
*Sistema de jogo estratégico hexagonal com arquitetura moderna*