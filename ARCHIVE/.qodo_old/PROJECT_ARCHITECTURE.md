# 🎮 PROJETO V&V - ARQUITETURA COMPLETA E FUNCIONALIDADES

## 📋 VISÃO GERAL DO PROJETO

**V&V** é um jogo de estratégia hexagonal com sistema de domínios, unidades e zoom sofisticado. O projeto evoluiu através de 90+ sessões para uma arquitetura enterprise-grade modular.

---

## 🏗️ ARQUITETURA PRINCIPAL

### 📁 Estrutura de Diretórios
```
SKETCH/
├── scenes/
│   └── main_game.tscn          # Cena principal
├── scripts/
│   ├── main_game.gd            # Orquestrador principal
│   ├── star_click_demo.gd      # Sistema de zoom de duas etapas
│   ├── core/                   # Sistemas fundamentais
│   ├── entities/               # Entidades do jogo
│   ├── game/                   # Lógica de jogo
│   ├── rendering/              # Renderização
│   └── interfaces/             # Sistema de interfaces
```

---

## 🎯 ENTIDADES PRINCIPAIS

### 🌟 **HexGrid** (`scripts/rendering/hex_grid.gd`)
**Responsabilidade**: Renderização e geometria do grid hexagonal

**Funcionalidades**:
- Geração de hexágonos em padrão hexagonal
- Criação de 553+ pontos (estrelas) conectados
- Sistema de cache para performance
- Coordenadas locais/globais
- Detecção de cliques

**Métodos Importantes**:
- `get_dot_positions()` → Array de posições das estrelas
- `is_grid_ready()` → Verifica se grid está pronto
- `to_local()/to_global()` → Conversão de coordenadas

### 🗺️ **StarMapper** (`scripts/entities/star_mapper.gd`)
**Responsabilidade**: Mapeamento e indexação das estrelas

**Funcionalidades**:
- Mapeia posições do HexGrid para IDs de estrelas
- Fornece acesso rápido a posições por ID
- Validação de IDs de estrelas

**Métodos Importantes**:
- `map_stars(dot_positions)` → Mapeia estrelas
- `get_star_position(star_id)` → Posição da estrela
- `get_star_count()` → Total de estrelas

### 🏰 **Domain** (`scripts/entities/domain.gd`)
**Responsabilidade**: Entidade de domínio hexagonal

**Implementa Interfaces**: `IGameEntity`, `IResourceProducer`, `IOwnable`

**Funcionalidades**:
- Criação de hexágonos tracejados
- Detecção de lados compartilhados
- Produção de recursos (power)
- Sistema de propriedade
- Visualização com cores

**Métodos Importantes**:
- `create_at_star(star_id, parent)` → Cria domínio
- `would_share_sides_with_domains()` → Verifica conflitos
- `set_legacy_owner(owner_id)` → Define proprietário
- `produce_resources()` → Produz recursos

### ⚔️ **Unit** (`scripts/entities/unit.gd`)
**Responsabilidade**: Unidade móvel do jogo

**Implementa Interfaces**: `IGameEntity`, `IMovable`, `ICombatable`, `IOwnable`

**Funcionalidades**:
- Movimento entre estrelas
- Sistema de combate
- Visualização com cores
- Ações por turno

**Métodos Importantes**:
- `move_to_star(star_id)` → Move unidade
- `position_at_star(star_id)` → Posiciona inicialmente
- `take_damage(amount)` → Recebe dano
- `attack(target)` → Ataca alvo

---

## 🎮 SISTEMAS DE JOGO

### 🎯 **GameManager** (`scripts/game/game_manager.gd`)
**Responsabilidade**: Gerenciamento central de entidades

**Funcionalidades**:
- Criação e destruição de unidades/domínios
- Validação de movimentos
- Detecção de terreno
- Spawn de domínios com unidades

**Métodos Importantes**:
- `create_unit(star_id)` → Cria unidade
- `create_domain(center_star_id)` → Cria domínio
- `spawn_domain_with_unit_colored()` → Spawn completo
- `get_valid_adjacent_stars(unit)` → Estrelas válidas

### 🎮 **GameController** (`scripts/game/managers/game_controller.gd`)
**Responsabilidade**: Orquestração de todos os sistemas

**Funcionalidades**:
- Coordenação de managers
- Processamento de input
- Sistema de turnos
- Zoom inicial automático

**Managers Integrados**:
- `TurnManager` → Controle de turnos
- `InputHandler` → Processamento de input
- `UIManager` → Interface do usuário

### 🔄 **TurnManager** (`scripts/game/managers/turn_manager.gd`)
**Responsabilidade**: Sistema de turnos

**Funcionalidades**:
- Controle de teams
- Ações por turno
- Mudança de turnos
- Validação de ações

