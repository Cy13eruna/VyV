# ✨ ANIMATION SYSTEM
# Purpose: Smooth animations and visual effects
# Layer: Infrastructure/Effects

extends RefCounted

class_name AnimationSystem

# Animation types
enum AnimationType {
	MOVE,
	SCALE,
	FADE,
	ROTATE,
	BOUNCE,
	SHAKE
}

# Easing functions
enum EaseType {
	LINEAR,
	EASE_IN,
	EASE_OUT,
	EASE_IN_OUT,
	BOUNCE,
	ELASTIC
}

# Animation data structure
class Animation:
	var id: String
	var type: AnimationType
	var target_object
	var start_value
	var end_value
	var duration: float
	var elapsed_time: float = 0.0
	var ease_type: EaseType = EaseType.EASE_OUT
	var delay: float = 0.0
	var loop: bool = false
	var reverse: bool = false
	var callback: Callable
	var is_active: bool = true
	
	func _init(anim_id: String, anim_type: AnimationType, target, start_val, end_val, dur: float):
		id = anim_id
		type = anim_type
		target_object = target
		start_value = start_val
		end_value = end_val
		duration = dur

# Animation manager state
var active_animations: Dictionary = {}
var animation_id_counter: int = 0
var global_speed_multiplier: float = 1.0

# Create and start animation
func animate(type: AnimationType, target, start_value, end_value, duration: float, ease: EaseType = EaseType.EASE_OUT) -> String:
	var anim_id = "anim_%d" % animation_id_counter
	animation_id_counter += 1
	
	var animation = Animation.new(anim_id, type, target, start_value, end_value, duration)
	animation.ease_type = ease
	
	active_animations[anim_id] = animation
	return anim_id

# Animate unit movement
func animate_unit_move(unit, start_pos: Vector2, end_pos: Vector2, duration: float = 0.5) -> String:
	return animate(AnimationType.MOVE, unit, start_pos, end_pos, duration, EaseType.EASE_OUT)

# Animate unit selection
func animate_unit_selection(unit, duration: float = 0.3) -> String:
	var start_scale = Vector2(1.0, 1.0)
	var end_scale = Vector2(1.2, 1.2)
	return animate(AnimationType.SCALE, unit, start_scale, end_scale, duration, EaseType.BOUNCE)

# Animate fade effect
func animate_fade(target, start_alpha: float, end_alpha: float, duration: float = 0.5) -> String:
	return animate(AnimationType.FADE, target, start_alpha, end_alpha, duration, EaseType.EASE_IN_OUT)

# Animate screen shake
func animate_screen_shake(intensity: float = 10.0, duration: float = 0.3) -> String:
	var shake_offset = Vector2.ZERO
	return animate(AnimationType.SHAKE, null, Vector2.ZERO, Vector2(intensity, intensity), duration, EaseType.LINEAR)

# Set animation properties
func set_animation_delay(anim_id: String, delay: float) -> void:
	if anim_id in active_animations:
		active_animations[anim_id].delay = delay

func set_animation_loop(anim_id: String, loop: bool) -> void:
	if anim_id in active_animations:
		active_animations[anim_id].loop = loop

func set_animation_callback(anim_id: String, callback: Callable) -> void:
	if anim_id in active_animations:
		active_animations[anim_id].callback = callback

# Stop animation
func stop_animation(anim_id: String) -> void:
	if anim_id in active_animations:
		active_animations.erase(anim_id)

# Stop all animations
func stop_all_animations() -> void:
	active_animations.clear()

# Update animations (call from _process)
func update_animations(delta: float) -> void:
	var completed_animations = []
	
	for anim_id in active_animations:
		var animation = active_animations[anim_id]
		
		if not animation.is_active:
			continue
		
		# Handle delay
		if animation.delay > 0:
			animation.delay -= delta
			continue
		
		# Update elapsed time
		animation.elapsed_time += delta * global_speed_multiplier
		
		# Calculate progress
		var progress = animation.elapsed_time / animation.duration
		
		if progress >= 1.0:
			progress = 1.0
			completed_animations.append(anim_id)
		
		# Apply easing
		var eased_progress = _apply_easing(progress, animation.ease_type)
		
		# Update animation
		_update_animation_value(animation, eased_progress)
	
	# Handle completed animations
	for anim_id in completed_animations:
		var animation = active_animations[anim_id]
		
		# Call completion callback
		if animation.callback.is_valid():
			animation.callback.call()
		
		# Handle looping
		if animation.loop:
			animation.elapsed_time = 0.0
			if animation.reverse:
				var temp = animation.start_value
				animation.start_value = animation.end_value
				animation.end_value = temp
		else:
			active_animations.erase(anim_id)

