# res://src/systems/grid/Sky.gd
extends Node2D

@export var star_count: int = 25000
@export var star_min_size: float = 0.5
@export var star_max_size: float = 2
@export var star_opacity_min: float = 0.3
@export var star_opacity_max: float = 1.0

var _mesh_instance: MeshInstance2D

func _ready() -> void:
	z_index = -10
	_generate_sky_mesh()
	_apply_twinkle_shader()

func _generate_sky_mesh() -> void:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector2Array()
	var uvs = PackedVector2Array() # USADO PARA DESSINCRONIZAR (X=Speed, Y=Phase)
	var colors = PackedColorArray() # USADO PARA OPACIDADE BASE
	var indices = PackedInt32Array()
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var area = Vector2(3500, 2000)
	
	for i in range(star_count):
		var pos = Vector2(rng.randf_range(-area.x, area.x), rng.randf_range(-area.y, area.y))
		var radius = rng.randf_range(star_min_size, star_max_size)
		
		# Geramos dados únicos por estrela
		var speed = rng.randf_range(0.8, 3.5)
		var phase = rng.randf_range(0.0, 1000.0) # Phase bem alta para garantir variação
		var base_opacity = rng.randf_range(star_opacity_min, star_opacity_max)
		
		var star_uv = Vector2(speed, phase)
		var star_color = Color(1.0, 1.0, 1.0, base_opacity)
		
		var start_index = vertices.size()
		
		# Vértice Central
		vertices.append(pos)
		uvs.append(star_uv)
		colors.append(star_color)
		
		# 6 Vértices do Hexágono
		for j in range(6):
			var angle = deg_to_rad(60 * j - 30)
			vertices.append(pos + Vector2(cos(angle), sin(angle)) * radius)
			uvs.append(star_uv)
			colors.append(star_color)
			
			indices.append(start_index)
			indices.append(start_index + 1 + j)
			indices.append(start_index + 1 + ((j + 1) % 6))

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	_mesh_instance = MeshInstance2D.new()
	_mesh_instance.mesh = mesh
	add_child(_mesh_instance)

func _apply_twinkle_shader() -> void:
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	
	void fragment() {
		// UV.x guarda a velocidade
		// UV.y guarda o offset/fase
		float speed = UV.x;
		float phase = UV.y;
		float base_a = COLOR.a;
		
		// TIME + phase garante que cada estrela esteja em um ponto diferente da curva
		// O uso de fract no tempo ajuda a manter a precisão após horas de jogo
		float t = TIME + phase;
		float twinkle = (sin(t * speed) + 1.0) * 0.5;
		
		// Torna o brilho mais "afiado" (pica-pisca real em vez de fade suave)
		twinkle = pow(twinkle, 4.0); 
		
		// Mistura entre quase apagada e o brilho máximo definido no COLOR.a
		float final_a = mix(base_a * 0.05, base_a, twinkle);
		
		COLOR = vec4(1.0, 1.0, 1.0, final_a);
	}
	"""
	var mat = ShaderMaterial.new()
	mat.shader = shader
	_mesh_instance.material = mat