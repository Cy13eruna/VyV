# 🔧 PLANO DE REFATORAÇÃO - ARQUIVOS GRANDES EM SKETCH
# Objetivo: Dividir arquivos grandes em módulos menores e remover sufixos "_clean"

## 📊 PRIORIDADES DE REFATORAÇÃO

### 🔥 PRIORIDADE CRÍTICA (1000+ linhas)
1. **action_dialog_manager.gd** (1,322 linhas) → DIVIDIR EM 4 MÓDULOS

### 🔴 PRIORIDADE ALTA (500-999 linhas)
2. **rendering_manager.gd** (806 linhas) → DIVIDIR EM 3 MÓDULOS
3. **domain_manager.gd** (674 linhas) → DIVIDIR EM 2 MÓDULOS
4. **input_manager.gd** (632 linhas) → DIVIDIR EM 2 MÓDULOS
5. **toggle_fog_clean.gd** (600 linhas) → DIVIDIR EM 2 MÓDULOS

### 🟡 PRIORIDADE MÉDIA (300-499 linhas)
6. **initialize_game_clean.gd** (492 linhas) → DIVIDIR EM 2 MÓDULOS
7. **main_game.gd** (424 linhas) → DIVIDIR EM 2 MÓDULOS
8. **movement_service_clean.gd** (362 linhas) → DIVIDIR EM 2 MÓDULOS
9. **unit_renderer.gd** (361 linhas) → DIVIDIR EM 2 MÓDULOS
10. **move_unit_clean.gd** (360 linhas) → DIVIDIR EM 2 MÓDULOS
11. **unit_selection_manager.gd** (338 linhas) → DIVIDIR EM 2 MÓDULOS
12. **ui_manager.gd** (307 linhas) → DIVIDIR EM 2 MÓDULOS
13. **game_state_clean.gd** (306 linhas) → DIVIDIR EM 2 MÓDULOS

---

## 🎯 PLANOS DETALHADOS DE REFATORAÇÃO

### 1. 🔥 ACTION_DIALOG_MANAGER.GD (1,322 linhas)
**Localização:** `presentation/managers/dialog/`

#### Divisão proposta:
```
action_dialog_manager.gd (300 linhas) - Coordenador principal
├── action_dialog_core.gd (250 linhas) - Lógica central de diálogos
├── action_dialog_training.gd (400 linhas) - Sistema de treinamento
├── action_dialog_settlement.gd (200 linhas) - Sistema de assentamento
└── action_dialog_validation.gd (172 linhas) - Validações de ações
```

#### Responsabilidades:
- **action_dialog_manager.gd**: Coordenação e interface pública
- **action_dialog_core.gd**: Criação e estilo de diálogos
- **action_dialog_training.gd**: Lógica de treinamento (Fighter/Healer)
- **action_dialog_settlement.gd**: Lógica de assentamento (Settler)
- **action_dialog_validation.gd**: Validações de poder, posição, tecnologias

---

### 2. 🔴 RENDERING_MANAGER.GD (806 linhas)
**Localização:** `presentation/managers/`

#### Divisão proposta:
```
rendering_manager.gd (200 linhas) - Coordenador principal
├── unit_indicator_renderer.gd (300 linhas) - Indicadores de unidades
├── domain_renderer.gd (200 linhas) - Renderização de domínios
└── grid_overlay_renderer.gd (106 linhas) - Overlays e efeitos
```

#### Responsabilidades:
- **rendering_manager.gd**: Coordenação geral de renderização
- **unit_indicator_renderer.gd**: Emojis de fighter, healer, health
- **domain_renderer.gd**: Renderização de domínios e poder
- **grid_overlay_renderer.gd**: Overlays, seleções, fog of war

---

### 3. 🔴 DOMAIN_MANAGER.GD (674 linhas)
**Localização:** `presentation/managers/domain/`

#### Divisão proposta:
```
domain_manager.gd (300 linhas) - Interface principal
├── domain_upgrade_handler.gd (200 linhas) - Sistema de upgrades
└── domain_technology_handler.gd (174 linhas) - Integração com tecnologias
```

#### Responsabilidades:
- **domain_manager.gd**: Interface pública e coordenação
- **domain_upgrade_handler.gd**: VAGABOND, TECH, HARVEST
- **domain_technology_handler.gd**: Verificações e aplicação de tecnologias

---

### 4. 🔴 INPUT_MANAGER.GD (632 linhas)
**Localização:** `presentation/managers/`

