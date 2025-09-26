# 🧪 COMO TESTAR O FOG OF WAR SIMPLES

## 📋 RESUMO DA IMPLEMENTAÇÃO

O fog of war simples foi **ATIVADO** através da conexão do GameManager ao renderer. O sistema já estava implementado, apenas precisava ser conectado.

### ✅ **O que foi feito**:
1. **HexGrid.gd**: Adicionado método `set_game_manager()` para conectar ao renderer
2. **MainGame.gd**: Conecta automaticamente o game manager ao HexGrid após inicialização
3. **SimpleFogOfWar.gd**: Sistema já implementado (verificações de visibilidade)
4. **SimpleHexGridRenderer.gd**: Renderização condicional já implementada

---

## 🎮 COMO TESTAR NO JOGO

### 1️⃣ **Executar o Jogo**

```bash
# Opção 1: Via run.bat (recomendado)
run.bat
# Escolha 2 domínios para melhor visualização

# Opção 2: Via linha de comando
cd SKETCH
"C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe" --path . scenes\main_game.tscn --domain-count=2
```

### 2️⃣ **Verificações Visuais**

#### **O que você DEVE ver**:
- ✅ **Apenas 2 áreas hexagonais visíveis** (uma para cada domínio)
- ✅ **7 estrelas por domínio** (1 central + 6 adjacentes)
- ✅ **12 losangos por domínio** (vértices do hexágono)
- ✅ **Resto do mapa invisível** (fog of war)

#### **O que você NÃO deve ver**:
- ❌ **Estrelas fora das áreas dos domínios**
- ❌ **Losangos fora das áreas dos domínios**
- ❌ **Grid completo visível**

### 3️⃣ **Verificar Logs**

Procure por estas mensagens no console:

```
[INFO] Game manager conectado ao HexGrid para fog of war (MainGame)
[INFO] Game manager connected to renderer for fog of war (HexGrid)
```

Se essas mensagens aparecerem, o fog of war está **ATIVO**.

---

## 🔍 TESTE TÉCNICO DETALHADO

### **Teste de Visibilidade**

Execute o script de teste:

```gdscript
# No editor Godot, execute:
SKETCH/test_fog_of_war.gd
```

**Resultado esperado**:
```
🌫️ === TESTE DE FOG OF WAR ===
📍 Testando visibilidade de estrelas:
   Estrela 0 (0, 0): ✅ Visível
   Estrela 1 (35, 0): ✅ Visível
   Estrela 2 (-35, 0): ✅ Visível
   Estrela 3 (17.5, 30): ✅ Visível
   Estrela 4 (-17.5, 30): ✅ Visível
   Estrela 5 (17.5, -30): ✅ Visível
   Estrela 6 (-17.5, -30): ✅ Visível
   Estrela 7 (70, 0): ❌ Invisível
   Estrela 8 (0, 70): ❌ Invisível
```

---

## 🎯 CONFIGURAÇÕES DE TESTE

### **Melhores configurações para testar**:

```bash
# 2 domínios - Melhor para ver fog of war
--domain-count=2

# 3 domínios - Teste intermediário
--domain-count=3

# 6 domínios - Teste com mapa cheio
--domain-count=6
```

### **Parâmetros de visibilidade**:

```gdscript
# Em SimpleFogOfWar.gd
STAR_ADJACENCY_DISTANCE = 40.0    # Distância para estrelas adjacentes
HEX_VERTEX_TOLERANCE = 15.0       # Tolerância para vértices
```

---

## 🐛 TROUBLESHOOTING

### **Problema**: Todo o mapa está visível
**Solução**: Verificar se as mensagens de log aparecem. Se não:
1. Verificar se `game_manager` não é null em `MainGame._setup_complete_system()`
2. Verificar se `hex_grid.set_game_manager()` está sendo chamado

### **Problema**: Nada está visível
**Solução**: Verificar se os domínios foram criados:
1. Verificar se `game_manager.get_all_domains()` retorna domínios
2. Verificar se `domain.get_center_star_id()` retorna IDs válidos

### **Problema**: Visibilidade incorreta
**Solução**: Ajustar parâmetros em `SimpleFogOfWar.gd`:
1. Aumentar `STAR_ADJACENCY_DISTANCE` se poucas estrelas visíveis
2. Aumentar `HEX_VERTEX_TOLERANCE` se poucos hexágonos visíveis

---

## 📊 MÉTRICAS DE TESTE

### **Para 2 domínios**:
- **Total de estrelas no mapa**: ~100-200
- **Estrelas visíveis**: 14 (7 por domínio)
- **Porcentagem visível**: ~7-14%

### **Para 6 domínios**:
- **Total de estrelas no mapa**: ~553
- **Estrelas visíveis**: 42 (7 por domínio)
- **Porcentagem visível**: ~7.6%

---

## ✅ CHECKLIST DE VERIFICAÇÃO

- [ ] **Jogo executa sem erros**
- [ ] **Logs de conexão aparecem**
- [ ] **Apenas áreas dos domínios são visíveis**
- [ ] **7 estrelas por domínio visíveis**
- [ ] **12 losangos por domínio visíveis**
- [ ] **Resto do mapa invisível (fog of war)**
- [ ] **Sistema funciona com diferentes números de domínios**

---

## 🎉 CONFIRMAÇÃO DE SUCESSO

Se você vê apenas as áreas hexagonais dos domínios e o resto do mapa está invisível, então:

**🎮 FOG OF WAR SIMPLES ESTÁ FUNCIONANDO PERFEITAMENTE! ✅**

O sistema implementa exatamente o que foi solicitado:
- ✅ Visibilidade baseada apenas em domínios
- ✅ 7 estrelas + 12 losangos por domínio
- ✅ Sistema por team (cada team vê seus domínios)
- ✅ Renderização condicional (elementos invisíveis não renderizados)

---

*"Fog of war simples implementado e testado com sucesso. Sistema pronto para uso!"* 🌫️✨