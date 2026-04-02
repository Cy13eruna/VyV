# res://src/core/autoloads/Signals.gd
extends Node

# --- SELEÇÃO E INPUT ---
signal unit_selected(unit: Node2D)
signal unit_deselected
signal camera_centered() # Notifica que a câmera terminou de focar

# --- GAMEPLAY / VAGABOND ---
signal unit_ap_changed(unit: Node2D, current_ap: int, max_ap: int)
signal unit_moved(unit: Node2D, from_grid: Vector2, to_grid: Vector2)
signal unit_exhausted(unit: Node2D)

# --- SISTEMA DE TURNO ---
# round_num incluído para compatibilidade com o GameHUD e PlayerTurnScreen
signal turn_started(player_id: int, player_color: Color, round_num: int)
signal turn_ended(player_id: int)

# --- SISTEMA DE DOMÍNIO E POP-UP ---
# Emitido pelo Domínio para solicitar a abertura do Balão de UI
signal request_upgrade_menu(domain_ref: Node2D)
# Emitido após o nível do domínio ser alterado com sucesso
signal domain_upgraded(domain_ref: Node2D, new_level: int)

# 💡 NOVO SINAL: Notifica que o jogador ficou sem recursos no domínio
# Isso deve ser usado para exaurir unidades e impedir movimentos extras
signal domain_power_depleted(owner_id: int)

# --- MUNDO E VISIBILIDADE ---
# Notifica que a visibilidade do jogador atual mudou
signal visibility_changed(player_id: int, lit_nodes: Array, revealed_edges: Array)

# Notifica quando a lista de domínios visíveis muda
signal domains_visibility_updated(visible_domains: Array)

# Mantive este caso você use para disparar o cálculo manualmente
signal fog_update_requested