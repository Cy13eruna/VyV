# 🔧 **CORE SYSTEMS - FUNDAMENTOS DO V&V**

## 📋 **STATUS: PARCIALMENTE IMPLEMENTADO**
**⚠️ SISTEMAS CRIADOS MAS NÃO TOTALMENTE INTEGRADOS**

---

## 📁 **SISTEMAS DISPONÍVEIS**

### ✅ **Logger** - Sistema de Logging Condicional
```gdscript
# USO CORRETO:
const Logger = preload("res://scripts/core/logger.gd")
Logger.debug("Mensagem de debug", "ComponentName")
Logger.info("Informação importante", "ComponentName") 
Logger.warning("Aviso", "ComponentName")
Logger.error("Erro crítico", "ComponentName")

# CONFIGURAÇÃO:
Logger.set_debug_mode(true)  # Ativar logs detalhados
Logger.set_level(Logger.Level.INFO)  # Definir nível mínimo
```

### ⚠️ **ObjectPool** - Pool de Objetos (NÃO USADO!)
```gdscript
# PROBLEMA: Criado mas não integrado no código principal
# TODO CRÍTICO: Substituir 25+ new() por ObjectPool

# USO CORRETO:
const ObjectPool = preload("res://scripts/core/object_pool.gd")

# Em vez de:
var highlight = Node2D.new()  # ❌ MEMORY LEAK!

# Use:
var highlight = ObjectPool.get_object("Highlight", highlight_factory)  # ✅
ObjectPool.return_object("Highlight", highlight)  # ✅ Cleanup
```

### ⚠️ **Config** - Sistema de Configuração (NÃO USADO!)
```gdscript
# PROBLEMA: Criado mas não integrado, magic numbers espalhados
# TODO CRÍTICO: Substituir valores hardcoded por Config

# USO CORRETO:
const Config = preload("res://scripts/core/config.gd")

# Em vez de:
var click_tolerance = 30.0  # ❌ MAGIC NUMBER!

# Use:
var click_tolerance = Config.get_setting("input", "click_tolerance", 30.0)  # ✅
```

---

## 🚨 **PROBLEMAS CRÍTICOS**

### **1. ObjectPool NÃO USADO**
```bash
# Encontrados 25+ new() diretos:
grep -r "new()" ../  # ❌ TODOS DEVERIAM USAR OBJECTPOOL
```

### **2. Config NÃO USADO**
```bash
# Magic numbers espalhados:
grep -r "24.0\|54.0\|38.0\|30.0" ../  # ❌ DEVERIAM USAR CONFIG
```

### **3. Logger PARCIALMENTE USADO**
```bash
# Ainda há prints diretos:
grep -r "print(" ../  # ❌ DEVERIAM USAR LOGGER
```

---

## 🎯 **PLANO DE INTEGRAÇÃO**

### **FASE 1: ObjectPool Integration**
```gdscript
# 1. Identificar todos os new() no código
# 2. Criar factories para objetos comuns:

func create_highlight_factory() -> Callable:
    return func() -> Node2D:
        var node = Node2D.new()
        node.z_index = 60
        return node

# 3. Substituir new() por ObjectPool.get_object()
# 4. Implementar cleanup com ObjectPool.return_object()
```

### **FASE 2: Config Integration**
```gdscript
# 1. Criar arquivo de configuração padrão
# 2. Migrar magic numbers:

# ANTES:
var click_width = 24.0
var click_height = 54.0
var max_adjacent_distance = 38.0

# DEPOIS:
var click_width = Config.get_setting("input", "click_width", 24.0)
var click_height = Config.get_setting("input", "click_height", 54.0)
var max_adjacent_distance = Config.get_setting("game", "max_adjacent_distance", 38.0)
```

### **FASE 3: Logger Complete Integration**
```gdscript
# Substituir todos os prints restantes:
# ANTES:
print("Debug info")

# DEPOIS:
Logger.debug("Debug info", "ComponentName")
```

---

## 📊 **MÉTRICAS DE INTEGRAÇÃO**

### **OBJETIVOS:**
- [ ] Zero new() diretos (usar ObjectPool)
- [ ] Zero magic numbers (usar Config)
- [ ] Zero prints diretos (usar Logger)
- [ ] Configuração centralizada
- [ ] Memory management otimizado

### **TRACKING:**
```bash
# Verificar progresso:
grep -c "new()" ../scripts/           # Meta: 0
grep -c "print(" ../scripts/          # Meta: 0 (exceto Logger)
grep -c "Config.get_setting" ../scripts/  # Meta: 20+
```

---

## 🔗 **DEPENDÊNCIAS**

### **Logger:**
- ✅ Standalone, sem dependências
- ✅ Usado em todos os sistemas

### **ObjectPool:**
- ⚠️ Precisa de factories implementadas
- ⚠️ Precisa de integração no main_game.gd

### **Config:**
- ⚠️ Precisa de arquivo de configuração padrão
- ⚠️ Precisa de migração de magic numbers

---

## 🚀 **PRÓXIMOS PASSOS**

1. **PRIORIDADE 1:** Integrar ObjectPool no main_game.gd
2. **PRIORIDADE 2:** Criar arquivo de configuração padrão
3. **PRIORIDADE 3:** Migrar magic numbers para Config
4. **PRIORIDADE 4:** Completar integração do Logger

**📋 Detalhes completos:** `../../.qodo/CRITICAL_REFACTOR_ROADMAP.md`