#### Divisão proposta:
```
input_manager.gd (250 linhas) - Coordenador principal
├── click_handler.gd (200 linhas) - Processamento de cliques
└── input_validator.gd (182 linhas) - Validações de entrada
```

#### Responsabilidades:
- **input_manager.gd**: Interface principal e coordenação
- **click_handler.gd**: Lógica de cliques em unidades, domínios, grid
- **input_validator.gd**: Validações de entrada e permissões

---

### 5. 🔴 TOGGLE_FOG_CLEAN.GD (600 linhas)
**Localização:** `application/use_cases/`
**Novo nome:** `fog_of_war_service.gd`

#### Divisão proposta:
```
fog_of_war_service.gd (200 linhas) - Interface principal
├── visibility_calculator.gd (250 linhas) - Cálculos de visibilidade
└── fog_renderer.gd (150 linhas) - Renderização do fog
```

#### Responsabilidades:
- **fog_of_war_service.gd**: Interface pública do sistema
- **visibility_calculator.gd**: Algoritmos de visibilidade
- **fog_renderer.gd**: Renderização visual do fog

---

### 6. 🟡 INITIALIZE_GAME_CLEAN.GD (492 linhas)
**Localização:** `application/use_cases/`
**Novo nome:** `game_initializer.gd`

#### Divisão proposta:
```
game_initializer.gd (200 linhas) - Coordenador principal
├── grid_generator.gd (150 linhas) - Geração do grid hexagonal
└── player_setup.gd (142 linhas) - Configuração inicial dos jogadores
```

#### Responsabilidades:
- **game_initializer.gd**: Coordenação da inicialização
- **grid_generator.gd**: Criação do grid e terrenos
- **player_setup.gd**: Criação de jogadores, domínios, unidades

---

### 7. 🟡 MAIN_GAME.GD (424 linhas)
**Localização:** `presentation/`

#### Divisão proposta:
```
main_game.gd (200 linhas) - Coordenador principal
├── game_scene_manager.gd (124 linhas) - Gerenciamento de cena
└── game_event_dispatcher.gd (100 linhas) - Distribuição de eventos
```

#### Responsabilidades:
- **main_game.gd**: Ponto de entrada e coordenação
- **game_scene_manager.gd**: Setup da cena e managers
- **game_event_dispatcher.gd**: Distribuição de eventos entre managers

---

### 8. 🟡 MOVEMENT_SERVICE_CLEAN.GD (362 linhas)
**Localização:** `application/services/`
**Novo nome:** `movement_service.gd`

#### Divisão proposta:
```
movement_service.gd (180 linhas) - Interface principal
├── pathfinding_calculator.gd (182 linhas) - Algoritmos de pathfinding
```

#### Responsabilidades:
- **movement_service.gd**: Interface pública de movimento
- **pathfinding_calculator.gd**: Cálculos de caminhos válidos

---

### 9. 🟡 UNIT_RENDERER.GD (361 linhas)
**Localização:** `presentation/managers/`

#### Divisão proposta:
```
unit_renderer.gd (180 linhas) - Interface principal
├── unit_visual_effects.gd (181 linhas) - Efeitos visuais e animações
```

#### Responsabilidades:
- **unit_renderer.gd**: Renderização básica de unidades
- **unit_visual_effects.gd**: Efeitos especiais, glows, animações

---

### 10. 🟡 MOVE_UNIT_CLEAN.GD (360 linhas)
**Localização:** `application/use_cases/`
**Novo nome:** `unit_movement_handler.gd`

#### Divisão proposta:
```
unit_movement_handler.gd (180 linhas) - Interface principal
├── movement_validator.gd (180 linhas) - Validações de movimento
```

#### Responsabilidades:
- **unit_movement_handler.gd**: Execução de movimentos
- **movement_validator.gd**: Validações de terreno, poder, ações

---

### 11. 🟡 UNIT_SELECTION_MANAGER.GD (338 linhas)
**Localização:** `presentation/managers/unit/`

#### Divisão proposta:
```
unit_selection_manager.gd (170 linhas) - Interface principal
├── selection_validator.gd (168 linhas) - Validações de seleção
```

#### Responsabilidades:
- **unit_selection_manager.gd**: Lógica de seleção
- **selection_validator.gd**: Validações de ownership, ações, visibilidade

---

### 12. 🟡 UI_MANAGER.GD (307 linhas)
**Localização:** `presentation/managers/`

