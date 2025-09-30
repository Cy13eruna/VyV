# 📋 ROTEIRO PARA DESMEMBRAMENTO DO MONÓLITO

## 🎯 **OBJETIVO**
Migrar as funções do `main_game.gd` para arquivos separados, mantendo a funcionalidade intacta.

## 📊 **ANÁLISE DO CÓDIGO ATUAL**

### **Funções Identificadas (20 funções):**
1. `_ready()` - Inicialização principal
2. `_generate_hex_grid()` - Geração do grid hexagonal
3. `_hex_to_pixel()` - Conversão de coordenadas
4. `_hex_direction()` - Direções hexagonais
5. `_generate_paths()` - Geração de caminhos
6. `_find_hex_coord_index()` - Busca de coordenadas
7. `_generate_terrain()` - Geração de terreno
8. `_create_ui()` - Criação da interface
9. `_process()` - Loop principal
10. `_draw()` - Renderização
11. `_get_path_color()` - Cores dos caminhos
12. `_can_move_to()` - Validação de movimento
13. `_unhandled_input()` - Entrada do usuário
14. `_try_move()` - Execução de movimento
15. `_on_skip_turn()` - Mudança de turno
16. `_update_ui()` - Atualização da interface

### **Categorização por Responsabilidade:**

#### **🔷 GRID & COORDENADAS (5 funções)**
- `_generate_hex_grid()`
- `_hex_to_pixel()`
- `_hex_direction()`
- `_generate_paths()`
- `_find_hex_coord_index()`

#### **🔷 TERRENO (1 função)**
- `_generate_terrain()`

#### **🔷 RENDERIZAÇÃO (3 funções)**
- `_draw()`
- `_get_path_color()`

#### **🔷 MOVIMENTO (2 funções)**
- `_can_move_to()`
- `_try_move()`

#### **🔷 INTERFACE (2 funções)**
- `_create_ui()`
- `_update_ui()`

#### **🔷 INPUT (1 função)**
- `_unhandled_input()`

#### **🔷 GAME LOGIC (2 funções)**
- `_on_skip_turn()`

#### **🔷 CORE (2 funções - MANTER NO MAIN)**
- `_ready()`
- `_process()`

## 🗂️ **ESTRUTURA DE ARQUIVOS PROPOSTA**

```
SKETCH/
├── main_game.gd (REDUZIDO - apenas coordenação)
├── grid_manager.gd (Grid & Coordenadas)
├── terrain_manager.gd (Terreno)
├── render_manager.gd (Renderização)
├── movement_manager.gd (Movimento)
├── ui_manager.gd (Interface)
├── input_manager.gd (Input)
├── game_logic.gd (Lógica do jogo)
└── project.godot
```

## 📝 **PLANO DE EXECUÇÃO (8 ETAPAS)**

### **ETAPA 1: Criar GridManager**
- ✅ Migrar funções de grid e coordenadas
- ✅ Manter interface simples
- ✅ Testar geração de grid

### **ETAPA 2: Criar TerrainManager**
- ✅ Migrar geração de terreno
- ✅ Integrar com GridManager
- ✅ Testar geração de terreno

### **ETAPA 3: Criar RenderManager**
- ✅ Migrar funções de desenho
- ✅ Manter acesso aos dados do grid
- ✅ Testar renderização

### **ETAPA 4: Criar MovementManager**
- ✅ Migrar validação e execução de movimento
- ✅ Integrar com grid e game state
- ✅ Testar movimento

### **ETAPA 5: Criar UIManager**
- ✅ Migrar criação e atualização de UI
- ✅ Manter referências necessárias
- ✅ Testar interface

### **ETAPA 6: Criar InputManager**
- ✅ Migrar tratamento de input
- ✅ Conectar com outros managers
- ✅ Testar controles

### **ETAPA 7: Criar GameLogic**
- ✅ Migrar lógica de turnos
- ✅ Centralizar estado do jogo
- ✅ Testar mudança de turnos

### **ETAPA 8: Refatorar Main**
- ✅ Reduzir main_game.gd ao mínimo
- ✅ Apenas coordenação entre managers
- ✅ Teste final completo

## 🔧 **PRINCÍPIOS DE SEGURANÇA**

### **1. UMA ETAPA POR VEZ**
- Migrar apenas um grupo de funções por vez
- Testar após cada migração
- Não prosseguir se houver bugs

### **2. MANTER INTERFACES SIMPLES**
- Funções públicas claras
- Parâmetros mínimos necessários
- Retornos consistentes

### **3. PRESERVAR ESTADO**
- Não alterar variáveis de estado
- Manter referências necessárias
- Evitar duplicação de dados

### **4. TESTES INCREMENTAIS**
- Testar cada manager individualmente
- Verificar integração após cada etapa
- Rollback se necessário

## ✅ **CRITÉRIOS DE SUCESSO**

### **Para cada Manager:**
- ✅ Compila sem erros
- ✅ Funcionalidade preservada
- ✅ Interface clara
- ✅ Sem duplicação de código

### **Para o projeto final:**
- ✅ Jogo funciona identicamente
- ✅ Código organizado por responsabilidade
- ✅ main_game.gd reduzido (< 50 linhas)
- ✅ Fácil manutenção e extensão

## 🚨 **PONTOS DE ATENÇÃO**

1. **Referências entre managers** - Evitar dependências circulares
2. **Estado compartilhado** - Centralizar em main ou game_logic
3. **Signals vs chamadas diretas** - Preferir interfaces simples
4. **Performance** - Não criar overhead desnecessário

---

**PRÓXIMO PASSO**: Começar pela ETAPA 1 - Criar GridManager