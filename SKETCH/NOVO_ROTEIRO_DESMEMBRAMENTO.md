# 🔄 NOVO ROTEIRO DE DESMEMBRAMENTO - MAIN_GAME.GD INTACTO

## 🚨 **PROBLEMA DO ROTEIRO ANTERIOR**
O roteiro anterior **FALHOU** porque tentava **MIGRAR** código do `main_game.gd`, causando bugs. 

## 🎯 **NOVO OBJETIVO**
Criar estrutura modular em **SUBPASTAS** mantendo `main_game.gd` **COMPLETAMENTE INTACTO**.

## 🏗️ **ESTRATÉGIA: DUPLICAÇÃO MODULAR**

### **PRINCÍPIO FUNDAMENTAL:**
- **NUNCA TOCAR** no `main_game.gd`
- **DUPLICAR** funcionalidades em módulos organizados
- **CRIAR** estrutura paralela para futuro desenvolvimento
- **MANTER** o jogo funcionando 100%

## 📁 **ESTRUTURA DE SUBPASTAS PROPOSTA**

```
SKETCH/
├── main_game.gd                    # ✅ INTACTO - NUNCA MODIFICAR
├── main_game.tscn                  # ✅ INTACTO - NUNCA MODIFICAR
├── project.godot                   # ✅ INTACTO - NUNCA MODIFICAR
├── modules/                        # 🆕 MÓDULOS ORGANIZADOS
│   ├── grid/                       # Grid e coordenadas
│   │   ├── hex_grid.gd            # Funções de grid hexagonal
│   │   ├── hex_math.gd            # Matemática hexagonal
│   │   └── coordinates.gd         # Sistema de coordenadas
│   ├── terrain/                    # Sistema de terreno
│   │   ├── terrain_generator.gd   # Geração de terreno
│   │   ├── terrain_types.gd       # Tipos de terreno
│   │   └── path_colors.gd         # Cores dos caminhos
│   ├── units/                      # Sistema de unidades
│   │   ├── unit_manager.gd        # Gerenciamento de unidades
│   │   ├── movement.gd            # Sistema de movimento
│   │   └── actions.gd             # Sistema de ações
│   ├── rendering/                  # Sistema de renderização
│   │   ├── hex_renderer.gd        # Renderização hexagonal
│   │   ├── ui_renderer.gd         # Renderização de UI
│   │   └── effects.gd             # Efeitos visuais
│   ├── input/                      # Sistema de entrada
│   │   ├── input_handler.gd       # Tratamento de input
│   │   ├── mouse_handler.gd       # Mouse e hover
│   │   └── keyboard_handler.gd    # Teclado
│   ├── game_logic/                 # Lógica do jogo
│   │   ├── turn_manager.gd        # Sistema de turnos
│   │   ├── game_state.gd          # Estado do jogo
│   │   └── rules.gd               # Regras do jogo
│   └── ui/                         # Interface do usuário
│       ├── ui_manager.gd          # Gerenciamento de UI
│       ├── labels.gd              # Sistema de labels
│       └── buttons.gd             # Sistema de botões
└── utils/                          # 🆕 UTILITÁRIOS COMPARTILHADOS
    ├── constants.gd               # Constantes do jogo
    ├── enums.gd                   # Enumerações
    └── helpers.gd                 # Funções auxiliares
```

## 📝 **PLANO DE EXECUÇÃO (7 ETAPAS SEGURAS)**

### **ETAPA 1: Criar Estrutura de Pastas**
- ✅ Criar todas as subpastas
- ✅ **NÃO TOCAR** em arquivos existentes
- ✅ Preparar estrutura organizacional

### **ETAPA 2: Extrair Constantes e Enums**
- ✅ Criar `utils/constants.gd` com constantes
- ✅ Criar `utils/enums.gd` com enumerações
- ✅ **DUPLICAR** (não mover) do `main_game.gd`
- ✅ Testar compilação