#### Divisão proposta:
```
ui_manager.gd (150 linhas) - Interface principal
├── ui_button_handler.gd (157 linhas) - Gerenciamento de botões
```

#### Responsabilidades:
- **ui_manager.gd**: Coordenação da UI
- **ui_button_handler.gd**: Lógica dos botões (Skip Turn, New Game, etc.)

---

### 13. 🟡 GAME_STATE_CLEAN.GD (306 linhas)
**Localização:** `infrastructure/persistence/`
**Novo nome:** `game_state_manager.gd`

#### Divisão proposta:
```
game_state_manager.gd (150 linhas) - Interface principal
├── state_serializer.gd (156 linhas) - Serialização e persistência
```

#### Responsabilidades:
- **game_state_manager.gd**: Gerenciamento do estado
- **state_serializer.gd**: Save/Load e serialização

---

## 📋 CRONOGRAMA DE EXECUÇÃO

### Fase 1 - Crítica (Semana 1)
- [x] Refatorar action_dialog_manager.gd ✅ CONCLUÍDO
  - ✅ Criado action_dialog_validation.gd (172 linhas)
  - ✅ Criado action_dialog_training.gd (150 linhas)
  - ✅ Criado action_dialog_settlement.gd (80 linhas)
  - ✅ Criado action_dialog_core.gd (280 linhas)
  - ✅ Refatorado action_dialog_manager.gd (120 linhas)
  - ✅ Total: 1,322 → 802 linhas (4 módulos + coordenador)

### Fase 2 - Alta Prioridade (Semana 2-3)
- [x] Refatorar rendering_manager.gd ✅ CONCLUÍDO
  - ✅ Criado unit_indicator_renderer.gd (293 linhas)
  - ✅ Criado domain_renderer.gd (163 linhas)
  - ✅ Criado grid_overlay_renderer.gd (388 linhas)
  - ✅ Refatorado rendering_manager.gd (126 linhas)
  - ✅ Total: 806 → 970 linhas (3 módulos + coordenador)
- [x] Refatorar domain_manager.gd ✅ CONCLUÍDO
  - ✅ Criado domain_upgrade_handler.gd (525 linhas)
  - ✅ Criado domain_technology_handler.gd (300 linhas)
  - ✅ Refatorado domain_manager.gd (135 linhas)
  - ✅ Total: 674 → 960 linhas (2 módulos + coordenador)
- [x] Refatorar input_manager.gd ✅ CONCLUÍDO
  - ✅ Criado input_event_handler.gd (311 linhas)
  - ✅ Criado input_debug_handler.gd (351 linhas)
  - ✅ Refatorado input_manager.gd (139 linhas)
  - ✅ Total: 632 → 801 linhas (2 módulos + coordenador)
- [x] Refatorar toggle_fog_clean.gd → fog_of_war_service.gd ✅ CONCLUÍDO
  - ✅ Criado fog_visibility_calculator.gd (404 linhas)
  - ✅ Criado fog_state_manager.gd (269 linhas)
  - ✅ Refatorado fog_of_war_service.gd (69 linhas)
  - ✅ Total: 600 → 742 linhas (2 módulos + coordenador)
  - ✅ Renomeado e movido para services/

### Fase 3 - Média Prioridade (Semana 4-5)
- [x] Refatorar initialize_game_clean.gd → game_initializer.gd ✅ CONCLUÍDO
  - ✅ Criado grid_generator.gd (232 linhas)
  - ✅ Criado player_setup.gd (244 linhas)
  - ✅ Refatorado game_initializer.gd (106 linhas)
  - ✅ Total: 492 → 582 linhas (2 módulos + coordenador)
  - ✅ Renomeado e movido para services/
- [x] Refatorar main_game.gd ✅ CONCLUÍDO
  - ✅ Criado game_scene_manager.gd (244 linhas)
  - ✅ Criado game_event_dispatcher.gd (178 linhas)
  - ✅ Refatorado main_game.gd (156 linhas)
  - ✅ Total: 424 → 578 linhas (2 módulos + coordenador)
  - ✅ Criado diretório game_coordination/
- [x] Refatorar movement_service_clean.gd → movement_service.gd ✅ CONCLUÍDO
  - ✅ Criado pathfinding_calculator.gd (256 linhas)
  - ✅ Criado movement_validator.gd (202 linhas)
  - ✅ Refatorado movement_service.gd (87 linhas)
  - ✅ Total: 362 → 545 linhas (2 módulos + coordenador)
  - ✅ Renomeado e criado diretório movement/
