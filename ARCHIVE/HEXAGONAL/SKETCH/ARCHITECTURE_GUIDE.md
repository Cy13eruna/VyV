# 🏗️ **GUIA DE ARQUITETURA V&V - REVOLUÇÃO EM ANDAMENTO**

## 🚨 **STATUS ATUAL: EM REFATORAÇÃO CRÍTICA**
**⚠️ ATENÇÃO: Este projeto está passando por uma revolução arquitetural completa!**
**📋 Roteiro completo: `../.qodo/CRITICAL_REFACTOR_ROADMAP.md`**

---

## 📁 **ESTRUTURA ATUAL E DESTINO**

### **🔴 PROBLEMAS CRÍTICOS IDENTIFICADOS:**
1. **main_game.gd** - 700+ linhas, viola SOLID ➜ **REFATORAR URGENTE**
2. **Memory leaks** - 25+ new() sem pool ➜ **IMPLEMENTAR OBJECTPOOL**
3. **Sistemas órfãos** - Criados mas não usados ➜ **INTEGRAR**
4. **Zero testes** - Impossível garantir qualidade ➜ **CRIAR SUITE**

---

## 📂 **MAPEAMENTO DE DIRETÓRIOS**

```
SKETCH/
├── 🎯 scripts/
│   ├── 🔧 core/                    # ✅ SISTEMAS FUNDAMENTAIS
│   │   ├── logger.gd              # ✅ Sistema de logging condicional
│   │   ├── object_pool.gd         # ⚠️  CRIADO MAS NÃO USADO - INTEGRAR!
│   │   └── config.gd              # ⚠️  CRIADO MAS NÃO USADO - INTEGRAR!
│   │
│   ├── 🎮 game/                    # ✅ LÓGICA DO JOGO
│   │   └── game_manager.gd        # ✅ Gerenciador principal
│   │
│   ├── 🎭 entities/                # ✅ ENTIDADES DO JOGO
│   │   ├── unit.gd                # ⚠️  PRECISA IMPLEMENTAR IGameEntity
│   │   ├── domain.gd              # ⚠️  PRECISA IMPLEMENTAR IGameEntity
│   │   └── star_mapper.gd         # ✅ Mapeamento de estrelas
│   │
│   ├── 🎨 rendering/               # ✅ SISTEMA DE RENDERIZAÇÃO
│   │   ├── hex_grid.gd            # ✅ Grid hexagonal principal
│   │   ├── hex_grid_renderer.gd   # ✅ Renderização otimizada
│   │   ├── hex_grid_cache.gd      # ✅ Cache inteligente
│   │   ├── hex_grid_geometry.gd   # ✅ Cálculos geométricos
│   │   └── hex_grid_config.gd     # ✅ Configuração do grid
│   │
│   ├── 🧩 components/              # ⚠️  ÓRFÃOS - NÃO UTILIZADOS
│   │   ├── visual_component.gd    # ❌ CRIADO MAS NÃO USADO
│   │   ├── unit_visual_component.gd # ❌ CRIADO MAS NÃO USADO
│   │   └── domain_visual_component.gd # ❌ CRIADO MAS NÃO USADO
│   │
│   ├── 🔌 interfaces/              # ⚠️  ÓRFÃOS - NÃO IMPLEMENTADOS
│   │   └── i_game_entity.gd       # ❌ INTERFACE CRIADA MAS NÃO USADA
│   │
│   ├── ⚙️  systems/                # ⚠️  ÓRFÃOS - PARCIALMENTE USADOS
│   │   ├── event_bus.gd           # ❌ AUTOLOAD MAS NÃO USADO NO CÓDIGO
│   │   ├── game_server.gd         # ❌ CRIADO MAS NÃO USADO
│   │   ├── input_manager.gd       # ❌ CRIADO MAS NÃO USADO
│   │   ├── player_instance.gd     # ❌ CRIADO MAS NÃO USADO
│   │   ├── shared_game_state.gd   # ❌ CRIADO MAS NÃO USADO
│   │   └── terrain_system.gd      # ❌ CRIADO MAS NÃO USADO
│   │
│   ├── 🖥️  ui/                     # ⚠️  ÓRFÃOS - NÃO UTILIZADOS
│   │   └── scroll_navigation.gd   # ❌ CRIADO MAS NÃO USADO
│   │
│   └── 🚨 main_game.gd             # 🔴 ARQUIVO MONOLÍTICO - REFATORAR!
│
├── 🎬 scenes/
│   └── main_game.tscn             # ✅ Cena principal
│
└── 📊 data/                        # ⚠️  VAZIO - IMPLEMENTAR CONFIGS
```

