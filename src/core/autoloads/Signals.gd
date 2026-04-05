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
signal turn_started(player_id: int, player_color: Color, round_num: int)
signal turn_ended(player_id: int)

# --- SISTEMA DE DOMÍNIO E POP-UP ---
## Emitido pelo Domínio para solicitar a abertura do Balão de UI.
## Agora inclui 'click_position' para que a câmera possa centralizar no local.
signal request_upgrade_menu(domain_ref: Node2D, click_position: Vector2)

## Emitido após o nível do domínio ser alterado com sucesso.
signal domain_upgraded(domain_ref: Node2D, new_level: int)

## Notifica que o jogador ficou sem recursos no domínio.
signal domain_power_depleted(owner_id: int)

# --- SISTEMA DE TECNOLOGIA (NOVO) ---
## Solicita a abertura da Árvore de Tecnologias para um domínio específico.
signal request_tech_tree(domain_ref: Node2D)

## Notifica que uma tecnologia específica foi desbloqueada.
signal tech_unlocked(tech_id: String, domain_ref: Node2D)

# --- MUNDO E VISIBILIDADE ---
## Notifica que a visibilidade do jogador atual mudou.
signal visibility_changed(player_id: int, lit_nodes: Array, revealed_edges: Array)

## Notifica quando a lista de domínios visíveis muda.
signal domains_visibility_updated(visible_domains: Array)

## Dispara o cálculo de neblina manualmente.
signal fog_update_requested