# ⚔️ ROTEIRO DE GUERRA AOS MONÓLITOS

## 🎯 **MISSÃO**
Desmembrar `main_game.gd` mantendo-o **100% INTACTO** através de **DUPLICAÇÃO MODULAR** em subpastas.

## 🚨 **REGRA DE OURO**
**NUNCA TOCAR NO `main_game.gd`** - Apenas **DUPLICAR** funcionalidades em módulos organizados.

## 📁 **ESTRUTURA DE BATALHA**

```
SKETCH/
├── main_game.gd                    # 🔒 INTACTO - O monólito protegido
├── main_game.tscn                  # 🔒 INTACTO - Scene original
├── project.godot                   # 🔒 INTACTO - Configuração
├── modules/                        # 🏗️ ARSENAL MODULAR
│   ├── grid/                       # ✅ COMPLETO
│   │   ├── hex_grid.gd            # Sistema de grid hexagonal
│   │   ├── hex_math.gd            # Matemática hexagonal
│   │   └── coordinates.gd         # Sistema de coordenadas
│   ├── terrain/                    # 🎯 PRÓXIMO ALVO
│   │   ├── terrain_generator.gd   # Geração de terreno
│   │   ├── terrain_types.gd       # Tipos de terreno
│   │   └── path_colors.gd         # Cores dos caminhos
│   ├── units/                      # 🎯 FUTURO
│   │   ├── unit_manager.gd        # Gerenciamento de unidades
│   │   ├── movement.gd            # Sistema de movimento
│   │   └── actions.gd             # Sistema de ações
│   ├── rendering/                  # 🎯 FUTURO
│   │   ├── hex_renderer.gd        # Renderização hexagonal
│   │   ├── ui_renderer.gd         # Renderização de UI
│   │   └── effects.gd             # Efeitos visuais
│   ├── input/                      # 🎯 FUTURO
│   │   ├── input_handler.gd       # Tratamento de input
│   │   ├── mouse_handler.gd       # Mouse e hover
│   │   └── keyboard_handler.gd    # Teclado
│   ├── game_logic/                 # 🎯 FUTURO
│   │   ├── turn_manager.gd        # Sistema de turnos
│   │   ├── game_state.gd          # Estado do jogo
│   │   └── rules.gd               # Regras do jogo
│   └── ui/                         # 🎯 FUTURO
│       ├── ui_manager.gd          # Gerenciamento de UI
│       ├── labels.gd              # Sistema de labels
│       └── buttons.gd             # Sistema de botões
└── utils/                          # ✅ COMPLETO
    ├── constants.gd               # Constantes do jogo
    ├── enums.gd                   # Enumerações
    └── helpers.gd                 # Funções auxiliares
```

## 📋 **PLANO DE BATALHA (7 ETAPAS)**

### **✅ ETAPA 1: Estrutura de Subpastas** 
- ✅ **COMPLETA** - Todas as pastas criadas
- ✅ Organização perfeita estabelecida

### **✅ ETAPA 2: Utilitários Base**
- ✅ **COMPLETA** - `utils/constants.gd`
- ✅ **COMPLETA** - `utils/enums.gd` 
- ✅ **COMPLETA** - `utils/helpers.gd`

### **✅ ETAPA 3: Módulo Grid**
- ✅ **COMPLETA** - `modules/grid/hex_grid.gd`
- ✅ **COMPLETA** - `modules/grid/hex_math.gd`
- ✅ **COMPLETA** - `modules/grid/coordinates.gd`

### **🎯 ETAPA 4: Módulo Terrain** (PRÓXIMA BATALHA)
- 🔄 Criar `modules/terrain/terrain_generator.gd`
- 🔄 Criar `modules/terrain/terrain_types.gd`
- 🔄 Criar `modules/terrain/path_colors.gd`
- 🔄 **DUPLICAR** funções de terreno do `main_game.gd`

### **🎯 ETAPA 5: Módulo Units**
- 🔄 Criar `modules/units/unit_manager.gd`
- 🔄 Criar `modules/units/movement.gd`
- 🔄 Criar `modules/units/actions.gd`
- 🔄 **DUPLICAR** funções de unidades e movimento