---

## 🎯 **PLANO DE REFATORAÇÃO**

### **FASE 1: CORREÇÕES CRÍTICAS** 🔴
```
📋 PRIORIDADE MÁXIMA:
1. Dividir main_game.gd em:
   ├── TurnManager (turnos)
   ├── InputHandler (input)
   ├── UIManager (interface)
   └── GameController (orquestração)

2. Integrar ObjectPool:
   ├── Substituir 25+ new() por pool
   ├── Implementar factories
   └── Cleanup adequado

3. Usar EventBus:
   ├── Migrar comunicação direta
   ├── Implementar listeners
   └── Desacoplar sistemas
```

### **FASE 2: ARQUITETURA SUSTENTÁVEL** 🟡
```
📋 INTEGRAÇÃO DE SISTEMAS:
1. Implementar IGameEntity:
   ├── Unit extends IGameEntity
   ├── Domain extends IGameEntity
   └── Validação de contratos

2. Usar Config System:
   ├── Substituir magic numbers
   ├── Arquivo de configuração
   └── Hot-reload

3. Sistema de Componentes:
   ├── Usar VisualComponent
   ├── ComponentManager
   └── Attachment/detachment
```

### **FASE 3: QUALIDADE E PRODUÇÃO** 🟢
```
📋 QUALIDADE TOTAL:
1. Testes Abrangentes:
   ├── Framework de testes
   ├── Testes unitários
   ├── Testes de integração
   └── 80%+ cobertura

2. Error Handling:
   ├── Result<T> type
   ├── Validação de input
   ├── Fallbacks
   └── Recovery system

3. Documentação:
   ├── Diagramas de arquitetura
   ├── Guia de contribuição
   ├── APIs documentadas
   └── Troubleshooting
```

---

## 🚨 **ALERTAS PARA DESENVOLVEDORES**

### **❌ NÃO FAÇA:**
- Adicionar código ao main_game.gd (está sendo refatorado)
- Criar novos objetos com new() (use ObjectPool)
- Comunicação direta entre sistemas (use EventBus)
- Magic numbers (use Config)
- Código sem testes

### **✅ FAÇA:**
- Siga o roteiro em `REVOLUCAO_ARQUITETURAL.qodo`
- Use sistemas existentes (Logger, Config, ObjectPool)
- Implemente interfaces (IGameEntity)
- Escreva testes para novo código
- Documente decisões arquiteturais

---

## 📊 **MÉTRICAS DE PROGRESSO**

### **🎯 METAS:**
- [ ] main_game.gd < 200 linhas
- [ ] Zero new() diretos
- [ ] 100% uso do EventBus
- [ ] 80%+ cobertura de testes
- [ ] Zero magic numbers

### **📈 TRACKING:**
```bash
# Verificar progresso:
wc -l scripts/main_game.gd          # Meta: < 200 linhas
grep -r "new()" scripts/             # Meta: 0 ocorrências diretas
grep -r "EventBus" scripts/          # Meta: usado em todos os sistemas
```

---

## 🔗 **LINKS IMPORTANTES**

- **📋 Roteiro Completo:** `../REVOLUCAO_ARQUITETURAL.qodo`
- **🏗️ Arquitetura Atual:** Este arquivo
- **📚 Documentação:** `README.md`
- **🧪 Testes:** `tests/` (a ser criado)

---

## 🚀 **PRÓXIMOS PASSOS**

1. **LEIA** o roteiro completo em `REVOLUCAO_ARQUITETURAL.qodo`
2. **ESCOLHA** uma tarefa da Fase 1 (críticas)
3. **IMPLEMENTE** seguindo as diretrizes
4. **TESTE** antes de commit
5. **DOCUMENTE** mudanças arquiteturais

---

**🎉 OBJETIVO: Transformar protótipo em sistema production-ready!**
**⏰ PRAZO: 2-3 semanas de revolução arquitetural**
**🎯 RESULTADO: Código sustentável, testável e escalável**