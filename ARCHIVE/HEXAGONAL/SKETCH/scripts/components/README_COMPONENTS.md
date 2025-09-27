# 🧩 **COMPONENTS - SISTEMA DE COMPONENTES ÓRFÃO**

## 🚨 **STATUS: COMPONENTES CRIADOS MAS NÃO UTILIZADOS!**
**⚠️ SISTEMA ECS PARCIAL - CRIADO MAS IGNORADO PELO CÓDIGO PRINCIPAL**

---

## 📁 **COMPONENTES DISPONÍVEIS**

### ❌ **VisualComponent** - Componente Base (NÃO USADO!)
```gdscript
# PROBLEMA: Classe base criada mas entidades não herdam
# IMPACTO: Lógica visual espalhada pelas entidades
# POTENCIAL: Sistema ECS limpo e modular

# FUNCIONALIDADES DISPONÍVEIS:
- Interface comum para componentes visuais
- Lifecycle management (create, update, destroy)
- Attachment/detachment system
- Z-index management
```

### ❌ **UnitVisualComponent** - Visual de Unidades (NÃO USADO!)
```gdscript
# PROBLEMA: Componente específico criado mas Unit.gd não usa
# IMPACTO: Lógica visual misturada na entidade Unit
# LOCALIZAÇÃO: Unit.gd tem create_visual() próprio

# DEVERIA SER USADO ASSIM:
var visual_component = UnitVisualComponent.new()
visual_component.attach_to(unit, parent_node)

# MAS Unit.gd FAZ ASSIM:
visual_node = Label.new()  # ❌ LÓGICA VISUAL NA ENTIDADE
```

### ❌ **DomainVisualComponent** - Visual de Domínios (NÃO USADO!)
```gdscript
# PROBLEMA: Componente específico criado mas Domain.gd não usa
# IMPACTO: Lógica visual misturada na entidade Domain
# LOCALIZAÇÃO: Domain.gd tem _create_visual() próprio

# DEVERIA SER USADO ASSIM:
var visual_component = DomainVisualComponent.new()
visual_component.attach_to(domain, parent_node)

# MAS Domain.gd FAZ ASSIM:
visual_node = Node2D.new()  # ❌ LÓGICA VISUAL NA ENTIDADE
```

---

## 🚨 **PROBLEMAS CAUSADOS**

### **1. VIOLAÇÃO DO SINGLE RESPONSIBILITY PRINCIPLE**
```gdscript
# PROBLEMA: Entidades fazem TUDO
class Unit extends RefCounted:
    # ❌ Lógica de negócio + visual + input + estado
    func create_visual()  # Deveria ser componente
    func position_at_star()  # OK - lógica de negócio
    func move_to_star()  # OK - lógica de negócio
    func _update_visual_for_state()  # Deveria ser componente
```

### **2. CÓDIGO DUPLICADO**
```gdscript
# Unit.gd:
visual_node = Label.new()
visual_node.text = emoji_text
visual_node.add_theme_font_size_override("font_size", font_size)

# Domain.gd:
visual_node = Node2D.new()
visual_node.z_index = z_index
visual_node.draw.connect(_draw_domain_hexagon)

# ❌ LÓGICA SIMILAR REPETIDA - DEVERIA SER COMPONENTIZADA
```

### **3. ACOPLAMENTO ALTO**
```gdscript
# PROBLEMA: Entidades acopladas ao sistema de rendering
# Unit precisa conhecer Label, Node2D, parent_node, etc.
# Domain precisa conhecer draw, z_index, etc.
# ❌ DEVERIA SER DESACOPLADO VIA COMPONENTES
```

---

## 🎯 **ARQUITETURA ECS IDEAL**

### **COMO DEVERIA SER:**
```gdscript
# Entity (Unit/Domain) - Apenas dados e lógica de negócio
class Unit extends IGameEntity:
    var position: Vector2
    var actions_remaining: int
    
    func move_to(target: Vector2) -> bool:
        # Apenas lógica de negócio
        pass

# Component (Visual) - Apenas responsabilidade visual
class UnitVisualComponent extends VisualComponent:
    func create_visual() -> void:
        # Apenas lógica visual
        pass
    
    func update_position(pos: Vector2) -> void:
        # Apenas atualização visual
        pass

# System (ComponentManager) - Gerencia componentes
class ComponentManager:
    func attach_component(entity, component):
        # Gerencia lifecycle dos componentes
        pass
```

