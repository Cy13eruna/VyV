# 🔗 UNIT DOMAIN ORIGINAL LINK ANALYSIS

## 🎯 PROBLEM IDENTIFIED
**ISSUE**: Unidades estabelecedoras de domínio mantêm vínculo com domínio original
**ROOT CAUSE**: Sistema de movimento usa inicial do nome para determinar domínio natal
**IMPACT**: Unidades sempre consomem poder do domínio com mesma inicial

## 🔍 CURRENT SYSTEM ANALYSIS

### **SCENARIO EXAMPLE**
1. **Player 1**: Tem domínio "Avalon" (inicial "A")
2. **Unit "Arthur"**: Inicial "A" → natal = "Avalon"
3. **Arthur estabelece**: Novo domínio "Babylon" (inicial "B")
4. **PROBLEMA**: Arthur ainda consome poder de "Avalon" para movimento

### **WHY THIS HAPPENS**
```gdscript
// Em MoveUnitUseCase._consume_power_from_natal_domain()
var unit_initial = unit.get_name_initial()  // "A" para Arthur
var natal_domain = _find_domain_by_initial(unit.owner_id, unit_initial, game_state)
// Sempre encontra "Avalon" para Arthur, mesmo após estabelecer "Babylon"
```

## 🤔 POSSIBLE SOLUTIONS

### **OPTION 1: Remove Initial-Based System Completely**
- **PRO**: Elimina todos os vínculos
- **CON**: Perde a lógica de domínio natal
- **IMPLEMENTATION**: Usar poder de qualquer domínio sempre

### **OPTION 2: Dynamic Domain Assignment**
- **PRO**: Mantém lógica natal mas permite mudança
- **CON**: Complexo de implementar
- **IMPLEMENTATION**: Unidades podem "adotar" novo domínio natal

### **OPTION 3: Settler Units Become Independent**
- **PRO**: Apenas unidades estabelecedoras ficam independentes
- **CON**: Sistema híbrido pode confundir
- **IMPLEMENTATION**: Flag especial para unidades estabelecedoras

### **OPTION 4: Power Consumption Independence**
- **PRO**: Simples e direto
- **CON**: Remove estratégia de domínio natal
- **IMPLEMENTATION**: Todas as unidades usam poder de qualquer domínio

## 📋 RECOMMENDED SOLUTION
**OPTION 4**: Remover sistema de domínio natal do movimento também
**RATIONALE**: Consistência com estabelecimento de domínio já implementado