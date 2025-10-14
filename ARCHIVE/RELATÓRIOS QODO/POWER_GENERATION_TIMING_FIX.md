# ⚡ POWER GENERATION TIMING FIX

## 🎯 PROBLEM IDENTIFIED
**ISSUE**: Domínios produzem poder ao clicar "skip turn" (fim do turno)
**EXPECTED**: Domínios devem produzir poder como primeira ação do turno do jogador
**ROOT CAUSE**: Lógica de produção está em `advance_to_next_turn()` antes da troca

## 🔧 SOLUTION IMPLEMENTED
**MOVE POWER GENERATION**: Da função de fim de turno para início de turno

### **CURRENT BROKEN LOGIC**
```gdscript
# ERRADO: Produz poder antes de trocar de jogador (fim do turno)
static func advance_to_next_turn(...):
    var current_player = get_current_player(turn_data, players_data)
    if current_player:
        _restore_player_actions(current_player, units_data)
        _restore_player_power(current_player, domains_data)  # AQUI ESTÁ ERRADO
    
    # Move to next player...
```

### **NEW CORRECT LOGIC**
```gdscript
# CORRETO: Produz poder após trocar para o novo jogador (início do turno)
static func advance_to_next_turn(...):
    # Restore actions for current player before switching
    var current_player = get_current_player(turn_data, players_data)
    if current_player:
        _restore_player_actions(current_player, units_data)
    
    # Move to next player...
    # DEPOIS da troca:
    var new_current_player = get_current_player(turn_data, players_data)
    if new_current_player:
        _restore_player_power(new_current_player, domains_data)  # AGORA ESTÁ CORRETO
```

## 📋 CHANGES MADE

### **TurnService (turn_service_clean.gd)**
- ✅ **REMOVED**: Power generation from before player switch
- ✅ **MOVED**: `_restore_player_power()` call to after player switch
- ✅ **ADDED**: Domain occupation update at start of new turn
- ✅ **TIMING**: Power generation now happens at start of new player's turn
- ✅ **LOGIC**: Domains produce power when player's turn begins, not ends

### **IMPLEMENTATION DETAILS**
```gdscript
# Power generation now happens AFTER player switch:
if next_player.is_in_game():
    turn_data.current_player_id = next_player_id
    # ... switch logic ...
    
    # GENERATE POWER FOR NEW PLAYER AT START OF THEIR TURN
    _update_domain_occupations_turn(units_data, domains_data)
    _restore_player_power(next_player, domains_data)
```

## 🎮 IMPACT
- **FIXES**: Poder produzido no momento correto (início do turno)
- **IMPROVES**: Lógica mais intuitiva para jogadores
- **ENSURES**: Produção acontece antes das ações do jogador