---

## 🔄 **PLANO DE MIGRAÇÃO**

### **FASE 1: Extrair Lógica Visual das Entidades**
```gdscript
# 1. Migrar Unit.create_visual() para UnitVisualComponent
# 2. Migrar Domain._create_visual() para DomainVisualComponent
# 3. Remover lógica visual das entidades
# 4. Manter apenas interface de comunicação
```

### **FASE 2: Implementar ComponentManager**
```gdscript
# 1. Criar sistema de attachment/detachment
# 2. Lifecycle management automático
# 3. Comunicação via EventBus
# 4. Pool de componentes para performance
```

### **FASE 3: Expandir Sistema ECS**
```gdscript
# 1. Criar mais componentes (InputComponent, PhysicsComponent)
# 2. Sistema de queries (get_entities_with_components)
# 3. Update loops otimizados
# 4. Serialização de componentes
```

---

## 📊 **BENEFÍCIOS DA MIGRAÇÃO**

### **ANTES (Estado Atual):**
❌ Entidades fazem tudo (visual + lógica + estado)
❌ Código duplicado entre Unit e Domain
❌ Acoplamento alto com sistema de rendering
❌ Difícil de testar e manter
❌ Componentes órfãos não utilizados

### **DEPOIS (ECS Implementado):**
✅ Separação clara de responsabilidades
✅ Componentes reutilizáveis
✅ Baixo acoplamento
✅ Fácil de testar (componentes isolados)
✅ Sistema ECS completo e funcional

---

## 🚀 **IMPLEMENTAÇÃO PRÁTICA**

### **PASSO 1: Migrar Unit Visual**
```gdscript
# ANTES (Unit.gd):
func create_visual(parent_node: Node) -> void:
    visual_node = Label.new()  # ❌
    visual_node.text = emoji_text
    parent_node.add_child(visual_node)

# DEPOIS (Unit.gd):
func attach_visual_component(parent_node: Node) -> void:
    var visual_comp = UnitVisualComponent.new()  # ✅
    ComponentManager.attach(self, visual_comp, parent_node)
```

### **PASSO 2: Migrar Domain Visual**
```gdscript
# ANTES (Domain.gd):
func _create_visual(parent_node: Node) -> bool:
    visual_node = Node2D.new()  # ❌
    visual_node.draw.connect(_draw_domain_hexagon)
    parent_node.add_child(visual_node)

# DEPOIS (Domain.gd):
func attach_visual_component(parent_node: Node) -> void:
    var visual_comp = DomainVisualComponent.new()  # ✅
    ComponentManager.attach(self, visual_comp, parent_node)
```

### **PASSO 3: ComponentManager**
```gdscript
# Criar sistema central de gerenciamento
class ComponentManager:
    static var entity_components = {}
    
    static func attach(entity, component, parent_node):
        component.setup(entity, parent_node)
        entity_components[entity] = entity_components.get(entity, [])
        entity_components[entity].append(component)
    
    static func detach(entity, component_type):
        # Cleanup e remoção
        pass
```

---

## 📈 **MÉTRICAS DE SUCESSO**

### **OBJETIVOS:**
- [ ] Zero lógica visual nas entidades
- [ ] 100% uso dos componentes criados
- [ ] ComponentManager implementado
- [ ] Comunicação via EventBus
- [ ] Testes para cada componente

### **TRACKING:**
```bash
# Verificar migração:
grep -c "visual_node.*new()" scripts/entities/  # Meta: 0
grep -c "VisualComponent" scripts/entities/     # Meta: 2+
grep -c "ComponentManager" scripts/            # Meta: 5+
```

---

## 🔗 **DEPENDÊNCIAS**

### **VisualComponent:**
- ⚠️ Precisa de ComponentManager
- ⚠️ Precisa de EventBus para comunicação

### **UnitVisualComponent:**
- ⚠️ Precisa de migração do Unit.gd
- ⚠️ Precisa de ObjectPool para Labels

### **DomainVisualComponent:**
- ⚠️ Precisa de migração do Domain.gd
- ⚠️ Precisa de ObjectPool para Node2Ds

---

## 🎉 **RESULTADO FINAL**

**Transformar sistema ECS órfão em arquitetura modular e reutilizável!**

**📋 Roteiro completo:** `../../.qodo/CRITICAL_REFACTOR_ROADMAP.md`