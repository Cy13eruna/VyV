# 🤝🏻 MARKET TECHNOLOGY IMPLEMENTATION

## Overview
Complete implementation of the Market technology based on specifications from i.txt. This technology unlocks market upgrade for domains, providing power duplication and global power sharing.

## Specifications from i.txt
```
- Market:
    - novo upgrade de domínio
    - pega o poder que o domínio produziu naquele turno e duplica
    - os domínios que possuírem mercado compartilharão suas reservas de poder entre si independentemnete de time: ou seja, poderão gastar o poder de outros domínios com mercado como se fosse a propria reserva de poder
    - pode ser usado apenas uma vez por domínio
```

## Implementation Details

### 1. Technology Description Update (technology_manager.gd)

#### Updated Description:
```gdscript
"market":
    description += "[b]Domain Market Upgrade Unlock[/b]\n"
    description += "Unlocks MARKET upgrade option for domains. Enables power sharing and duplication.\n\n"
    description += "[b]Mechanics:[/b]\n"
    description += "• Unlocks: MARKET upgrade option in domain upgrade menu\n"
    description += "• Effect: Duplicates power generated that turn + enables power sharing\n"
    description += "• Power sharing: All market domains share power reserves globally\n"
    description += "• Restrictions: One use per domain, works across all players"
```

### 2. Domain Upgrade System Integration

#### Upgrade Button (domain_upgrade_handler.gd):
```gdscript
# Create market button if player has market technology
var market_button = null
if current_player and technology_manager.has_technology(current_player.id, "market"):
    market_button = Button.new()
    market_button.text = "🤝🏻\nMARKET"
    
    # Check if market can be used on this domain (only once per domain)
    if not can_use_market_on_domain(clicked_domain, game_state):
        market_button.disabled = true
        market_button.modulate = Color(0.5, 0.5, 0.5, 1.0)  # Gray out
```

#### Validation Function:
```gdscript
func can_use_market_on_domain(domain, game_state: Dictionary) -> bool:
    if not domain:
        return false
    
    # Check if domain already has market upgrade (can only be used once)
    if domain.get("has_market_upgrade", false):
        return false
    
    return true  # Domain can have market
```

### 3. Market Upgrade Execution

#### Upgrade Process:
```gdscript
func _on_market_upgrade(dialog, domain, game_state: Dictionary):
    # Execute MARKET upgrade: UP + duplicate power generated this turn + enable power sharing
    var domain_level = domain.get("level", 1)
    var domain_power = domain.get("power", 1)
    
    # Check if player has enough power
    if domain_power >= domain_level:
        # Execute base upgrade
        domain.power -= domain_level
        domain.level += 1
        
        # MARKET bonus: duplicate power generated this turn
        apply_market_to_domain(domain, game_state)
        
        # Mark domain as having market upgrade (can only be used once)
        domain.has_market_upgrade = true
```

#### Market Application:
```gdscript
func apply_market_to_domain(domain, game_state: Dictionary):
    # Get power generated this turn (power_per_turn)
    var power_generated_this_turn = domain.get("power_per_turn", 0)
    
    # Duplicate the power generated this turn
    var market_bonus = power_generated_this_turn
    domain.power += market_bonus
    
    # Store market bonus for display/tracking
    domain.current_market_bonus = market_bonus
    
    # Add domain to global market network for power sharing
    if not ("market_domains" in game_state):
        game_state.market_domains = []
    
    # Add this domain to the market network if not already there
    var domain_id = domain.get("id", -1)
    if domain_id != -1 and domain_id not in game_state.market_domains:
        game_state.market_domains.append(domain_id)
```

### 4. Global Power Sharing System

#### Power Calculation (domain_technology_handler.gd):
```gdscript
func get_player_total_power(player_id: int, game_state: Dictionary) -> int:
    var total_power = 0
    
    if "domains" in game_state:
        # Check if player has any market domains
        var player_has_market = false
        for domain_id in game_state.domains:
            var domain = game_state.domains[domain_id]
            if domain.owner_id == player_id and domain.get("has_market_upgrade", false):
                player_has_market = true
                break
        
        if player_has_market and "market_domains" in game_state:
            # Player has market access - can use power from ALL market domains globally
            for domain_id in game_state.market_domains:
                if domain_id in game_state.domains:
                    var domain = game_state.domains[domain_id]
                    total_power += domain.power
        else:
            # Player has no market access - only own domains
            for domain_id in game_state.domains:
                var domain = game_state.domains[domain_id]
                if domain.owner_id == player_id:
                    total_power += domain.power
    
    return total_power
```