### **ETAPA 3: Criar Módulo Grid**
- ✅ Criar `modules/grid/hex_grid.gd`
- ✅ **DUPLICAR** funções de grid do `main_game.gd`
- ✅ Criar versões modulares independentes
- ✅ Testar funcionalidade isolada

### **ETAPA 4: Criar Módulo Terrain**
- ✅ Criar `modules/terrain/terrain_generator.gd`
- ✅ **DUPLICAR** funções de terreno
- ✅ Integrar com módulo Grid
- ✅ Testar geração de terreno

### **ETAPA 5: Criar Módulo Units**
- ✅ Criar `modules/units/unit_manager.gd`
- ✅ **DUPLICAR** funções de unidades e movimento
- ✅ Criar sistema modular de unidades
- ✅ Testar movimento

### **ETAPA 6: Criar Módulo Rendering**
- ✅ Criar `modules/rendering/hex_renderer.gd`
- ✅ **DUPLICAR** funções de renderização
- ✅ Criar sistema de desenho modular
- ✅ Testar renderização

### **ETAPA 7: Criar Módulos Restantes**
- ✅ Criar módulos Input, Game Logic e UI
- ✅ **DUPLICAR** funcionalidades restantes
- ✅ Integrar todos os módulos
- ✅ Teste final completo

## 🔧 **PRINCÍPIOS DE SEGURANÇA ABSOLUTA**

### **1. NUNCA MODIFICAR ARQUIVOS EXISTENTES**
- `main_game.gd` permanece **100% INTACTO**
- `main_game.tscn` permanece **100% INTACTO**
- `project.godot` permanece **100% INTACTO**

### **2. APENAS CRIAR NOVOS ARQUIVOS**
- Todos os módulos são **NOVOS ARQUIVOS**
- **DUPLICAR** funcionalidades, nunca mover
- Estrutura paralela independente

### **3. TESTES INCREMENTAIS**
- Testar cada módulo isoladamente
- Verificar que jogo original continua funcionando
- **ZERO RISCO** de quebrar o jogo

### **4. DUPLICAÇÃO INTELIGENTE**
- Copiar lógica, não código literal
- Melhorar organização na duplicação
- Manter compatibilidade funcional

## ✅ **CRITÉRIOS DE SUCESSO**

### **Para cada Etapa:**
- ✅ Jogo original funciona **IDENTICAMENTE**
- ✅ Novos módulos compilam sem erro
- ✅ Funcionalidade duplicada testada
- ✅ **ZERO MODIFICAÇÕES** em arquivos existentes

### **Para o projeto final:**
- ✅ `main_game.gd` **100% INTACTO**
- ✅ Estrutura modular **COMPLETA**
- ✅ Funcionalidades **DUPLICADAS** e organizadas
- ✅ Base para **FUTURO DESENVOLVIMENTO**

## 🎯 **VANTAGENS DESTA ABORDAGEM**

### **1. RISCO ZERO**
- Jogo original nunca quebra
- Sempre funcional durante desenvolvimento
- Rollback desnecessário

### **2. DESENVOLVIMENTO PARALELO**
- Estrutura modular para novos features
- Código organizado por responsabilidade
- Fácil manutenção futura

### **3. MIGRAÇÃO GRADUAL**
- Novos desenvolvimentos usam módulos
- Código antigo permanece funcional
- Transição suave quando necessário

## 🚨 **REGRAS CRÍTICAS**

### **PROIBIDO:**
- ❌ Modificar `main_game.gd`
- ❌ Modificar `main_game.tscn`
- ❌ Modificar `project.godot`
- ❌ Mover código existente
- ❌ Deletar arquivos existentes

### **PERMITIDO:**
- ✅ Criar novos arquivos
- ✅ Criar novas pastas
- ✅ Duplicar funcionalidades
- ✅ Melhorar organização
- ✅ Testar módulos isoladamente

---

**PRÓXIMO PASSO**: Começar pela **ETAPA 1** - Criar estrutura de pastas completa