### 🖱️ **InputHandler** (`scripts/game/managers/input_handler.gd`)
**Responsabilidade**: Processamento de eventos

**Funcionalidades**:
- Detecção de cliques em unidades/estrelas
- Eventos de zoom (wheel)
- Conversão de coordenadas
- Cooldown de input

---

## 🔍 SISTEMA DE ZOOM DE DUAS ETAPAS

### 📍 **StarClickDemo** (`scripts/star_click_demo.gd`)
**Responsabilidade**: Sistema de zoom sofisticado

**Como Funciona**:
1. **Primeira Scroll na Estrela** → Centraliza câmera e cursor na estrela
2. **Segunda Scroll na Mesma Estrela** → Aplica zoom mantendo centralização
3. **Scroll em Estrela Diferente** → Centraliza na nova estrela
4. **Clique Esquerdo** → Reset do modo zoom

**Constantes**:
- `ZOOM_FACTOR: 1.3` → Fator de zoom por step
- `MIN_ZOOM: 0.3` → Zoom mínimo
- `MAX_ZOOM: 5.0` → Zoom máximo

**Estados**:
- `zoom_mode_active` → Se modo zoom está ativo
- `current_centered_star_id` → Estrela atualmente centralizada

**Métodos Principais**:
- `_handle_zoom(zoom_in)` → Lógica principal
- `_center_star()` → Etapa 1: Centralizar
- `_apply_zoom()` → Etapa 2: Zoom
- `_reset_zoom_mode()` → Reset

---

## 🏛️ SISTEMA DE INTERFACES

### 📋 **Interfaces Implementadas** (`scripts/core/interfaces.gd`)

#### `IGameEntity`
- `initialize(id, type, position)` → Inicializar entidade
- `update(delta)` → Atualizar por frame
- `validate()` → Validar estado
- `serialize()/deserialize()` → Persistência

#### `IMovable`
- `move_to(position)` → Mover para posição
- `stop_movement()` → Parar movimento
- `can_move_to(position)` → Verificar se pode mover
- `update_movement(delta)` → Atualizar movimento

#### `ICombatable`
- `take_damage(amount)` → Receber dano
- `attack(target)` → Atacar alvo
- `heal(amount)` → Curar
- `is_alive()` → Verificar se vivo
- `get_health()` → Obter vida atual

#### `IResourceProducer`
- `produce_resources()` → Produzir recursos
- `collect_resources()` → Coletar recursos
- `can_produce()` → Verificar se pode produzir

#### `IOwnable`
- `set_owner(player_id, color)` → Definir proprietário
- `belongs_to(player_id)` → Verificar propriedade
- `has_owner()` → Verificar se tem dono

---

## 🛠️ SISTEMAS DE SUPORTE

### 📊 **ObjectPool** (`scripts/core/object_pool.gd`)
**Responsabilidade**: Reutilização de objetos para performance

**Pools Configurados**:
- `HighlightNode` → Highlights de movimento
- `UnitLabel` → Labels de unidades
- `DomainNode` → Nós visuais de domínios
- `Button/Panel/CanvasLayer` → UI

### 📝 **Logger** (`scripts/core/logger.gd`)
**Responsabilidade**: Sistema de logging

**Níveis**: DEBUG, INFO, WARNING, ERROR

### ⚠️ **Result<T>** (`scripts/core/result.gd`)
**Responsabilidade**: Tratamento de erros

**Tipos**: Success, Error com mensagens detalhadas

### 🧹 **ResourceCleanup** (`scripts/core/resource_cleanup.gd`)
**Responsabilidade**: Limpeza de memória

---

## 🎯 FLUXO DE INICIALIZAÇÃO

### 📋 **Sequência de Startup**
1. **MainGame._ready()** → Inicialização principal
2. **_initialize_core_systems()** → Criar managers
3. **_step_0_console_input()** → Detectar argumentos
4. **_execute_map_creation_steps()** → Criar mapa
5. **_step_1_render_board()** → Renderizar grid
6. **_step_2_map_stars()** → Mapear estrelas
7. **_step_3_position_domains()** → Criar domínios
8. **_setup_complete_system()** → Inicializar GameController
9. **setup_initial_zoom()** → Configurar zoom baseado em domínios

### 🎮 **Sistema de Domínios Dinâmico**
**Argumentos de Console**: `--domain-count=N` (2-6)

**Mapeamento**:
- 2 domínios → Grid 5x5 → Zoom 2.0x
- 3 domínios → Grid 7x7 → Zoom 1.6x
- 4 domínios → Grid 9x9 → Zoom 1.3x
- 5 domínios → Grid 11x11 → Zoom 1.1x
- 6 domínios → Grid 13x13 → Zoom 0.9x

---

## 🎨 SISTEMA VISUAL

