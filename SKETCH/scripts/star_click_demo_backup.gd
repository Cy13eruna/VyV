## Backup do arquivo original
## Este é o backup do star_click_demo.gd antes da simplificação para debug

extends Node2D

const StarMapper = preload("res://scripts/star_mapper.gd")
const Unit = preload("res://scripts/unit.gd")
const Domain = preload("res://scripts/domain.gd")
const GameManager = preload("res://scripts/game_manager.gd")

@onready var hex_grid = $HexGrid
var star_mapper = null
var game_manager = null

# Dynamic map size based on domain count
const DOMAIN_TO_MAP_SIZE = {
	6: 19,
	5: 15,
	4: 13,
	3: 9,
	2: 7
}

func _ready() -> void:
	print("V&V: Sistema simplificado para debug...")
	
	# Configure dynamic map size immediately
	_configure_dynamic_map_size()
	
	print("V&V: Sistema pronto!")

## Configure dynamic map size based on domain count
func _configure_dynamic_map_size() -> void:
	# Get domain count from command line arguments
	var domain_count = _get_domain_count_from_args_early()
	
	# Get corresponding map size
	var map_size = DOMAIN_TO_MAP_SIZE.get(domain_count, 19)  # Default to 19 if not found
	
	print("🗺️ Configurando mapa dinâmico...")
	print("   Domínios: %d" % domain_count)
	print("   Tamanho: %dx%d estrelas" % [map_size, map_size])
	
	# Verify hex_grid exists
	if not hex_grid:
		print("⚠️ ERRO: HexGrid não encontrado!")
		return
	
	# Configure hex grid size
	print("   Tamanho anterior: %dx%d" % [hex_grid.grid_width, hex_grid.grid_height])
	hex_grid.grid_width = map_size
	hex_grid.grid_height = map_size
	print("   Tamanho novo: %dx%d" % [hex_grid.grid_width, hex_grid.grid_height])
	
	print("✅ Mapa configurado: %d domínios → %dx%d estrelas" % [domain_count, map_size, map_size])

## Get domain count from arguments (early version for map sizing)
func _get_domain_count_from_args_early() -> int:
	var args = OS.get_cmdline_args()
	var domain_count = 6  # Default
	
	for arg in args:
		if arg.begins_with("--domain-count="):
			domain_count = int(arg.split("=")[1])
			break
	
	# Validate
	domain_count = clamp(domain_count, 2, 6)
	
	return domain_count