- [x] Refatorar unit_renderer.gd ✅ CONCLUÍDO
  - ✅ Criado unit_basic_renderer.gd (260 linhas)
  - ✅ Criado unit_visual_effects.gd (143 linhas)
  - ✅ Refatorado unit_renderer.gd (148 linhas)
  - ✅ Total: 361 → 551 linhas (2 módulos + coordenador)
  - ✅ Criado diretório rendering/unit/
- [x] Refatorar move_unit_clean.gd → unit_movement_handler.gd ✅ CONCLUÍDO
  - ✅ Criado movement_orchestrator.gd (261 linhas)
  - ✅ Criado movement_power_manager.gd (192 linhas)
  - ✅ Refatorado unit_movement_handler.gd (72 linhas)
  - ✅ Total: 360 → 525 linhas (2 módulos + coordenador)
  - ✅ Renomeado e criado diretório unit_movement/

### Fase 4 - Finalização (Semana 6)
- [x] Refatorar unit_selection_manager.gd ✅ CONCLUÍDO
  - ✅ Criado unit_action_validator.gd (184 linhas)
  - ✅ Criado unit_selection_core.gd (210 linhas)
  - ✅ Refatorado unit_selection_manager.gd (175 linhas)
  - ✅ Total: 300 → 569 linhas (2 módulos + coordenador)
  - ✅ Criado diretório selection/
- [x] Refatorar ui_manager.gd ✅ CONCLUÍDO
  - ✅ Criado ui_menu_manager.gd (175 linhas)
  - ✅ Criado ui_game_interface.gd (230 linhas)
  - ✅ Refatorado ui_manager.gd (227 linhas)
  - ✅ Total: 299 → 632 linhas (2 módulos + coordenador)
  - ✅ Criado diretório ui/
- [x] Refatorar gameplay_manager.gd ✅ CONCLUÍDO
  - ✅ Criado gameplay_manager_core.gd (228 linhas)
  - ✅ Criado gameplay_input_handler.gd (166 linhas)
  - ✅ Refatorado gameplay_manager.gd (201 linhas)
  - ✅ Total: 299 → 595 linhas (2 módulos + coordenador)
  - ✅ Criado diretório gameplay/

---

## 🎯 BENEFÍCIOS ESPERADOS

### Manutenibilidade
- ✅ Arquivos menores (< 300 linhas cada)
- ✅ Responsabilidades bem definidas
- ✅ Fácil localização de bugs

### Legibilidade
- ✅ Código mais focado
- ✅ Nomes mais claros (sem "_clean")
- ✅ Estrutura modular

### Testabilidade
- ✅ Módulos independentes
- ✅ Fácil criação de testes unitários
- ✅ Isolamento de responsabilidades

### Performance
- ✅ Carregamento sob demanda
- ✅ Menor uso de memória
- ✅ Compilação mais rápida

---

## 📝 NOTAS DE IMPLEMENTAÇÃO

### Padrões a seguir:
1. **Single Responsibility Principle**: Cada arquivo uma responsabilidade
2. **Dependency Injection**: Injetar dependências via construtor
3. **Interface Segregation**: Interfaces pequenas e específicas
4. **Naming Convention**: Nomes descritivos sem sufixos técnicos

### Estrutura de diretórios:
```
SKETCH/
├── application/
│   ├── services/
│   └── use_cases/
├── core/
│   ├── entities/
│   └── value_objects/
├── infrastructure/
│   ├── input/
│   ├── persistence/
│   └── rendering/
└── presentation/
    ├── managers/
    │   ├── dialog/
    │   ├── domain/
    │   ├── rendering/
    │   └── unit/
    └── ui/
```

### Critérios de sucesso:
- [ ] Nenhum arquivo > 300 linhas
- [ ] Todos os testes passando
- [ ] Performance mantida ou melhorada
- [ ] Documentação atualizada

---

## 🔄 ESTRATÉGIA DE MIGRAÇÃO

### Abordagem incremental:
1. **Criar novos módulos** sem quebrar o existente
2. **Migrar funcionalidades** gradualmente
3. **Atualizar referências** nos arquivos dependentes
4. **Remover código antigo** após validação
5. **Renomear arquivos** removendo "_clean"

### Validação:
- [ ] Testes unitários para cada módulo
- [ ] Testes de integração
- [ ] Verificação de performance
- [ ] Code review completo

### Rollback plan:
- Manter backup dos arquivos originais
- Commits atômicos para cada refatoração
- Possibilidade de reverter individualmente