# Update specific animation value
func _update_animation_value(animation: Animation, progress: float) -> void:
	match animation.type:
		AnimationType.MOVE:
			var current_pos = animation.start_value.lerp(animation.end_value, progress)
			if animation.target_object and "position" in animation.target_object:
				animation.target_object.position = current_pos
		
		AnimationType.SCALE:
			var current_scale = animation.start_value.lerp(animation.end_value, progress)
			if animation.target_object and "scale" in animation.target_object:
				animation.target_object.scale = current_scale
		
		AnimationType.FADE:
			var current_alpha = lerp(animation.start_value, animation.end_value, progress)
			if animation.target_object and "modulate" in animation.target_object:
				animation.target_object.modulate.a = current_alpha
		
		AnimationType.ROTATE:
			var current_rotation = lerp(animation.start_value, animation.end_value, progress)
			if animation.target_object and "rotation" in animation.target_object:
				animation.target_object.rotation = current_rotation
		
		AnimationType.BOUNCE:
			var bounce_factor = sin(progress * PI * 4) * (1.0 - progress)
			var current_pos = animation.start_value.lerp(animation.end_value, progress)
			current_pos.y -= bounce_factor * 20.0  # Bounce height
			if animation.target_object and "position" in animation.target_object:
				animation.target_object.position = current_pos
		
		AnimationType.SHAKE:
			var shake_intensity = animation.end_value * (1.0 - progress)
			var shake_offset = Vector2(
				randf_range(-shake_intensity.x, shake_intensity.x),
				randf_range(-shake_intensity.y, shake_intensity.y)
			)
			# Shake would be applied to camera or screen offset

# Apply easing function
func _apply_easing(t: float, ease_type: EaseType) -> float:
	match ease_type:
		EaseType.LINEAR:
			return t
		
		EaseType.EASE_IN:
			return t * t
		
		EaseType.EASE_OUT:
			return 1.0 - (1.0 - t) * (1.0 - t)
		
		EaseType.EASE_IN_OUT:
			if t < 0.5:
				return 2.0 * t * t
			else:
				return 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0
		
		EaseType.BOUNCE:
			if t < 1.0 / 2.75:
				return 7.5625 * t * t
			elif t < 2.0 / 2.75:
				t -= 1.5 / 2.75
				return 7.5625 * t * t + 0.75
			elif t < 2.5 / 2.75:
				t -= 2.25 / 2.75
				return 7.5625 * t * t + 0.9375
			else:
				t -= 2.625 / 2.75
				return 7.5625 * t * t + 0.984375
		
		EaseType.ELASTIC:
			if t == 0.0 or t == 1.0:
				return t
			var p = 0.3
			var s = p / 4.0
			return pow(2.0, -10.0 * t) * sin((t - s) * (2.0 * PI) / p) + 1.0
		
		_:
			return t

# Create animation sequence
func create_sequence() -> AnimationSequence:
	return AnimationSequence.new(self)

# Animation sequence for chaining animations
class AnimationSequence:
	var animation_system: AnimationSystem
	var sequence_steps: Array = []
	var current_step: int = 0
	var is_playing: bool = false
	
	func _init(anim_sys: AnimationSystem):
		animation_system = anim_sys
	
	func add_animation(type: AnimationType, target, start_value, end_value, duration: float, ease: EaseType = EaseType.EASE_OUT) -> AnimationSequence:
		sequence_steps.append({
			"type": type,
			"target": target,
			"start_value": start_value,
			"end_value": end_value,
			"duration": duration,
			"ease": ease
		})
		return self
	
	func add_delay(duration: float) -> AnimationSequence:
		sequence_steps.append({
			"type": "delay",
			"duration": duration
		})
		return self
	
	func play() -> void:
		if sequence_steps.size() > 0:
			is_playing = true
			current_step = 0
			_play_next_step()
	
	func _play_next_step() -> void:
		if current_step >= sequence_steps.size():
			is_playing = false
			return
		
		var step = sequence_steps[current_step]
		current_step += 1
		
		if step.type == "delay":
			# Handle delay
			animation_system.get_tree().create_timer(step.duration).timeout.connect(_play_next_step)
		else:
			# Play animation
			var anim_id = animation_system.animate(step.type, step.target, step.start_value, step.end_value, step.duration, step.ease)
			animation_system.set_animation_callback(anim_id, _play_next_step)

# Get animation statistics
func get_animation_stats() -> Dictionary:
	return {
		"active_animations": active_animations.size(),
		"total_created": animation_id_counter,
		"global_speed": global_speed_multiplier
	}