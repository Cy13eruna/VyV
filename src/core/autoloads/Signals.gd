# res://src/core/autoloads/Signals.gd
extends Node

# --- SELEÇÃO E INPUT ---
## Emitido quando uma unidade é clicada.
signal unit_selected(unit: Node2D)

## Emitido quando o jogador clica no vazio ou muda de foco.
## IMPORTANTE: Sem argumentos para evitar erros de assinatura no GridManager e ActionController.
signal unit_deselected()

## Notifica que a câmera terminou de focar em um alvo.
signal camera_centered()

# --- GAMEPLAY / VAGABOND ---
## Atualização de interface de pontos de ação.
signal unit_ap_changed(unit: Node2D, current_ap: int, max_ap: int)

## Notifica o fim de um movimento físico no grid.
signal unit_moved(unit: Node2D, from_grid: Vector2, to_grid: Vector2)

## Solicitação de movimento (geralmente do ActionController para o GridManager).
signal unit_move_requested(unit: Node2D)

## Notifica que a unidade não pode mais agir neste turno.
signal unit_exhausted(unit: Node2D)

# --- SISTEMA DE TURNO ---
signal turn_started(player_id: int, player_color: Color, round_num: int)
signal turn_ended(player_id: int)

# --- SISTEMA DE DOMÍNIO E UI ---
## Solicita abertura do menu de upgrade/construção.
signal request_upgrade_menu(domain_ref: Node2D, click_position: Vector2)

## Notifica sucesso no upgrade de um território.
signal domain_upgraded(domain_ref: Node2D, new_level: int)

## Notifica que o poder de um domínio chegou a zero.
signal domain_power_depleted(owner_id: int)

## Notifica que o mapa mudou (ex: nova cidade fundada) e precisa de redesenho.
signal map_updated()

# --- SISTEMA DE TECNOLOGIA ---
## Abre a interface de pesquisa para o domínio selecionado.
signal request_tech_tree(domain_ref: Node2D)

## Notifica que uma nova habilidade global foi desbloqueada.
signal tech_unlocked(tech_id: String, domain_ref: Node2D)

# --- MUNDO E VISIBILIDADE (FOG OF WAR) ---
## Atualiza quais hexágonos estão iluminados para o jogador atual.
signal visibility_changed(player_id: int, lit_nodes: Array, revealed_edges: Array)

## Notifica domínios inimigos ou neutros que entraram/saíram da visão.
signal domains_visibility_updated(visible_domains: Array)

## Força uma atualização imediata da neblina de guerra.
signal fog_update_requested()