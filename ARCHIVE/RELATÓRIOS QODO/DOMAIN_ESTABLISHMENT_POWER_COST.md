# ⚡ DOMAIN ESTABLISHMENT POWER COST

## 📋 REQUIREMENT IMPLEMENTED

**User Request:** "faça com que seja necessário gastar uma ação e consequentemente 1 de poder para estabelecer novo dominio"

**Translation:** Make it necessary to spend an action and consequently 1 power to establish a new domain.

## ⚡ POWER COST SYSTEM

### **🎯 New Requirement:**
- **Establishing a domain now costs 1 power**
- **Players must have at least 1 available power to establish domains**
- **Power is consumed from existing domains when establishing new ones**

## 🔧 IMPLEMENTATION DETAILS

### **1. Power Validation**
```gdscript
# Check if unit can establish domain (Settler)
func _can_unit_establish_domain(unit, game_state: Dictionary) -> bool:
    # Must have Settler technology
    if not technology_manager.has_technology(unit.owner_id, "settler"):
        return false
    
    # Must have at least 1 power to establish domain (NEW REQUIREMENT)
    var player_total_power = _get_player_total_power(unit.owner_id, game_state)
    if player_total_power < 1:
        return false
    
    # Other existing validations...
```

### **2. Power Consumption Logic**
```gdscript
# Consume power from player's domains
func _consume_player_power(player_id: int, power_needed: int, game_state: Dictionary) -> bool:
    # Find domains with available power
    var domains_with_power = []
    for domain_id in game_state.domains:
        var domain = game_state.domains[domain_id]
        if domain.owner_id == player_id and domain.get("power", 0) > 0:
            domains_with_power.append(domain)
    
    # Check if we have enough total power
    var total_available_power = 0
    for domain in domains_with_power:
        total_available_power += domain.get("power", 0)
    
    if total_available_power < power_needed:
        return false  # Not enough power available
    
    # Consume power from domains (starting with highest power domains)
    domains_with_power.sort_custom(func(a, b): return a.get("power", 0) > b.get("power", 0))
    
    var power_remaining = power_needed
    for domain in domains_with_power:
        if power_remaining <= 0:
            break
        
        var domain_power = domain.get("power", 0)
        var power_to_consume = min(domain_power, power_remaining)
        
        domain.power -= power_to_consume
        power_remaining -= power_to_consume
    
    return power_remaining == 0
```

### **3. Domain Establishment with Power Cost**
```gdscript
# Execute the settler action (sacrifice unit, create domain)
func _execute_settler_action(unit):
    var game_state = _get_game_state()
    if unit.id in game_state.units:
        # CONSUME 1 POWER FOR ESTABLISHING DOMAIN (NEW REQUIREMENT)
        var power_consumed = _consume_player_power(unit.owner_id, 1, game_state)
        if not power_consumed:
            print("ERROR: Failed to consume power for domain establishment")
            return  # Cannot establish domain without power
        
        # Create new domain...
```

### **4. Updated UI Text**
```gdscript
# Get display name for action
func _get_action_display_name(action: String) -> String:
    match action:
        "MOVE":
            return "Move (1 power)"
        "ESTABLISH_DOMAIN":
            return "Establish Domain (1 power)"  # Shows power cost
```

## 🎮 GAMEPLAY IMPACT

### **🎯 Strategic Depth:**
1. **Resource Management** - Players must carefully manage power between movement and expansion
2. **Timing Decisions** - When to expand vs when to move becomes more critical
3. **Domain Prioritization** - Players must decide which domains to use for power consumption

### **⚖️ Balance Changes:**
1. **Slower Expansion** - Domain establishment is now limited by available power
2. **Power Scarcity** - Power becomes a more valuable and contested resource
3. **Strategic Planning** - Players must plan expansion around power generation cycles

### **🔄 Power Consumption Strategy:**
- **Intelligent Consumption** - System consumes power from highest-power domains first
- **Efficient Distribution** - Minimizes impact on overall power economy
- **Preservation** - Maintains lower-power domains for future growth

## 📊 BEFORE vs AFTER

### **Before (Free Expansion):**
```
❌ Domain establishment was free (no power cost)
❌ Only required Settler technology and valid placement
❌ Unlimited expansion potential per turn
❌ Power was only used for movement
```

### **After (Power-Gated Expansion):**
```
✅ Domain establishment costs 1 power
✅ Requires both Settler technology AND available power
✅ Expansion limited by power availability
✅ Power is shared resource between movement and expansion
```

## 🎯 USER EXPERIENCE

### **🎮 Player Decision Making:**
1. **Power Allocation** - "Do I use power for movement or domain establishment?"
2. **Expansion Timing** - "When is the best time to establish a new domain?"
3. **Resource Planning** - "How do I balance power generation and consumption?"

### **⚡ Power Management:**
- **Visible Costs** - UI clearly shows power requirements for all actions
- **Smart Consumption** - System automatically optimizes power usage
- **Strategic Feedback** - Players can see power availability before committing to actions

### **🔄 Game Flow:**
- **Meaningful Choices** - Every action now has opportunity cost
- **Resource Tension** - Power scarcity creates interesting decisions
- **Strategic Depth** - Multiple valid strategies for power management

## 🛡️ TECHNICAL SAFEGUARDS

### **✅ Validation Layers:**
1. **Pre-Action Check** - Validates power availability before showing options
2. **Execution Check** - Double-checks power before consuming
3. **Fallback Handling** - Graceful failure if power becomes unavailable

### **🔧 Smart Power Consumption:**
- **Optimal Distribution** - Consumes from highest-power domains first
- **Preservation Strategy** - Maintains domain viability
- **Efficient Algorithm** - Minimizes computational overhead

---

**⚡ DOMAIN ESTABLISHMENT NOW REQUIRES STRATEGIC POWER MANAGEMENT**

> Players must now carefully balance power usage between movement and domain expansion, adding meaningful strategic depth to the expansion mechanics.