### 🎨 **Cores de Teams**
```gdscript
var team_colors = [
    Color(0, 0, 1),      # Azul
    Color(1, 0.5, 0),    # Laranja
    Color(1, 0, 0),      # Vermelho
    Color(0.5, 0, 1),    # Roxo
    Color(1, 1, 0),      # Amarelo
    Color(0, 1, 1)       # Ciano
]
```

### 🎯 **Sistema de Highlights**
- Estrelas válidas para movimento são destacadas
- Cores correspondem à unidade selecionada
- Uso de ObjectPool para performance

---

## 🔧 CONFIGURAÇÕES IMPORTANTES

### ⚙️ **Constantes do Sistema**
```gdscript
# Movimento
max_adjacent_distance: 38.0    # Distância máxima entre estrelas
click_tolerance: 30.0          # Tolerância para cliques

# Zoom
ZOOM_FACTOR: 1.3              # Fator de zoom
MIN_ZOOM: 0.3                 # Zoom mínimo
MAX_ZOOM: 5.0                 # Zoom máximo

# Domínios
position_tolerance: 10.0       # Tolerância para detecção de lados
```

### 🎮 **Estados do Jogo**
- `map_initialized` → Se mapa foi inicializado
- `movement_mode_active` → Se modo movimento está ativo
- `zoom_mode_active` → Se modo zoom está ativo
- `selected_unit` → Unidade atualmente selecionada

---

## 🚀 COMO EXECUTAR

### 💻 **Comandos**
```bash
# Jogo padrão (6 domínios)
godot --path SKETCH scenes/main_game.tscn

# Jogo com 2 domínios (zoom maior)
godot --path SKETCH scenes/main_game.tscn --domain-count=2

# Jogo com 4 domínios (zoom médio)
godot --path SKETCH scenes/main_game.tscn --domain-count=4
```

### 🎮 **Controles**
- **Mouse Wheel na Estrela** → Zoom de duas etapas
- **Clique na Unidade** → Selecionar/ativar movimento
- **Clique na Estrela** → Mover unidade (se selecionada)
- **Clique Esquerdo Vazio** → Desselecionar/reset zoom

---

## 📚 PROTOCOLOS IMPORTANTES

### ⚠️ **Regras Críticas**
1. **i.txt é UNIDIRECIONAL** → Apenas user escreve, Qodo lê
2. **SKETCH/ é o diretório principal** → Não usar raiz do projeto
3. **Preservar funcionalidades** → Nunca quebrar sistemas existentes
4. **ObjectPool sempre** → Usar para performance
5. **Interfaces obrigatórias** → Todas entidades implementam

### 🔄 **Padrões de Desenvolvimento**
- Logging detalhado em todas operações
- Validação de referências antes de uso
- Cleanup de recursos ao sair
- Tratamento de erros com Result<T>
- Documentação inline em português

---

## 🎯 FUNCIONALIDADES PRINCIPAIS

### ✅ **Sistemas Funcionais**
- ✅ Grid hexagonal dinâmico (2-6 domínios)
- ✅ Sistema de zoom de duas etapas
- ✅ Movimento de unidades com highlights
- ✅ Criação de domínios sem sobreposição
- ✅ Sistema de turnos por teams
- ✅ Detecção de terreno para movimento
- ✅ Produção de recursos
- ✅ Sistema de propriedade
- ✅ Arquitetura modular enterprise-grade
- ✅ Interfaces completas implementadas
- ✅ ObjectPool para performance
- ✅ Sistema de cleanup automático

### 🎮 **Gameplay**
- Jogadores controlam unidades e domínios
- Movimento limitado por terreno e distância
- Domínios produzem recursos automaticamente
- Sistema de turnos alternados
- Zoom inteligente para diferentes tamanhos de mapa

---

## 📖 HISTÓRICO DE DESENVOLVIMENTO

**90+ Sessões de Evolução**:
- Sessões 1-30: Grid hexagonal básico
- Sessões 31-60: Sistema de entidades
- Sessões 61-80: Refatoração para arquitetura modular
- Sessões 81-90: Sistema de interfaces enterprise-grade
- Sessão 91+: Correções de compilação e zoom

**Marcos Importantes**:
- Implementação do grid hexagonal
- Sistema de movimento de unidades
- Criação de domínios
- Sistema de zoom de duas etapas
- Refatoração para GameController
- Sistema de interfaces completo
- Restauração do zoom original

---

## 🎯 ESTE DOCUMENTO

**Objetivo**: Garantir que a arquitetura e funcionalidades do projeto V&V nunca sejam esquecidas novamente.

**Última Atualização**: Sessão atual - Sistema de zoom restaurado

**Status**: ✅ Projeto 100% funcional com todas as features implementadas

---

*"Um jogo de estratégia hexagonal que evoluiu para uma arquitetura enterprise-grade através de 90+ sessões de desenvolvimento colaborativo."* 🎮✨