#### Power Deduction (action_dialog_training.gd):
```gdscript
func _deduct_power_from_player(player, game_state: Dictionary, cost: int):
    var remaining_cost = cost
    
    # Check if player has market access
    var player_has_market = false
    for domain_id in game_state.domains:
        var domain = game_state.domains[domain_id]
        if domain.owner_id == player.id and domain.get("has_market_upgrade", false):
            player_has_market = true
            break
    
    if player_has_market and "market_domains" in game_state:
        # Player has market access - can deduct from ALL market domains
        for domain_id in game_state.market_domains:
            if domain_id in game_state.domains and remaining_cost > 0:
                var domain = game_state.domains[domain_id]
                var deduction = min(domain.power, remaining_cost)
                domain.power -= deduction
                remaining_cost -= deduction
    else:
        # Player has no market access - only own domains
        for domain_id in player.domain_ids:
            if domain_id in game_state.domains and remaining_cost > 0:
                var domain = game_state.domains[domain_id]
                var deduction = min(domain.power, remaining_cost)
                domain.power -= deduction
                remaining_cost -= deduction
```

## Game Mechanics

### 1. Market Upgrade Process
1. **Prerequisite**: Player must have researched Market technology
2. **Location**: Domain upgrade menu (nuclear star click)
3. **Cost**: Domain level power to upgrade
4. **Effect**: 
   - Domain level increases by 1
   - Power generated that turn is duplicated
   - Domain joins global market network
5. **Restriction**: Can only be used once per domain

### 2. Power Duplication
- **Trigger**: When market upgrade is applied
- **Amount**: Duplicates the domain's `power_per_turn` value
- **Timing**: Immediate bonus when upgrade is applied
- **Storage**: Tracked in `current_market_bonus` for display

### 3. Global Power Sharing
- **Network**: All domains with market upgrade join `game_state.market_domains`
- **Access**: Any player with at least one market domain can access the shared pool
- **Scope**: Works across all players (independent of team)
- **Usage**: Power can be spent from any market domain for any action

### 4. Power Pool Mechanics
- **Calculation**: Sum of all power from all market domains globally
- **Deduction**: Power is deducted from market domains when spent
- **Priority**: Market domains are checked first for power deduction
- **Fallback**: If no market access, only own domains are used

## Technical Architecture

### 1. Data Structure
```gdscript
# Domain properties
domain.has_market_upgrade = true  # Marks domain as having market
domain.current_market_bonus = X   # Tracks bonus for display

# Game state
game_state.market_domains = [id1, id2, ...]  # Global market network
```

### 2. Integration Points
- **Technology System**: Unlocks market upgrade option
- **Domain Upgrade**: Adds market button to upgrade menu
- **Power System**: Modifies power calculation and deduction
- **Training System**: Uses market-aware power deduction

### 3. Cross-Player Mechanics
- **Independence**: Market sharing works regardless of player teams
- **Global Pool**: All market domains contribute to shared pool
- **Access Control**: Only players with market domains can access pool
- **Fair Usage**: Power is deducted from actual market domains

## Strategic Implications

### 1. Economic Benefits
- **Power Duplication**: Immediate bonus when upgrading
- **Shared Resources**: Access to global power pool
- **Economic Cooperation**: Incentivizes market adoption
- **Resource Efficiency**: Better power utilization across players

### 2. Game Balance
- **High Cost**: Requires Tier 2 technology research
- **One-Time Use**: Limited to once per domain
- **Shared Risk**: Other players can also access your power
- **Strategic Choice**: Trade-off between security and efficiency

### 3. Multiplayer Dynamics
- **Cooperation**: Players benefit from others having markets
- **Competition**: Shared pool creates resource competition
- **Timing**: Early market adoption provides advantages
- **Network Effects**: More market domains = larger shared pool

## Implementation Status

### ✅ Completed Features
- [x] Technology description updated
- [x] Market upgrade button in domain menu
- [x] Market upgrade validation and execution
- [x] Power duplication on upgrade
- [x] Global market network tracking
- [x] Market-aware power calculation
- [x] Market-aware power deduction
- [x] Cross-player power sharing
- [x] One-time use restriction

### 🔄 Integration Points
- [x] Domain upgrade system
- [x] Technology unlock system
- [x] Power calculation system
- [x] Training cost system
- [x] Game state management

### 📋 Testing Scenarios
1. **Basic Functionality**:
   - Research Market technology
   - Upgrade domain with market
   - Verify power duplication
   - Verify market network joining

2. **Power Sharing**:
   - Multiple players with market domains
   - Verify shared power pool calculation
   - Test power deduction from shared pool
   - Verify cross-player access

3. **Edge Cases**:
   - Market upgrade with 0 power generation
   - Single market domain in network
   - Market domain power depletion
   - Mixed market/non-market players

## Future Enhancements

### 1. Visual Indicators
- Market domain visual markers
- Shared power pool display
- Market network visualization
- Power flow animations

### 2. Advanced Features
- Market transaction history
- Power trading mechanics
- Market domain bonuses
- Economic statistics

### 3. Balance Adjustments
- Market upgrade costs
- Power sharing ratios
- Network size limits
- Access restrictions

## Conclusion

The Market technology has been fully implemented according to the specifications in i.txt. It provides a unique economic mechanic that encourages cooperation while maintaining competitive balance. The global power sharing system creates interesting strategic decisions and multiplayer dynamics, making market domains valuable assets that benefit all players in the network.