### **🎯 ETAPA 6: Módulo Rendering**
- 🔄 Criar `modules/rendering/hex_renderer.gd`
- 🔄 Criar `modules/rendering/ui_renderer.gd`
- 🔄 Criar `modules/rendering/effects.gd`
- 🔄 **DUPLICAR** funções de renderização

### **🎯 ETAPA 7: Módulos Finais**
- 🔄 Criar módulos Input, Game Logic e UI
- 🔄 **DUPLICAR** funcionalidades restantes
- 🔄 Integração final e testes

## 🛡️ **PRINCÍPIOS DE SEGURANÇA**

### **1. PROTEÇÃO ABSOLUTA DO MONÓLITO**
- ❌ **PROIBIDO** modificar `main_game.gd`
- ❌ **PROIBIDO** mover código existente
- ❌ **PROIBIDO** deletar arquivos originais
- ✅ **PERMITIDO** apenas criar novos arquivos

### **2. DUPLICAÇÃO INTELIGENTE**
- ✅ Copiar **LÓGICA**, não código literal
- ✅ Melhorar **ORGANIZAÇÃO** na duplicação
- ✅ Manter **COMPATIBILIDADE** funcional
- ✅ Criar **INTERFACES** limpas

### **3. TESTES INCREMENTAIS**
- ✅ Testar cada módulo **ISOLADAMENTE**
- ✅ Verificar que jogo original **CONTINUA FUNCIONANDO**
- ✅ **ZERO RISCO** de quebrar o jogo
- ✅ Rollback desnecessário

## 🎯 **FUNÇÕES ALVO POR MÓDULO**

### **🔷 TERRAIN (Próximo Alvo)**
```gdscript
# Funções a duplicar do main_game.gd:
- _generate_terrain()
- _get_path_color()
- EdgeType enum (já duplicado em utils/enums.gd)
```

### **🔷 UNITS (Futuro)**
```gdscript
# Funções a duplicar do main_game.gd:
- _can_unit_move_to_point()
- _attempt_movement()
- _is_connected_to_unit()
- Unit positioning logic
```

### **🔷 RENDERING (Futuro)**
```gdscript
# Funções a duplicar do main_game.gd:
- _draw()
- _update_name_positions()
- Visual rendering logic
```

### **🔷 INPUT (Futuro)**
```gdscript
# Funções a duplicar do main_game.gd:
- _unhandled_input()
- Mouse hover detection
- Keyboard handling
```

### **🔷 GAME_LOGIC (Futuro)**
```gdscript
# Funções a duplicar do main_game.gd:
- _on_skip_turn_pressed()
- Turn management
- Game state logic
```

### **🔷 UI (Futuro)**
```gdscript
# Funções a duplicar do main_game.gd:
- UI creation and management
- Label updates
- Button handling
```

## ✅ **CRITÉRIOS DE VITÓRIA**

### **Para cada Etapa:**
- ✅ Jogo original funciona **IDENTICAMENTE**
- ✅ Novos módulos compilam **SEM ERRO**
- ✅ Funcionalidade duplicada **TESTADA**
- ✅ **ZERO MODIFICAÇÕES** em arquivos existentes

### **Para a Guerra Final:**
- ✅ `main_game.gd` **100% INTACTO**
- ✅ Estrutura modular **COMPLETA**
- ✅ Funcionalidades **DUPLICADAS** e organizadas
- ✅ Base para **FUTURO DESENVOLVIMENTO**

## 📊 **PROGRESSO ATUAL**
- **Etapas Completas**: 3/7 ✅
- **Próxima Batalha**: ETAPA 4 - Módulo Terrain 🎯
- **Status do Monólito**: 100% PROTEGIDO 🔒
- **Arquivos Criados**: 6 módulos funcionais ⚔️

---

**🚀 PRÓXIMA AÇÃO**: Atacar ETAPA 4 - Duplicar funções de terreno do `main_game.gd`