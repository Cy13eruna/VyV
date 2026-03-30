# res://src/core/autoloads/Signals.gd
extends Node

# --- SELEÇÃO E INPUT ---
signal unit_selected(unit: Node2D)
signal unit_deselected

# --- GAMEPLAY / VAGABOND ---
signal unit_ap_changed(unit: Node2D, current_ap: int, max_ap: int)
signal unit_moved(unit: Node2D, from_grid: Vector2, to_grid: Vector2)
signal unit_exhausted(unit: Node2D)

# --- SISTEMA DE TURNO ---
signal turn_started(player_id: int, player_color: Color)
signal turn_ended(player_id: int)

# --- MUNDO E VISIBILIDADE ---
# Notifica que a visibilidade do jogador atual mudou
# lit_nodes: Array[Vector2] (O que está aceso agora)
# revealed_edges: Array[Array[Vector2, Vector2]] (O que foi descoberto permanentemente)
signal visibility_changed(player_id: int, lit_nodes: Array, revealed_edges: Array)

# Notifica quando a lista de domínios visíveis muda
signal domains_visibility_updated(visible_domains: Array)

# Mantive este caso você use para disparar o cálculo manualmente
signal fog_update_requested