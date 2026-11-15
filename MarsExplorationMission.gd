extends Node3D

class RadarWidget extends Control:
	var blips: Array[Vector2] = []

	func set_blips(new_blips: Array[Vector2]) -> void:
		blips = new_blips
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var radius: float = minf(size.x, size.y) * 0.44
		var cyan := Color(0.15, 0.85, 1.0, 0.8)

		draw_circle(center, radius, Color(0.02, 0.08, 0.12, 0.88))
		draw_arc(center, radius, 0.0, TAU, 64, cyan, 2.0)
		draw_arc(center, radius * 0.66, 0.0, TAU, 64, Color(0.15, 0.65, 0.78, 0.45), 1.0)
		draw_arc(center, radius * 0.33, 0.0, TAU, 64, Color(0.15, 0.65, 0.78, 0.35), 1.0)
		draw_line(Vector2(center.x - radius, center.y), Vector2(center.x + radius, center.y), Color(0.15, 0.65, 0.78, 0.35), 1.0)
		draw_line(Vector2(center.x, center.y - radius), Vector2(center.x, center.y + radius), Color(0.15, 0.65, 0.78, 0.35), 1.0)
		var orbit_path := PackedVector2Array()
		for i in range(65):
			var angle := TAU * float(i) / 64.0
			orbit_path.append(center + Vector2(cos(angle) * radius * 0.74, -sin(angle) * radius * 0.74))
		draw_polyline(orbit_path, Color(1.0, 0.68, 0.32, 0.72), 1.5, true)

		for blip in blips:
			var point: Vector2 = center + Vector2(blip.x, -blip.y) * radius
			draw_circle(point, 4.0, Color(0.1, 1.0, 0.95, 0.95))
			draw_circle(point, 7.0, Color(0.1, 1.0, 0.95, 0.25))

		draw_circle(center, 5.0, Color(1.0, 1.0, 1.0, 0.95))
		draw_circle(center, 9.0, Color(0.2, 0.8, 1.0, 0.3))


class MissionStory extends Node:
	## A short, self-contained campaign layer for the Mars exploration scene.

	const PANEL := Color(0.025, 0.045, 0.058, 0.97)
	const CYAN := Color(0.35, 0.88, 0.91)
	const WHITE := Color(0.89, 0.94, 0.95)
	const MUTED := Color(0.59, 0.71, 0.75)

	var game: Node3D
	var overlay: ColorRect
	var panel: PanelContainer
	var body_text: RichTextLabel
	var status_text: Label
	var objective_choice: OptionButton
	var wavelength_choice: OptionButton
	var instrument_choice: OptionButton
	var optics_choice: OptionButton
	var approve_button: Button
	var open := true
	var design_approved := false
	var samples_returned := 0
	var last_story := ""


	func setup(game_root: Node3D) -> void:
		game = game_root
		_build_interface()
		present_briefing()


	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_J:
			_set_open(not open)


	func _build_interface() -> void:
		var canvas := CanvasLayer.new()
		canvas.layer = 20
		add_child(canvas)
		overlay = ColorRect.new()
		overlay.color = Color(0.008, 0.018, 0.025, 0.72)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		canvas.add_child(overlay)
		panel = PanelContainer.new()
		panel.set_anchors_preset(Control.PRESET_CENTER)
		panel.position = Vector2(-350.0, -300.0)
		panel.size = Vector2(700.0, 600.0)
		panel.custom_minimum_size = Vector2(700.0, 600.0)
		var style := StyleBoxFlat.new()
		style.bg_color = PANEL
		style.border_color = Color(0.19, 0.58, 0.65, 0.9)
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		style.content_margin_left = 24.0
		style.content_margin_right = 24.0
		style.content_margin_top = 20.0
		style.content_margin_bottom = 20.0
		panel.add_theme_stylebox_override("panel", style)
		canvas.add_child(panel)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 10)
		panel.add_child(column)
		var eyebrow := Label.new()
		eyebrow.text = "AEOLIS EXPEDITION     /     MISSION BRIEF 01"
		eyebrow.add_theme_color_override("font_color", CYAN)
		eyebrow.add_theme_font_size_override("font_size", 12)
		column.add_child(eyebrow)
		var title := Label.new()
		title.text = "The signal beneath the dust"
		title.add_theme_color_override("font_color", WHITE)
		title.add_theme_font_size_override("font_size", 27)
		column.add_child(title)
		body_text = RichTextLabel.new()
		body_text.bbcode_enabled = true
		body_text.fit_content = true
		body_text.scroll_active = false
		body_text.custom_minimum_size.y = 118.0
		body_text.add_theme_color_override("default_color", MUTED)
		body_text.add_theme_font_size_override("normal_font_size", 14)
		column.add_child(body_text)
		var separator := HSeparator.new()
		column.add_child(separator)
		var design_title := Label.new()
		design_title.text = "MISSION DESIGN LAB  /  CML 2 TRADE STUDY"
		design_title.add_theme_color_override("font_color", CYAN)
		design_title.add_theme_font_size_override("font_size", 12)
		column.add_child(design_title)
		objective_choice = _add_option(column, "Science objective", ["Find signs of ancient water", "Map surface temperature", "Track dust-storm winds"])
		wavelength_choice = _add_option(column, "Wavelength", ["Visible light", "Infrared", "Ultraviolet"])
		instrument_choice = _add_option(column, "Instrument", ["Panoramic camera", "Imaging spectrometer", "Weather station"])
		optics_choice = _add_option(column, "Optical system", ["Reflecting telescope", "Refracting telescope", "Wide-angle camera"])
		status_text = Label.new()
		status_text.text = "Choose a design, then check that the science goal and hardware agree."
		status_text.add_theme_color_override("font_color", MUTED)
		status_text.add_theme_font_size_override("font_size", 12)
		status_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(status_text)
		approve_button = Button.new()
		approve_button.text = "VERIFY DESIGN  /  BEGIN SURFACE OPERATIONS"
		approve_button.custom_minimum_size.y = 42.0
		approve_button.pressed.connect(_approve_design)
		column.add_child(approve_button)
		var hint := Label.new()
		hint.text = "J  JOURNAL     •     F  COLLECT SAMPLE     •     C  UPLINK AT LANDER"
		hint.add_theme_color_override("font_color", MUTED)
		hint.add_theme_font_size_override("font_size", 10)
		column.add_child(hint)


	func _add_option(parent: VBoxContainer, caption: String, options: Array) -> OptionButton:
		var row := HBoxContainer.new()
		parent.add_child(row)
		var label := Label.new()
		label.text = caption
		label.custom_minimum_size.x = 155.0
		label.add_theme_color_override("font_color", WHITE)
		row.add_child(label)
		var choice := OptionButton.new()
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for option in options:
			choice.add_item(option)
		row.add_child(choice)
		return choice


	func present_briefing() -> void:
		last_story = "[b]MISSION NEED[/b]  An orbiter has found a faint mineral signature in Gale Crater. If water once altered these rocks, the layers may hold clues to whether Mars could have supported life.\n\nYou are the surface geologist on [b]Aeolis[/b]. Before landing, the Mission Design Lab compared science goals, wavelength bands, instruments and optical systems. Your choices now shape what the expedition can confidently claim."
		body_text.text = last_story
		_set_open(true)


	func _approve_design() -> void:
		if objective_choice.selected != 0 or wavelength_choice.selected != 1 or instrument_choice.selected != 1 or optics_choice.selected != 0:
			status_text.text = "TRADE STUDY INCOMPLETE: ancient water minerals need infrared spectra, an imaging spectrometer and a reflecting telescope. Adjust the point design and verify again."
			status_text.add_theme_color_override("font_color", Color(1.0, 0.68, 0.36))
			return
		design_approved = true
		status_text.text = "CML 3 POINT DESIGN VERIFIED. Launch, relay, surface and science-user segments are ready."
		status_text.add_theme_color_override("font_color", CYAN)
		approve_button.text = "DESIGN VERIFIED  /  CLOSE JOURNAL"
		approve_button.pressed.disconnect(_approve_design)
		approve_button.pressed.connect(_close_after_approval)
		body_text.text = "[b]CML 1 — NEED[/b]  Find evidence of ancient water.   [b]CML 2 — FEASIBILITY[/b]  Compare wavelength and instrument trades.\n[b]CML 3 — POINT DESIGN[/b]  Infrared spectrometer behind a reflecting telescope.   [b]CML 4 — VERIFY[/b]  Test the interpretation against three field samples.\n\nThe launch vehicle delivered the Aeolis lander and a small relay orbiter. The orbiter's infrared map is your guide. Walk to each marked outcrop, collect a sample, then return to the lander to send results to the science team on Earth."


	func _close_after_approval() -> void:
		_set_open(false)


	func on_sample_collected(sample_index: int, sample_name: String) -> void:
		samples_returned += 1
		var beats := [
			"The basalt is older than the surrounding plain. Its chemistry gives the team a baseline for the crater floor.",
			"Clay-bearing rock confirms the orbital clue: liquid water once changed this terrain. The instrument's infrared bands separate hydrated minerals from ordinary dust.",
			"The dune sample records a younger, wind-shaped Mars. Together, the three samples tell a story of water, rock and a planet that kept changing."
		]
		var beat_index := mini(sample_index, beats.size() - 1)
		last_story = "[b]FIELD LOG  /  %s[/b]\n%s\n\nSamples aboard: %d of 3. Return to the lander to uplink the science packet." % [sample_name.to_upper(), beats[beat_index], samples_returned]
		if open:
			body_text.text = last_story
			status_text.text = "CML 4 VERIFICATION  /  %d OF 3 FIELD RESULTS" % samples_returned


	func on_uplink_received(count: int) -> void:
		if count < 3:
			last_story = "[b]DOWNLINK RECEIVED[/b]\nThe science team has the first results. They ask you to keep exploring: the full picture needs all three field sites."
		else:
			last_story = "[b]MISSION COMPLETE  /  AEOLIS EXPEDITION[/b]\nThe Earth team confirms hydrated clay beneath the basalt and a younger dune layer above it. Mars had persistent water in its past, then slowly became the cold desert you crossed.\n\nYour field evidence closes the loop from mission design to launch, orbital mapping, surface operations and science analysis. The next mission can now ask a better question."
		if open:
			body_text.text = last_story
			status_text.text = "USER SEGMENT  /  SCIENCE PACKET DELIVERED"
			status_text.add_theme_color_override("font_color", CYAN)


	func _set_open(value: bool) -> void:
		open = value
		if is_instance_valid(panel):
			panel.visible = value
			overlay.visible = value
		if value:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif is_instance_valid(game) and bool(game.get("game_started")):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ------------------------------------------------------------------ world
## Playable map footprint: 1,200 m x 1,200 m = 1,440,000 m².
const WORLD_WIDTH := 1200.0
const WORLD_DEPTH := 1200.0
const TERRAIN_RESOLUTION_X := 600
const TERRAIN_RESOLUTION_Z := 600
const WRAP_SEAM_BLEND_WIDTH := 72.0
const MARS_HEIGHT_RESOLUTION_X := 400
const MARS_HEIGHT_RESOLUTION_Z := 250
const MARS_HEIGHT_BLEND_MARGIN := 40.0
const WORLD_EDGE_MARGIN := 1.5
const SPAWN_POSITION := Vector3(-150.0, 5.0, 0.0)
const DUNE_PATCH_ORIGIN := Vector2(-100.0, -50.0)
const DUNE_PATCH_WIDTH := 200.0
const DUNE_PATCH_DEPTH := 100.0
const DUNE_HEIGHT_SAMPLE_SPACING := 1.0

# ------------------------------------------------------------------ graphics
# 0 = performance, 1 = balanced, 2 = high.
const GRAPHICS_QUALITY := 1
const USE_CUSTOM_TERRAIN_SHADER := true
const TERRAIN_BRIGHTNESS := 1.2
const PHYSICS_TICKS_PER_SECOND := 120
const UI_UPDATE_INTERVAL := 1.0 / 30.0
const HUD_PRIMARY := Color(0.86, 0.91, 0.93)
const HUD_SECONDARY := Color(0.55, 0.65, 0.7)
const HUD_CYAN := Color(0.28, 0.72, 0.78)
const HUD_AMBER := Color(0.88, 0.59, 0.27)
const HUD_GREEN := Color(0.37, 0.72, 0.54)
const HUD_PANEL := Color(0.025, 0.039, 0.049, 0.91)
const HUD_LINE := Color(0.2, 0.31, 0.35, 0.82)
const MARS_STORM_START_LOCAL_HOUR := 12.0
const MARS_STORM_BUILD_SECONDS := 35.0
const MARS_STORM_PEAK_SECONDS := 65.0
const MARS_STORM_DECAY_SECONDS := 35.0
## One playable sol is compressed to 24 real minutes.
const SIMULATED_SOL_DURATION := 1440.0

# ------------------------------------------------------------------ movement
## Movement constants are metres per second: 5 km/h walk and 19.8 km/h sprint.
const WALK_SPEED := 1.39
const SPRINT_SPEED := 5.5
const JUMP_FORCE := 3.4
const GRAVITY := 3.71
const JETPACK_THRUST := 5.2
const JETPACK_DURATION := 5.0
const JETPACK_RECHARGE_TIME := 15.0
const MOUSE_SENSITIVITY := 0.003
const ACCELERATION := 4.0
const BRAKING := 5.5
const AIR_CONTROL := 0.35
const AIR_DRAG := 0.25
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.12

const FLOOR_MAX_ANGLE_DEG := 55.0
const UPHILL_MIN_SPEED_FACTOR := 0.6

const WALK_ANIM_RATE := 2.0 * (WALK_SPEED / 3.2)
const RUN_ANIM_RATE := 1.5 * (SPRINT_SPEED / 6.0)

# ------------------------------------------------------------------ climbing
const CLIMB_SPEED := 3.2
const CLIMB_STICK_SPEED := 2.0
const CLIMB_ENTRY_PUSH_DOT := 0.55
const CLIMB_ENTRY_TIME := 0.15
const CLIMB_LOST_GRACE := 0.25
const CLIMB_COOLDOWN := 0.25
const CLIMB_JUMP_AWAY := 4.5

# ------------------------------------------------------------------ character visuals
const MODEL_FOOT_OFFSET := 0.0
const MAX_FOOT_DROP := 0.45
const GROUND_TILT_AMOUNT := 0.15
## NASA Astronaut.glb coordinates are in inches; convert to metres.
const NASA_ASTRONAUT_SCALE := 0.0254
const NASA_ASTRONAUT_HALF_HEIGHT_M := 0.94

const TERRAIN_DIFFUSE := "res://assets/codex_upgrade/mars_regolith_albedo.jpg"
const TERRAIN_NORMAL := "res://assets/codex_upgrade/mars_regolith_normal.jpg"
const TERRAIN_ROUGHNESS := "res://assets/codex_upgrade/mars_regolith_roughness.jpg"
const MARS_MAP := "res://assets/codex_upgrade/mars_jpl.jpg"
const MARS_GALE_HEIGHT_MAP := "res://assets/codex_upgrade/mars_gale_10ha_height.bin"
const MARS_DUNE_HEIGHT_MAP := "res://assets/codex_upgrade/mars_bagnold_2ha_height.bin"
const MARS_DUNE_ALBEDO := "res://assets/codex_upgrade/mars_bagnold_2ha_albedo.png"
const ASTRONAUT_MODEL := "res://assets/codex_upgrade/NASA_Astronaut.glb"
const TON_618_MODEL := "res://assets/codex_upgrade/black-hole-ton618.glb"

const DEFAULT_KEY_BINDINGS := {
	"move_forward": KEY_W,
	"move_back": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"sprint": KEY_SHIFT,
	"jump": KEY_SPACE,
	"jetpack": KEY_E,
}

const TERRAIN_SHADER_CODE := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mars_macro_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dune_albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec2 dune_origin = vec2(-100.0, -50.0);
uniform vec2 dune_size = vec2(200.0, 100.0);
uniform vec4 tint : source_color = vec4(1.0);
uniform float tile_size = 5.0;
uniform float far_tile_scale = 0.125;
uniform float mars_macro_scale = 0.0025;
uniform float albedo_gain = 1.08;
uniform float normal_strength = 0.45;
uniform float blend_sharpness = 6.0;
uniform float storm_dust = 0.0;
uniform bool flip_green = false;
uniform vec3 cliff_tint : source_color = vec3(0.72, 0.62, 0.54);

varying vec3 w_pos;
varying vec3 w_normal;
varying float view_distance;

vec3 unpack_normal(vec4 tex) {
	vec3 n = tex.xyz * 2.0 - 1.0;
	if (flip_green) {
		n.y = -n.y;
	}
	n.xy *= normal_strength;
	return n;
}

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	view_distance = length((VIEW_MATRIX * MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz);
}

void fragment() {
	vec3 wn = normalize(w_normal);
	vec3 w = pow(abs(wn), vec3(blend_sharpness));
	w /= (w.x + w.y + w.z + 0.0001);

	float s_near = 1.0 / tile_size;
	float s_far = s_near * far_tile_scale;

	vec2 uv_x = w_pos.zy * s_near;
	vec2 uv_y = w_pos.xz * s_near;
	vec2 uv_z = w_pos.xy * s_near;
	vec2 uv_y_far = w_pos.xz * s_far + vec2(0.37, 0.61);

	vec3 col_x = texture(albedo_tex, uv_x).rgb;
	vec3 col_z = texture(albedo_tex, uv_z).rgb;
	vec3 col_y = mix(texture(albedo_tex, uv_y).rgb, texture(albedo_tex, uv_y_far).rgb, 0.45);
	vec3 tex_col = col_x * w.x + col_y * w.y + col_z * w.z;
	vec3 mars_macro = texture(mars_macro_tex, w_pos.xz * mars_macro_scale + vec2(0.31, 0.17)).rgb;
	tex_col *= mix(vec3(1.0), mars_macro * 1.12, 0.22);
	float distance_fade = smoothstep(150.0, 420.0, view_distance);
	tex_col = mix(tex_col, mars_macro, distance_fade * 0.62);

	float cliff = 1.0 - smoothstep(0.55, 0.85, wn.y);
	float dune_mask = clamp(1.0 - COLOR.a, 0.0, 1.0);
	vec3 base = tex_col * COLOR.rgb * tint.rgb * albedo_gain;
	vec3 rock_albedo = mix(base, base * cliff_tint, cliff);
	// Procedural sand fields repeat every map width, so the wrapped map edges
	// keep the same wind ripples and patch coloring on both sides.
	vec2 map_uv = w_pos.xz / 1200.0;
	float sand_field = 0.5
		+ 0.22 * sin(TAU * (map_uv.x * 3.0 + map_uv.y * 2.0))
		+ 0.16 * sin(TAU * (map_uv.x * 5.0 - map_uv.y * 4.0))
		+ 0.10 * sin(TAU * (map_uv.x * 8.0 + map_uv.y * 7.0));
	float sand_coverage = smoothstep(0.31, 0.66, sand_field) * smoothstep(0.28, 0.88, wn.y);
	float ripple_phase = TAU * (map_uv.x * 360.0 + map_uv.y * 72.0
		+ 0.018 * sin(TAU * (map_uv.x * 8.0 + map_uv.y * 5.0)));
	float ripple_wave = sin(ripple_phase);
	float ripple_ridge = pow(max(0.0, 0.5 + 0.5 * ripple_wave), 12.0);
	float sand_grain = sin(TAU * (map_uv.x * 840.0 + map_uv.y * 610.0))
		* sin(TAU * (map_uv.x * 530.0 - map_uv.y * 770.0));
	float ripple_visibility = 1.0 - smoothstep(85.0, 300.0, view_distance);
	vec3 sand_color = vec3(0.72, 0.48, 0.33);
	sand_color *= 0.94 + 0.10 * ripple_wave * ripple_visibility
		+ 0.12 * ripple_ridge * ripple_visibility + 0.025 * sand_grain * ripple_visibility;
	vec3 sand_albedo = mix(rock_albedo, sand_color * tint.rgb * albedo_gain, 0.78);
	vec3 surface_albedo = mix(rock_albedo, sand_albedo, sand_coverage);
	surface_albedo = mix(surface_albedo, surface_albedo * vec3(1.07, 0.94, 0.82), storm_dust * 0.14);
	vec2 dune_uv = clamp((w_pos.xz - dune_origin) / dune_size, vec2(0.0), vec2(1.0));
	vec3 dune_albedo = texture(dune_albedo_tex, dune_uv).rgb;
	ALBEDO = mix(surface_albedo, dune_albedo, dune_mask);

	vec3 n_x = unpack_normal(texture(normal_tex, uv_x));
	vec3 n_z = unpack_normal(texture(normal_tex, uv_z));
	vec3 n_y = mix(unpack_normal(texture(normal_tex, uv_y)), unpack_normal(texture(normal_tex, uv_y_far)), 0.4);
	n_x = vec3(n_x.xy + wn.zy, abs(n_x.z) * wn.x);
	n_y = vec3(n_y.xy + wn.xz, abs(n_y.z) * wn.y);
	n_z = vec3(n_z.xy + wn.xy, abs(n_z.z) * wn.z);
	vec3 world_n = normalize(n_x.zyx * w.x + n_y.xzy * w.y + n_z.xyz * w.z);
	float distant_normal_fade = smoothstep(90.0, 260.0, view_distance) * 0.82;
	vec3 terrain_n = normalize(mix(world_n, wn, max(dune_mask * 0.85, distant_normal_fade)));
	vec2 ripple_direction = normalize(vec2(360.0, 72.0));
	vec2 ripple_slope = ripple_direction * cos(ripple_phase) * 0.075 * ripple_visibility;
	vec3 sand_normal = normalize(wn + vec3(ripple_slope.x, 0.10, ripple_slope.y));
	terrain_n = normalize(mix(terrain_n, sand_normal, sand_coverage * 0.42));
	NORMAL = normalize((VIEW_MATRIX * vec4(terrain_n, 0.0)).xyz);

	float base_roughness = clamp(texture(rough_tex, uv_y).r, 0.6, 1.0);
	ROUGHNESS = mix(mix(base_roughness, 0.97, sand_coverage * 0.55), 0.96, dune_mask);
	METALLIC = mix(0.04, 0.0, dune_mask);
	SPECULAR = 0.35;
}
"""

const MARS_DUST_FOG_SHADER_CODE := """
shader_type fog;

uniform float storm_intensity = 0.0;
uniform float daylight_factor = 1.0;

float dust_hash(vec3 cell) {
	cell.xz = mod(cell.xz, vec2(32.0));
	return fract(sin(dot(cell, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float dust_noise(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float x00 = mix(dust_hash(cell), dust_hash(cell + vec3(1.0, 0.0, 0.0)), f.x);
	float x10 = mix(dust_hash(cell + vec3(0.0, 1.0, 0.0)), dust_hash(cell + vec3(1.0, 1.0, 0.0)), f.x);
	float x01 = mix(dust_hash(cell + vec3(0.0, 0.0, 1.0)), dust_hash(cell + vec3(1.0, 0.0, 1.0)), f.x);
	float x11 = mix(dust_hash(cell + vec3(0.0, 1.0, 1.0)), dust_hash(cell + vec3(1.0, 1.0, 1.0)), f.x);
	return mix(mix(x00, x10, f.y), mix(x01, x11, f.y), f.z);
}

float dust_fbm(vec3 p) {
	float broad = dust_noise(p);
	float medium = dust_noise(p * 2.0 + vec3(4.3, 1.7, 8.1));
	float fine = dust_noise(p * 4.0 + vec3(9.2, 3.1, 2.4));
	return broad * 0.60 + medium * 0.28 + fine * 0.12;
}

void fog() {
	// 32 wrapped horizontal cells make the animated cloud field tile every 1.2 km.
	vec3 p = vec3(WORLD_POSITION.x / 1200.0 * 32.0, WORLD_POSITION.y * 0.024, WORLD_POSITION.z / 1200.0 * 32.0);
	p += vec3(-TIME * 0.20, TIME * 0.002, -TIME * 0.075);
	float field = dust_fbm(p);
	float billows = smoothstep(0.52, 0.70, field);
	float fine_detail = dust_fbm(p * 2.6 + vec3(2.0, 0.0, 5.0));
	float edge_fade = smoothstep(0.0, 85.0, -SDF);
	float height_fade = 1.0 - smoothstep(70.0, 155.0, max(WORLD_POSITION.y - OBJECT_POSITION.y, 0.0));
	vec3 night_dust = vec3(0.10, 0.11, 0.16);
	vec3 day_dust = mix(vec3(0.62, 0.37, 0.24), vec3(0.82, 0.59, 0.40), billows);
	ALBEDO = mix(night_dust, day_dust, daylight_factor);
	EMISSION = vec3(0.10, 0.038, 0.014) * storm_intensity * daylight_factor;
	DENSITY = storm_intensity * (0.0009 + 0.011 * billows * mix(0.82, 1.18, fine_detail)) * edge_fade * height_fade;
}
"""

# ------------------------------------------------------------------ state
var player: CharacterBody3D
var astronaut_model: Node3D
var astronaut_animation: AnimationPlayer
var skeleton: Skeleton3D
var camera_pivot: Node3D
var player_camera: Camera3D
var terrain_noise := FastNoiseLite.new()
var terrain_height_grid := PackedFloat32Array()
var mars_height_data := PackedFloat32Array()
var mars_dune_data := PackedFloat32Array()

var terrain_shader: Shader
var terrain_shader_material: ShaderMaterial
var tex_diffuse: Texture2D
var tex_normal: Texture2D
var tex_roughness: Texture2D
var tex_dune_albedo: Texture2D
var mars_environment: Environment
var martian_sun: DirectionalLight3D
var mars_sky_material: ProceduralSkyMaterial
var night_star_material: StandardMaterial3D
var storm_fog_volume: FogVolume
var storm_fog_material: ShaderMaterial
var storm_fog_supported := false
var environment_status_label: Label

# Weather is a clearly labeled gameplay approximation: dust affects visibility
# and sunlight, while Mars's thin air does not shove the astronaut like a storm on Earth.
var storm_intensity := 0.0
var storm_target_intensity := 0.0
var storm_drill_active := false
var storm_status := "CLEAR"
var storm_visibility_m := 1800.0
var storm_solar_availability := 100.0
var local_mars_hour := 5.0
var simulated_sol_number := 1
var solar_elevation := 0.0
var daylight_factor := 0.0
var simulated_solar_output := 0.0
var solar_phase_label := "DAWN"

var effect_time := 0.0
var ui_timer := 0.0

var starfield: MultiMeshInstance3D
var space_sky_root: Node3D
var accretion_disk_node: Node3D
var red_giant_material: StandardMaterial3D
var red_giant_glow: Sprite3D
var tidal_stream: MeshInstance3D
var galaxy_textures: Array[Texture2D] = []

var message_timer := 0.0
var jetpack_fuel := JETPACK_DURATION
var jetpack_recharge_timer := 0.0

var coyote_timer := 0.0
var jump_buffer_timer := 0.0

var climbing := false
var wall_normal := Vector3.ZERO
var wall_contact_time := 0.0
var climb_lost_timer := 0.0
var climb_cooldown := 0.0
var climb_move_amount := 0.0
var climb_hint_shown := false

var model_yaw := 0.0
var model_quat := Quaternion.IDENTITY
var ground_normal := Vector3.UP
var model_height_offset := 0.0
var rest_pose_applied := false
var anim_idle := ""
var anim_walk := ""
var anim_run := ""
var anim_climb := ""
var anim_air := ""

var title_label: Label
var jetpack_bar: ProgressBar
var jetpack_value: Label
var message_label: Label
var message_panel: PanelContainer

# Mission-control state.  All spacecraft/orbit telemetry below is deliberately
# simulated for gameplay; it is not a GMAT dynamics solution.
const SAMPLE_POSITIONS := [Vector2(-120.0, -42.0), Vector2(-28.0, 38.0), Vector2(96.0, -34.0)]
const SAMPLE_NAMES := ["Basalt Ridge", "Clay Bearing Outcrop", "Dune Margin" ]
const SAMPLE_RANGE := 4.0
var sample_collected: Array[bool] = [false, false, false]
var mission_elapsed := 0.0
var telemetry_clock := 0.0
var uplink_count := 0
var mission_panel: PanelContainer
var mission_status_label: Label
var telemetry_label: Label
var timeline_label: Label
var mission_progress_bar: ProgressBar
var communication_bar: ProgressBar
var orbital_widget: RadarWidget
var relay_distance := 0.0
var communication_quality := 100.0
var science_data_buffer := 0
var mission_canvas: CanvasLayer
var mission_story: Variant

var game_started := false


func _ready() -> void:
	randomize()
	Engine.physics_ticks_per_second = PHYSICS_TICKS_PER_SECOND
	setup_input_map()
	setup_noise()
	load_mars_height_map()
	create_environment()
	create_terrain()
	create_player()
	create_hud()
	create_mission_control()
	mission_story = MissionStory.new()
	add_child(mission_story)
	mission_story.setup(self)
	game_started = true


func setup_input_map() -> void:
	for action in DEFAULT_KEY_BINDINGS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var key_event := InputEventKey.new()
		key_event.physical_keycode = DEFAULT_KEY_BINDINGS[action]
		InputMap.action_add_event(action, key_event)


func setup_noise() -> void:
	terrain_noise.seed = randi()
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	terrain_noise.frequency = 0.035
	terrain_noise.fractal_octaves = 5
	terrain_noise.fractal_gain = 0.5
	terrain_noise.fractal_lacunarity = 2.1


func load_mars_height_map() -> void:
	var file := FileAccess.open(MARS_GALE_HEIGHT_MAP, FileAccess.READ)
	if file == null:
		push_warning("Gale Crater height data not found; using procedural fallback terrain.")
	else:
		var expected_samples := (MARS_HEIGHT_RESOLUTION_X + 1) * (MARS_HEIGHT_RESOLUTION_Z + 1)
		if file.get_length() == expected_samples * 4:
			mars_height_data.resize(expected_samples)
			for i in range(expected_samples):
				mars_height_data[i] = file.get_float()
		else:
			push_warning("Gale Crater height data has an unexpected size; using procedural fallback terrain.")

	var dune_file := FileAccess.open(MARS_DUNE_HEIGHT_MAP, FileAccess.READ)
	if dune_file == null:
		push_warning("Bagnold dune data not found; the 2 hectare sand patch will be omitted.")
		return

	var dune_samples := 201 * 101
	if dune_file.get_length() != dune_samples * 4:
		push_warning("Bagnold dune data has an unexpected size; the sand patch will be omitted.")
		return

	mars_dune_data.resize(dune_samples)
	for i in range(dune_samples):
		mars_dune_data[i] = dune_file.get_float()

	tex_dune_albedo = load(MARS_DUNE_ALBEDO) as Texture2D


func create_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()

	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.27, 0.20, 0.14)
	sky_material.sky_horizon_color = Color(0.75, 0.56, 0.40)
	sky_material.ground_bottom_color = Color(0.14, 0.105, 0.08)
	sky_material.ground_horizon_color = Color(0.50, 0.38, 0.28)
	sky_material.sky_curve = 0.22
	sky_material.sun_angle_max = 12.0
	sky_material.sun_curve = 0.08
	sky_material.energy_multiplier = 0.9
	sky_material.use_debanding = true
	mars_sky_material = sky_material

	sky.sky_material = sky_material
	env.background_mode = Environment.BG_SKY
	env.sky = sky

	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.54, 0.42)
	env.ambient_light_energy = 0.48
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 0.82

	env.fog_enabled = true
	env.fog_light_color = Color(0.58, 0.48, 0.38)
	env.fog_density = 0.00115
	env.fog_sky_affect = 0.25
	storm_fog_supported = RenderingServer.get_current_rendering_method() == "forward_plus"
	if storm_fog_supported:
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.0
		env.volumetric_fog_albedo = Color(0.68, 0.43, 0.29)
		env.volumetric_fog_emission = Color(0.08, 0.027, 0.009)
		env.volumetric_fog_emission_energy = 0.22
		env.volumetric_fog_anisotropy = 0.48
		env.volumetric_fog_length = 650.0
		env.volumetric_fog_detail_spread = 1.25
		env.volumetric_fog_sky_affect = 0.85

	var sun := DirectionalLight3D.new()
	sun.name = "MartianSun"
	sun.rotation_degrees = Vector3(-34.0, -28.0, 0.0)
	sun.light_color = Color(1.0, 0.88, 0.72)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 0.8
	sun.shadow_blur = 2.4
	martian_sun = sun

	var viewport := get_viewport()

	if GRAPHICS_QUALITY <= 0:
		env.glow_enabled = false
		env.ssao_enabled = false
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		sun.directional_shadow_max_distance = 80.0
		viewport.msaa_3d = Viewport.MSAA_DISABLED
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA

	elif GRAPHICS_QUALITY == 1:
		env.glow_enabled = true
		env.glow_intensity = 0.35
		env.glow_bloom = 0.015
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
		env.ssao_enabled = true
		env.ssao_radius = 1.1
		env.ssao_intensity = 0.8
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		sun.directional_shadow_max_distance = 110.0
		viewport.msaa_3d = Viewport.MSAA_2X
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA

	else:
		env.glow_enabled = true
		env.glow_intensity = 0.4
		env.glow_bloom = 0.02
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
		env.ssao_enabled = true
		env.ssao_radius = 1.2
		env.ssao_intensity = 1.0
		env.ssil_enabled = true
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		sun.directional_shadow_max_distance = 150.0
		viewport.msaa_3d = Viewport.MSAA_4X
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA

	world.environment = env
	mars_environment = env
	add_child(world)
	add_child(sun)


func get_terrain_height(x: float, z: float) -> float:
	if terrain_height_grid.size() == (TERRAIN_RESOLUTION_X + 1) * (TERRAIN_RESOLUTION_Z + 1):
		var step_x := WORLD_WIDTH / float(TERRAIN_RESOLUTION_X)
		var step_z := WORLD_DEPTH / float(TERRAIN_RESOLUTION_Z)
		var u := clampf((x + WORLD_WIDTH * 0.5) / step_x, 0.0, float(TERRAIN_RESOLUTION_X))
		var v := clampf((z + WORLD_DEPTH * 0.5) / step_z, 0.0, float(TERRAIN_RESOLUTION_Z))
		return sample_height_bilinear(terrain_height_grid, TERRAIN_RESOLUTION_X + 1, TERRAIN_RESOLUTION_Z + 1, u, v)
	return get_raw_terrain_height(x, z)


func get_raw_terrain_height(x: float, z: float) -> float:
	var terrain_height: float

	terrain_height = 0.0
	if mars_height_data.size() == (MARS_HEIGHT_RESOLUTION_X + 1) * (MARS_HEIGHT_RESOLUTION_Z + 1):
		var data_min_x := -200.0
		var data_max_x := 200.0
		var data_min_z := -125.0
		var data_max_z := 125.0
		if x >= data_min_x and x <= data_max_x and z >= data_min_z and z <= data_max_z:
			var u := x - data_min_x
			var v := z - data_min_z
			var source_height := sample_height_bilinear(mars_height_data, MARS_HEIGHT_RESOLUTION_X + 1, MARS_HEIGHT_RESOLUTION_Z + 1, u, v)
			var edge_distance := minf(minf(x - data_min_x, data_max_x - x), minf(z - data_min_z, data_max_z - z))
			if edge_distance >= MARS_HEIGHT_BLEND_MARGIN:
				terrain_height = source_height
			else:
				var data_weight := smoothstep(0.0, MARS_HEIGHT_BLEND_MARGIN, edge_distance)
				terrain_height = lerpf(get_procedural_surface_height(x, z), source_height, data_weight)
		else:
			terrain_height = get_procedural_surface_height(x, z)
	else:
		terrain_height = get_procedural_surface_height(x, z)

	if mars_dune_data.size() == 201 * 101:
		var local_x := x - DUNE_PATCH_ORIGIN.x
		var local_z := z - DUNE_PATCH_ORIGIN.y

		if local_x >= 0.0 and local_x <= DUNE_PATCH_WIDTH and local_z >= 0.0 and local_z <= DUNE_PATCH_DEPTH:
			var dune_u := local_x / DUNE_HEIGHT_SAMPLE_SPACING
			var dune_v := local_z / DUNE_HEIGHT_SAMPLE_SPACING
			var dune_relief := sample_height_bilinear(mars_dune_data, 201, 101, dune_u, dune_v)
			var edge_distance := minf(
				minf(local_x, DUNE_PATCH_WIDTH - local_x),
				minf(local_z, DUNE_PATCH_DEPTH - local_z)
			)
			var edge_blend := clampf(edge_distance / 8.0, 0.0, 1.0)
			edge_blend = edge_blend * edge_blend * (3.0 - 2.0 * edge_blend)
			terrain_height += dune_relief * edge_blend

	return terrain_height


func get_procedural_surface_height(x: float, z: float) -> float:
	# Keep open plains relatively broad and calm; larger geological forms supply
	# the dramatic relief instead of making every part of the world hilly.
	var broad := terrain_noise.get_noise_2d(x * 0.55, z * 0.55) * 4.5
	var detail := terrain_noise.get_noise_2d(x * 2.8, z * 2.8) * 1.1
	var ridges := absf(terrain_noise.get_noise_2d(x * 0.55 + 100.0, z * 0.55)) * 1.2
	var wind_erosion := terrain_noise.get_noise_2d(x * 0.9 + 320.0, z * 0.9) * 0.24
	var height := broad + detail + ridges + wind_erosion - 0.7
	# Eroded mesas and a high shield mountain create stepped, non-uniform skyline.
	height += get_eroded_mesa_height(x, z, Vector2(145.0, 155.0), 26.0, 68.0, 28.0)
	height += get_eroded_mesa_height(x, z, Vector2(-285.0, -205.0), 38.0, 96.0, 34.0)
	height += get_eroded_mesa_height(x, z, Vector2(385.0, -245.0), 22.0, 62.0, 20.0)
	height += get_shield_mountain_height(x, z, Vector2(40.0, 330.0), 92.0, 230.0)
	# A long Valles-style chasm and a narrower secondary fissure cut across plains.
	var main_canyon_center := 265.0 + z * 0.18 + sin(z * 0.006) * 45.0
	var main_canyon_offset := absf(x - main_canyon_center)
	var main_canyon_width := 56.0 + terrain_noise.get_noise_2d(x * 0.012, z * 0.012) * 8.0
	var main_floor := 1.0 - smoothstep(main_canyon_width * 0.42, main_canyon_width, main_canyon_offset)
	var main_rim := exp(-pow((main_canyon_offset - main_canyon_width - 11.0) / 13.0, 2.0))
	height += -68.0 * main_floor + 10.0 * main_rim
	var fissure_center := -445.0 + z * 0.10 + sin(z * 0.011) * 24.0
	var fissure_offset := absf(x - fissure_center)
	var fissure_floor := 1.0 - smoothstep(14.0, 34.0, fissure_offset)
	height -= 32.0 * fissure_floor
	# Large impact basins have deep floors, steep inner walls, and raised rims.
	height += get_large_impact_basin(x, z, Vector2(-395.0, 280.0), 142.0, 62.0)
	height += get_large_impact_basin(x, z, Vector2(430.0, -300.0), 176.0, 78.0)
	height += get_procedural_crater_relief(x, z)
	return height


func get_eroded_mesa_height(x: float, z: float, center: Vector2, plateau_radius: float, foot_radius: float, mesa_height: float) -> float:
	var distance := Vector2(x - center.x, z - center.y).length()
	if distance >= foot_radius:
		return 0.0
	var shoulder := 1.0 - smoothstep(plateau_radius, foot_radius, distance)
	var crown := 1.0 - smoothstep(plateau_radius * 0.82, plateau_radius * 1.12, distance)
	var strata := sin(distance * 0.42 + terrain_noise.get_noise_2d(x * 0.025, z * 0.025) * 2.0) * 0.7
	return maxf(shoulder * mesa_height + crown * 2.5 + strata * shoulder, 0.0)


func get_shield_mountain_height(x: float, z: float, center: Vector2, peak_height: float, foot_radius: float) -> float:
	var distance := Vector2(x - center.x, z - center.y).length()
	if distance >= foot_radius:
		return 0.0
	var broad_slope := 1.0 - smoothstep(0.0, foot_radius, distance)
	var summit := 1.0 - smoothstep(18.0, 78.0, distance)
	var flank_ridges := sin(distance * 0.075 + terrain_noise.get_noise_2d(x * 0.02, z * 0.02) * 2.0) * 2.0 * broad_slope
	return peak_height * broad_slope * 0.72 + peak_height * 0.28 * summit + flank_ridges


func get_large_impact_basin(x: float, z: float, center: Vector2, radius: float, depth: float) -> float:
	var distance := Vector2(x - center.x, z - center.y).length()
	if distance > radius * 1.2:
		return 0.0
	var bowl := 1.0 - smoothstep(radius * 0.38, radius * 1.08, distance)
	var rim := exp(-pow((distance - radius) / (radius * 0.075), 2.0))
	var broken_rim := terrain_noise.get_noise_2d(x * 0.07, z * 0.07) * 4.0 * rim
	return -depth * bowl + 18.0 * rim + broken_rim


func get_procedural_crater_relief(x: float, z: float) -> float:
	var crater_centres := [
		Vector3(72.0, 0.0, -58.0), Vector3(-38.0, 0.0, 76.0),
		Vector3(145.0, 0.0, 55.0), Vector3(-118.0, 0.0, -78.0),
		Vector3(-430.0, 0.0, 305.0), Vector3(430.0, 0.0, 380.0),
		Vector3(-390.0, 0.0, -410.0), Vector3(350.0, 0.0, -430.0)
	]

	var crater_radii := [22.0, 15.0, 29.0, 12.0, 54.0, 42.0, 48.0, 36.0]
	var total := 0.0

	for i in range(crater_centres.size()):
		var distance := Vector2(x - crater_centres[i].x, z - crater_centres[i].z).length()
		var radius: float = crater_radii[i]
		if distance > radius * 1.8:
			continue
		var bowl := -2.2 * exp(-pow(distance / (radius * 0.72), 2.0) * 1.7)
		var rim := 0.75 * exp(-pow((distance - radius) / (radius * 0.13), 2.0))
		total += bowl + rim

	return total


func sample_height_bilinear(data: PackedFloat32Array, grid_width: int, grid_depth: int, u: float, v: float) -> float:
	var x0 := clampi(floori(u), 0, grid_width - 1)
	var z0 := clampi(floori(v), 0, grid_depth - 1)
	var x1 := mini(x0 + 1, grid_width - 1)
	var z1 := mini(z0 + 1, grid_depth - 1)
	var fx := clampf(u - float(x0), 0.0, 1.0)
	var fz := clampf(v - float(z0), 0.0, 1.0)

	var top := lerpf(data[z0 * grid_width + x0], data[z0 * grid_width + x1], fx)
	var bottom := lerpf(data[z1 * grid_width + x0], data[z1 * grid_width + x1], fx)

	return lerpf(top, bottom, fz)


func make_terrain_edges_wrap_smooth(heights: PackedFloat32Array, grid_width: int, grid_depth: int, step_x: float, step_z: float) -> void:
	var x_band := mini(ceili(WRAP_SEAM_BLEND_WIDTH / step_x), (grid_width - 1) / 2)
	var z_band := mini(ceili(WRAP_SEAM_BLEND_WIDTH / step_z), (grid_depth - 1) / 2)
	var source := heights.duplicate()
	for zi in range(grid_depth):
		for offset in range(x_band + 1):
			var left_index := zi * grid_width + offset
			var right_index := zi * grid_width + (grid_width - 1 - offset)
			var pair_height := (source[left_index] + source[right_index]) * 0.5
			var distance_from_edge := float(offset) * step_x
			var blend := 1.0 - smoothstep(0.0, WRAP_SEAM_BLEND_WIDTH, distance_from_edge)
			heights[left_index] = lerpf(source[left_index], pair_height, blend)
			heights[right_index] = lerpf(source[right_index], pair_height, blend)
	source = heights.duplicate()
	for xi in range(grid_width):
		for offset in range(z_band + 1):
			var north_index := offset * grid_width + xi
			var south_index := (grid_depth - 1 - offset) * grid_width + xi
			var pair_height := (source[north_index] + source[south_index]) * 0.5
			var distance_from_edge := float(offset) * step_z
			var blend := 1.0 - smoothstep(0.0, WRAP_SEAM_BLEND_WIDTH, distance_from_edge)
			heights[north_index] = lerpf(source[north_index], pair_height, blend)
			heights[south_index] = lerpf(source[south_index], pair_height, blend)


func make_color_edges_wrap_smooth(colors: PackedColorArray, grid_width: int, grid_depth: int, step_x: float, step_z: float) -> void:
	var x_band := mini(ceili(WRAP_SEAM_BLEND_WIDTH / step_x), (grid_width - 1) / 2)
	var z_band := mini(ceili(WRAP_SEAM_BLEND_WIDTH / step_z), (grid_depth - 1) / 2)
	var source := colors.duplicate()
	for zi in range(grid_depth):
		for offset in range(x_band + 1):
			var left_index := zi * grid_width + offset
			var right_index := zi * grid_width + (grid_width - 1 - offset)
			var pair_color := (source[left_index] + source[right_index]) * 0.5
			var blend := 1.0 - smoothstep(0.0, WRAP_SEAM_BLEND_WIDTH, float(offset) * step_x)
			colors[left_index] = source[left_index].lerp(pair_color, blend)
			colors[right_index] = source[right_index].lerp(pair_color, blend)
	source = colors.duplicate()
	for xi in range(grid_width):
		for offset in range(z_band + 1):
			var north_index := offset * grid_width + xi
			var south_index := (grid_depth - 1 - offset) * grid_width + xi
			var pair_color := (source[north_index] + source[south_index]) * 0.5
			var blend := 1.0 - smoothstep(0.0, WRAP_SEAM_BLEND_WIDTH, float(offset) * step_z)
			colors[north_index] = source[north_index].lerp(pair_color, blend)
			colors[south_index] = source[south_index].lerp(pair_color, blend)


func get_terrain_color(x: float, z: float, height: float) -> Color:
	var color_noise := terrain_noise.get_noise_2d(x * 0.18 + 500.0, z * 0.18)
	var rock_noise := terrain_noise.get_noise_2d(x * 0.45, z * 0.45 + 300.0)
	var dune_noise := terrain_noise.get_noise_2d(x * 0.08 - 180.0, z * 0.08 + 240.0)
	var base_color: Color

	if height > 6.0:
		base_color = Color(0.76, 0.57, 0.42).lerp(
			Color(0.88, 0.69, 0.52),
			clampf((height - 6.0) / 12.0, 0.0, 0.7)
		)
	elif rock_noise > 0.34:
		base_color = Color(0.68, 0.57, 0.46)
	elif dune_noise > 0.12:
		base_color = Color(0.82, 0.65, 0.47).lerp(
			Color(0.92, 0.75, 0.55),
			clampf(dune_noise, 0.0, 1.0) * 0.4
		)
	elif color_noise > 0.32:
		base_color = Color(0.76, 0.56, 0.42)
	else:
		base_color = Color(0.72, 0.52, 0.39)

	var variation := color_noise * 0.022
	base_color = Color(
		clampf(base_color.r + variation, 0.0, 1.0),
		clampf(base_color.g + variation * 0.55, 0.0, 1.0),
		clampf(base_color.b + variation * 0.3, 0.0, 1.0),
		1.0
	)

	var local_x := x - DUNE_PATCH_ORIGIN.x
	var local_z := z - DUNE_PATCH_ORIGIN.y

	if local_x >= 0.0 and local_x <= DUNE_PATCH_WIDTH and local_z >= 0.0 and local_z <= DUNE_PATCH_DEPTH:
		var edge_distance := minf(
			minf(local_x, DUNE_PATCH_WIDTH - local_x),
			minf(local_z, DUNE_PATCH_DEPTH - local_z)
		)
		var dune_blend := clampf(edge_distance / 8.0, 0.0, 1.0)
		dune_blend = dune_blend * dune_blend * (3.0 - 2.0 * dune_blend)
		var sand_edge_tint := base_color.lerp(Color(0.64, 0.48, 0.35), dune_blend)
		return Color(sand_edge_tint.r, sand_edge_tint.g, sand_edge_tint.b, 1.0 - dune_blend)

	return base_color


func make_procedural_regolith_texture() -> Texture2D:
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)

	var broad_noise := FastNoiseLite.new()
	broad_noise.seed = 4107
	broad_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	broad_noise.frequency = 0.025
	broad_noise.fractal_octaves = 4

	var fine_noise := FastNoiseLite.new()
	fine_noise.seed = 9123
	fine_noise.frequency = 0.19
	fine_noise.fractal_octaves = 2

	var grain_noise := FastNoiseLite.new()
	grain_noise.seed = 2221
	grain_noise.frequency = 0.72

	for y in range(512):
		for x in range(512):
			var broad := broad_noise.get_noise_2d(float(x), float(y))
			var fine := fine_noise.get_noise_2d(float(x), float(y))
			var grain := grain_noise.get_noise_2d(float(x), float(y))
			var value := broad * 0.11 + fine * 0.045 + grain * 0.018
			var iron_stain := maxf(0.0, broad * 0.5 + fine * 0.25)
			var base := Color(0.56, 0.36, 0.25)

			var color := Color(
				clampf(base.r + value + iron_stain * 0.045, 0.0, 1.0),
				clampf(base.g + value * 0.62 + iron_stain * 0.018, 0.0, 1.0),
				clampf(base.b + value * 0.38, 0.0, 1.0),
				1.0
			)

			image.set_pixel(x, y, color)

	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


func make_procedural_normal_texture() -> Texture2D:
	# A generated normal map adds fine regolith relief when no texture pack exists.
	var image := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var normal_noise := FastNoiseLite.new()
	normal_noise.seed = 7319
	normal_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	normal_noise.frequency = 0.085
	normal_noise.fractal_octaves = 4
	for y in range(256):
		for x in range(256):
			var dx := normal_noise.get_noise_2d(float(x + 1), float(y)) - normal_noise.get_noise_2d(float(x - 1), float(y))
			var dy := normal_noise.get_noise_2d(float(x), float(y + 1)) - normal_noise.get_noise_2d(float(x), float(y - 1))
			var normal := Vector3(-dx * 2.6, -dy * 2.6, 1.0).normalized()
			image.set_pixel(x, y, Color(normal.x * 0.5 + 0.5, normal.y * 0.5 + 0.5, normal.z * 0.5 + 0.5, 1.0))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


func make_roughness_texture() -> Texture2D:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.94, 0.94, 0.94, 1.0))
	return ImageTexture.create_from_image(image)


func make_terrain_material(tint: Color = Color.WHITE) -> Material:
	if tex_diffuse == null:
		if ResourceLoader.exists(TERRAIN_DIFFUSE):
			tex_diffuse = load(TERRAIN_DIFFUSE) as Texture2D
		if tex_diffuse == null:
			tex_diffuse = make_procedural_regolith_texture()

	if tex_normal == null:
		if ResourceLoader.exists(TERRAIN_NORMAL):
			tex_normal = load(TERRAIN_NORMAL) as Texture2D
		if tex_normal == null:
			tex_normal = make_procedural_normal_texture()

	if tex_roughness == null:
		if ResourceLoader.exists(TERRAIN_ROUGHNESS):
			tex_roughness = load(TERRAIN_ROUGHNESS) as Texture2D
		if tex_roughness == null:
			tex_roughness = make_roughness_texture()

	if tex_dune_albedo == null:
		if ResourceLoader.exists(MARS_DUNE_ALBEDO):
			tex_dune_albedo = load(MARS_DUNE_ALBEDO) as Texture2D
		if tex_dune_albedo == null:
			tex_dune_albedo = tex_diffuse

	if USE_CUSTOM_TERRAIN_SHADER:
		if terrain_shader == null:
			terrain_shader = Shader.new()
			terrain_shader.code = TERRAIN_SHADER_CODE

		var shader_material := ShaderMaterial.new()
		shader_material.shader = terrain_shader
		shader_material.set_shader_parameter("albedo_tex", tex_diffuse)
		shader_material.set_shader_parameter("normal_tex", tex_normal)
		shader_material.set_shader_parameter("rough_tex", tex_roughness)

		var macro_texture: Texture2D = null
		if ResourceLoader.exists(MARS_MAP):
			macro_texture = load(MARS_MAP) as Texture2D
		if macro_texture == null:
			macro_texture = tex_diffuse

		shader_material.set_shader_parameter("mars_macro_tex", macro_texture)
		shader_material.set_shader_parameter("dune_albedo_tex", tex_dune_albedo)
		shader_material.set_shader_parameter("dune_origin", DUNE_PATCH_ORIGIN)
		shader_material.set_shader_parameter("dune_size", Vector2(DUNE_PATCH_WIDTH, DUNE_PATCH_DEPTH))
		shader_material.set_shader_parameter("tint", tint)
		shader_material.set_shader_parameter("albedo_gain", 1.08)
		terrain_shader_material = shader_material

		return shader_material

	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.albedo_color = tint
	material.albedo_texture = tex_diffuse
	material.normal_enabled = true
	material.normal_texture = tex_normal
	material.roughness_texture = tex_roughness
	material.roughness = 0.96
	material.metallic = 0.0
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE / 5.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

	return material


func create_terrain() -> void:
	var verts_x := TERRAIN_RESOLUTION_X + 1
	var verts_z := TERRAIN_RESOLUTION_Z + 1
	var step_x := WORLD_WIDTH / float(TERRAIN_RESOLUTION_X)
	var step_z := WORLD_DEPTH / float(TERRAIN_RESOLUTION_Z)
	var half_x := WORLD_WIDTH * 0.5
	var half_z := WORLD_DEPTH * 0.5

	var heights := PackedFloat32Array()
	heights.resize(verts_x * verts_z)

	for zi in range(verts_z):
		for xi in range(verts_x):
			heights[zi * verts_x + xi] = get_terrain_height(
				-half_x + xi * step_x,
				-half_z + zi * step_z
			)

	make_terrain_edges_wrap_smooth(heights, verts_x, verts_z, step_x, step_z)
	terrain_height_grid = heights
	var vertex_colors := PackedColorArray()
	vertex_colors.resize(heights.size())
	for zi in range(verts_z):
		var z := -half_z + zi * step_z
		for xi in range(verts_x):
			var x := -half_x + xi * step_x
			vertex_colors[zi * verts_x + xi] = get_terrain_color(x, z, heights[zi * verts_x + xi])
	make_color_edges_wrap_smooth(vertex_colors, verts_x, verts_z, step_x, step_z)

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	for zi in range(verts_z):
		var z := -half_z + zi * step_z

		for xi in range(verts_x):
			var x := -half_x + xi * step_x
			var h := heights[zi * verts_x + xi]

			surface.set_color(vertex_colors[zi * verts_x + xi])
			surface.set_uv(Vector2(x / 6.0, z / 6.0))
			surface.add_vertex(Vector3(x, h, z))

	for zi in range(TERRAIN_RESOLUTION_Z):
		for xi in range(TERRAIN_RESOLUTION_X):
			var i00 := zi * verts_x + xi
			var i10 := i00 + 1
			var i01 := i00 + verts_x
			var i11 := i01 + 1

			surface.add_index(i00)
			surface.add_index(i10)
			surface.add_index(i01)
			surface.add_index(i10)
			surface.add_index(i11)
			surface.add_index(i01)

	surface.generate_normals()
	var terrain_mesh := surface.commit()

	var terrain := StaticBody3D.new()
	terrain.name = "AlienTerrain"
	terrain.collision_layer = 1
	terrain.collision_mask = 0

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = terrain_mesh
	var terrain_material := make_terrain_material()
	mesh_instance.material_override = terrain_material
	terrain.add_child(mesh_instance)
	# Visual-only neighboring copies keep a continuous horizon at map edges.
	# The central terrain remains the only collision surface.
	for tile_x in range(-1, 2):
		for tile_z in range(-1, 2):
			if tile_x == 0 and tile_z == 0:
				continue
			var neighbor := MeshInstance3D.new()
			neighbor.name = "WrappedTerrain_%d_%d" % [tile_x, tile_z]
			neighbor.mesh = terrain_mesh
			neighbor.material_override = terrain_material
			neighbor.position = Vector3(tile_x * WORLD_WIDTH, 0.0, tile_z * WORLD_DEPTH)
			neighbor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			terrain.add_child(neighbor)

	var height_shape := HeightMapShape3D.new()
	height_shape.map_width = verts_x
	height_shape.map_depth = verts_z
	height_shape.map_data = heights

	var collision := CollisionShape3D.new()
	collision.shape = height_shape
	collision.scale = Vector3(step_x, 1.0, step_z)
	terrain.add_child(collision)

	add_child(terrain)


func create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Astronaut"
	player.position = get_player_spawn_position()
	player.collision_layer = 2
	player.collision_mask = 1
	player.floor_max_angle = deg_to_rad(FLOOR_MAX_ANGLE_DEG)
	player.floor_snap_length = 0.6
	player.floor_stop_on_slope = true
	player.floor_constant_speed = true
	player.floor_block_on_wall = true
	player.max_slides = 6
	add_child(player)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	player.add_child(collision)

	create_astronaut_model()

	camera_pivot = Node3D.new()
	camera_pivot.position.y = 1.5
	player.add_child(camera_pivot)

	var spring_arm := SpringArm3D.new()
	spring_arm.spring_length = 5.0
	spring_arm.margin = 0.3
	spring_arm.collision_mask = 1
	spring_arm.position.y = 0.7

	var spring_shape := SphereShape3D.new()
	spring_shape.radius = 0.3
	spring_arm.shape = spring_shape
	camera_pivot.add_child(spring_arm)

	player_camera = Camera3D.new()
	player_camera.rotation_degrees.x = -8.0
	player_camera.far = 1100.0
	spring_arm.add_child(player_camera)
	player_camera.current = true
	create_storm_cloud_volume()
	create_night_starfield()


func create_night_starfield() -> void:
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.65
	star_mesh.height = 1.3
	star_mesh.radial_segments = 6
	star_mesh.rings = 4

	var star_multimesh := MultiMesh.new()
	star_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	star_multimesh.use_colors = true
	star_multimesh.mesh = star_mesh
	star_multimesh.instance_count = 520
	for i in range(star_multimesh.instance_count):
		var y_direction := randf_range(-1.0, 1.0)
		var azimuth := randf_range(0.0, TAU)
		var horizontal := sqrt(maxf(1.0 - y_direction * y_direction, 0.0))
		var direction := Vector3(horizontal * cos(azimuth), y_direction, horizontal * sin(azimuth))
		var size_factor := randf_range(0.45, 1.8)
		var transform := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size_factor), direction * 900.0)
		star_multimesh.set_instance_transform(i, transform)
		var brightness := randf_range(0.55, 1.0)
		star_multimesh.set_instance_color(i, Color(0.72, 0.82, 1.0, brightness))

	starfield = MultiMeshInstance3D.new()
	starfield.name = "NightSkyStars"
	starfield.multimesh = star_multimesh
	starfield.custom_aabb = AABB(Vector3(-1000.0, -1000.0, -1000.0), Vector3(2000.0, 2000.0, 2000.0))
	starfield.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	night_star_material = StandardMaterial3D.new()
	night_star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	night_star_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	night_star_material.vertex_color_use_as_albedo = true
	night_star_material.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	night_star_material.emission_enabled = true
	night_star_material.emission = Color(0.52, 0.67, 1.0)
	night_star_material.emission_energy_multiplier = 1.4
	starfield.material_override = night_star_material
	player.add_child(starfield)


func create_astronaut_model() -> void:
	astronaut_model = Node3D.new()
	astronaut_model.name = "AstronautModel"
	player.add_child(astronaut_model)

	var model_scene := load(ASTRONAUT_MODEL) as PackedScene
	if model_scene == null:
		push_warning("Astronaut model not found; using the built-in suit placeholder.")
		create_placeholder_astronaut()
		return

	var suit_model := model_scene.instantiate()
	suit_model.name = "NASA_Astronaut_Static"
	suit_model.rotation.y = PI
	suit_model.scale = Vector3.ONE * NASA_ASTRONAUT_SCALE
	suit_model.position.y = NASA_ASTRONAUT_HALF_HEIGHT_M
	astronaut_model.add_child(suit_model)

	astronaut_animation = suit_model.find_child("AnimationPlayer", true, false) as AnimationPlayer

	var skeletons := suit_model.find_children("*", "Skeleton3D", true, false)
	if not skeletons.is_empty():
		skeleton = skeletons[0] as Skeleton3D

	setup_character_animations()
	if astronaut_animation == null and skeleton != null:
		skeleton.reset_bone_poses()
		apply_relaxed_standing_arm_pose()
		rest_pose_applied = true


func find_animation(keywords: Array) -> String:
	if astronaut_animation == null:
		return ""

	for anim_name in astronaut_animation.get_animation_list():
		var lowered := String(anim_name).to_lower()

		for keyword in keywords:
			if lowered.contains(String(keyword)):
				return String(anim_name)

	return ""


func setup_character_animations() -> void:
	if astronaut_animation == null:
		return

	print("ASTRA animations found: ", astronaut_animation.get_animation_list())

	anim_walk = "walk" if astronaut_animation.has_animation("walk") else find_animation(["walk"])
	anim_run = "run" if astronaut_animation.has_animation("run") else find_animation(["run", "sprint", "jog"])
	anim_idle = find_animation(["idle", "stand"])
	anim_climb = find_animation(["climb"])
	anim_air = find_animation(["jump", "fall"])

	for anim_name in [anim_idle, anim_climb]:
		if anim_name != "":
			astronaut_animation.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR


func create_card(parent: Node, panel_position: Vector2, panel_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = panel_position
	panel.custom_minimum_size = panel_size

	var style := StyleBoxFlat.new()
	style.bg_color = HUD_PANEL
	style.border_color = HUD_LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 13.0
	style.content_margin_right = 13.0
	style.content_margin_top = 11.0
	style.content_margin_bottom = 11.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0.0, 3.0)

	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	return panel


func make_progress_bar(parent: Control, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(220.0, 8.0)
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.show_percentage = false

	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.06, 0.09, 0.11, 1.0)
	background.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", background)

	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill)

	parent.add_child(bar)
	return bar


func create_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)

	# Compact crew-status card. Keep labels short so the landscape remains visible.
	var stats_panel := create_card(canvas, Vector2(22.0, 20.0), Vector2(330.0, 126.0))
	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 5)
	stats_panel.add_child(stats_box)

	title_label = Label.new()
	title_label.text = "ASTRA   /   SURFACE OPERATIONS"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", HUD_PRIMARY)
	stats_box.add_child(title_label)
	var mission_subtitle := Label.new()
	mission_subtitle.text = "AEOLIS PALUS  ·  CREWED FIELD UNIT 01"
	mission_subtitle.add_theme_font_size_override("font_size", 10)
	mission_subtitle.add_theme_color_override("font_color", HUD_SECONDARY)
	stats_box.add_child(mission_subtitle)

	jetpack_value = Label.new()
	jetpack_value.add_theme_font_size_override("font_size", 11)
	jetpack_value.add_theme_color_override("font_color", HUD_CYAN)
	stats_box.add_child(jetpack_value)
	jetpack_bar = make_progress_bar(stats_box, HUD_CYAN)

	var data_panel := create_card(canvas, Vector2(-314.0, 20.0), Vector2(292.0, 242.0))
	data_panel.anchor_left = 1.0
	data_panel.anchor_right = 1.0

	var data_box := VBoxContainer.new()
	data_box.add_theme_constant_override("separation", 5)
	data_panel.add_child(data_box)

	var data_title := Label.new()
	data_title.text = "ENVIRONMENT  /  MARS"
	data_title.add_theme_font_size_override("font_size", 13)
	data_title.add_theme_color_override("font_color", HUD_PRIMARY)
	data_box.add_child(data_title)

	environment_status_label = Label.new()
	environment_status_label.text = "SITE  GALE ANALOG  /  AEOLIS PALUS\nATMOSPHERE  CO2 95%\nSURFACE PRESSURE  6.36 mbar\nMEAN TEMPERATURE  214 K\nMAP FOOTPRINT  1.44 km2"
	environment_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	environment_status_label.add_theme_font_size_override("font_size", 11)
	environment_status_label.add_theme_color_override("font_color", HUD_SECONDARY)
	data_box.add_child(environment_status_label)

	var controls_panel := create_card(canvas, Vector2(22.0, -154.0), Vector2(350.0, 132.0))
	controls_panel.anchor_top = 1.0
	controls_panel.anchor_bottom = 1.0

	var controls_box := VBoxContainer.new()
	controls_box.add_theme_constant_override("separation", 5)
	controls_panel.add_child(controls_box)

	var controls_title := Label.new()
	controls_title.text = "MOBILITY  /  EVA CONTROLS"
	controls_title.add_theme_font_size_override("font_size", 11)
	controls_title.add_theme_color_override("font_color", HUD_CYAN)
	controls_box.add_child(controls_title)

	var controls_text := Label.new()
	controls_text.text = "WASD WALK  %.1f km/h   SHIFT RUN  %.1f km/h\nSPACE HOP   E EVA THRUSTERS   F SAMPLE\nC UPLINK   F1 CONSOLE   F2 STORM DRILL" % [WALK_SPEED * 3.6, SPRINT_SPEED * 3.6]
	controls_text.add_theme_font_size_override("font_size", 10)
	controls_text.add_theme_color_override("font_color", HUD_SECONDARY)
	controls_box.add_child(controls_text)

	message_panel = create_card(canvas, Vector2(-275.0, -94.0), Vector2(550.0, 48.0))
	message_panel.anchor_left = 0.5
	message_panel.anchor_right = 0.5
	message_panel.anchor_top = 1.0
	message_panel.anchor_bottom = 1.0
	message_panel.visible = false
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 12)
	message_label.add_theme_color_override("font_color", HUD_PRIMARY)
	message_panel.add_child(message_label)

	update_hud()


func update_hud(delta: float = 0.0) -> void:
	if not is_instance_valid(jetpack_bar):
		return

	var jetpack_percent := 0.0

	if jetpack_recharge_timer > 0.0:
		jetpack_value.text = "EVA THRUST  /  RECHARGE  %02.0f s" % jetpack_recharge_timer
		jetpack_percent = 100.0 * (1.0 - jetpack_recharge_timer / JETPACK_RECHARGE_TIME)
	else:
		jetpack_value.text = "EVA THRUST  /  PROPELLANT  %03.0f%%" % (100.0 * jetpack_fuel / JETPACK_DURATION)
		jetpack_percent = 100.0 * jetpack_fuel / JETPACK_DURATION

	var blend := 1.0 if delta <= 0.0 else minf(delta * 6.0, 1.0)
	jetpack_bar.value = lerpf(jetpack_bar.value, jetpack_percent, blend)
	if is_instance_valid(environment_status_label):
		var local_hour := int(floor(local_mars_hour))
		var local_minute := int(floor((local_mars_hour - float(local_hour)) * 60.0))
		environment_status_label.text = "SITE  GALE ANALOG  /  AEOLIS PALUS\nLOCAL SOL  %02d:%02d  /  SOL %02d\nSOLAR PHASE  %s\nATMOSPHERE  CO2 95%\nSURFACE PRESSURE  6.36 mbar\nMEAN TEMPERATURE  214 K\nMAP FOOTPRINT  1.44 km2\nDUST  %s  /  %02.0f%%\nSIM VISUAL RANGE  ~%03.0f m\nSIM SOLAR OUTPUT  %02.0f%%\nWIND LOAD  LOW  /  THIN AIR" % [local_hour, local_minute, simulated_sol_number, solar_phase_label, storm_status, storm_intensity * 100.0, storm_visibility_m, simulated_solar_output]


func create_storm_cloud_volume() -> void:
	if not storm_fog_supported:
		push_warning("High-detail volumetric dust clouds require the Forward+ renderer. The scene will use its animated distance haze on this renderer.")
		return
	var fog_shader := Shader.new()
	fog_shader.code = MARS_DUST_FOG_SHADER_CODE
	storm_fog_material = ShaderMaterial.new()
	storm_fog_material.shader = fog_shader
	storm_fog_material.set_shader_parameter("storm_intensity", 0.0)

	storm_fog_volume = FogVolume.new()
	storm_fog_volume.name = "AnimatedMartianDustClouds"
	storm_fog_volume.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	storm_fog_volume.size = Vector3(2400.0, 280.0, 2400.0)
	storm_fog_volume.position = Vector3(0.0, 30.0, 0.0)
	storm_fog_volume.material = storm_fog_material
	storm_fog_volume.visible = false
	player.add_child(storm_fog_volume)


func update_mars_weather(delta: float) -> void:
	if storm_drill_active:
		storm_target_intensity = 1.0
	else:
		var hours_since_noon := fposmod(local_mars_hour - MARS_STORM_START_LOCAL_HOUR, 24.0)
		var storm_event_time := hours_since_noon * SIMULATED_SOL_DURATION / 24.0
		if storm_event_time < MARS_STORM_BUILD_SECONDS:
			storm_target_intensity = storm_event_time / MARS_STORM_BUILD_SECONDS
		elif storm_event_time < MARS_STORM_BUILD_SECONDS + MARS_STORM_PEAK_SECONDS:
			storm_target_intensity = 1.0
		elif storm_event_time < MARS_STORM_BUILD_SECONDS + MARS_STORM_PEAK_SECONDS + MARS_STORM_DECAY_SECONDS:
			var decay_progress := (storm_event_time - MARS_STORM_BUILD_SECONDS - MARS_STORM_PEAK_SECONDS) / MARS_STORM_DECAY_SECONDS
			storm_target_intensity = 1.0 - decay_progress
		else:
			storm_target_intensity = 0.0

	storm_intensity = move_toward(storm_intensity, storm_target_intensity, delta * 0.085)
	storm_intensity = clampf(storm_intensity, 0.0, 1.0)
	storm_visibility_m = lerpf(1800.0, 150.0, pow(storm_intensity, 1.15))
	storm_solar_availability = lerpf(100.0, 22.0, pow(storm_intensity, 1.1))
	if storm_intensity < 0.04:
		storm_status = "CLEAR"
	elif storm_target_intensity > storm_intensity + 0.035:
		storm_status = "DUST LIFTING"
	elif storm_target_intensity < storm_intensity - 0.035:
		storm_status = "SETTLING"
	else:
		storm_status = "ACTIVE"

	if is_instance_valid(mars_environment):
		mars_environment.fog_density = lerpf(0.00115, 0.0045, storm_intensity)
	if is_instance_valid(terrain_shader_material):
		terrain_shader_material.set_shader_parameter("storm_dust", storm_intensity)
	if is_instance_valid(storm_fog_material):
		storm_fog_material.set_shader_parameter("storm_intensity", storm_intensity)
		storm_fog_material.set_shader_parameter("daylight_factor", daylight_factor)
	if is_instance_valid(storm_fog_volume):
		storm_fog_volume.visible = storm_intensity > 0.015
	if storm_fog_supported and is_instance_valid(mars_environment):
		mars_environment.volumetric_fog_density = storm_intensity * 0.0016
		mars_environment.volumetric_fog_albedo = Color(0.62, 0.38, 0.25).lerp(Color(0.78, 0.56, 0.38), storm_intensity)


func update_mars_day_night() -> void:
	var elapsed_sols := mission_elapsed / SIMULATED_SOL_DURATION
	simulated_sol_number = int(floor(elapsed_sols)) + 1
	local_mars_hour = fposmod(5.0 + elapsed_sols * 24.0, 24.0)
	var solar_phase := TAU * (local_mars_hour - 6.0) / 24.0
	solar_elevation = sin(solar_phase)
	daylight_factor = smoothstep(-0.18, 0.38, solar_elevation)
	var direct_sun_factor := maxf(solar_elevation, 0.0)
	simulated_solar_output = 100.0 * direct_sun_factor * storm_solar_availability / 100.0
	if solar_elevation < -0.18:
		solar_phase_label = "NIGHT"
	elif solar_elevation < 0.12:
		solar_phase_label = "DAWN" if local_mars_hour < 12.0 else "DUSK"
	else:
		solar_phase_label = "DAY"

	if is_instance_valid(martian_sun):
		var sun_altitude := rad_to_deg(asin(clampf(solar_elevation, -1.0, 1.0)))
		var sun_azimuth := -cos(solar_phase) * 90.0
		martian_sun.rotation_degrees = Vector3(-sun_altitude, sun_azimuth, 0.0)
		martian_sun.light_energy = 1.25 * direct_sun_factor * storm_solar_availability / 100.0
		martian_sun.light_color = Color(1.0, 0.54, 0.30).lerp(Color(1.0, 0.88, 0.72), daylight_factor)

	var night_top := Color(0.012, 0.018, 0.045)
	var daylight_top := Color(0.27, 0.20, 0.14)
	var twilight_top := Color(0.28, 0.12, 0.095)
	var night_horizon := Color(0.035, 0.028, 0.05)
	var daylight_horizon := Color(0.75, 0.56, 0.40)
	var twilight_horizon := Color(0.78, 0.31, 0.17)
	var twilight_strength := 1.0 - smoothstep(0.04, 0.48, absf(solar_elevation))
	if is_instance_valid(mars_sky_material):
		var sky_top := night_top.lerp(daylight_top, daylight_factor)
		var sky_horizon := night_horizon.lerp(daylight_horizon, daylight_factor)
		sky_top = sky_top.lerp(twilight_top, twilight_strength * 0.62)
		sky_horizon = sky_horizon.lerp(twilight_horizon, twilight_strength * 0.72)
		var storm_day_tint := storm_intensity * daylight_factor
		mars_sky_material.sky_top_color = sky_top.lerp(Color(0.34, 0.23, 0.16), storm_day_tint * 0.45)
		mars_sky_material.sky_horizon_color = sky_horizon.lerp(Color(0.66, 0.43, 0.29), storm_day_tint * 0.52)
		mars_sky_material.ground_bottom_color = Color(0.012, 0.010, 0.018).lerp(Color(0.14, 0.105, 0.08), daylight_factor)
		mars_sky_material.ground_horizon_color = Color(0.025, 0.020, 0.033).lerp(Color(0.50, 0.38, 0.28), daylight_factor).lerp(Color(0.48, 0.32, 0.23), storm_intensity * 0.35)

	if is_instance_valid(mars_environment):
		mars_environment.ambient_light_color = Color(0.19, 0.22, 0.34).lerp(Color(0.65, 0.54, 0.42), daylight_factor)
		mars_environment.ambient_light_energy = lerpf(0.12, 0.48, daylight_factor) * lerpf(1.0, 0.78, storm_intensity)
		mars_environment.adjustment_saturation = lerpf(0.56, 0.82, daylight_factor) * lerpf(1.0, 0.84, storm_intensity)
		var storm_day_tint := storm_intensity * daylight_factor
		mars_environment.fog_light_color = Color(0.10, 0.075, 0.12).lerp(Color(0.58, 0.48, 0.38), daylight_factor).lerp(Color(0.48, 0.34, 0.25), storm_day_tint * 0.45)
	if is_instance_valid(night_star_material):
		var star_visibility := pow(1.0 - daylight_factor, 1.8)
		night_star_material.albedo_color = Color(1.0, 1.0, 1.0, star_visibility)
	if is_instance_valid(starfield):
		starfield.rotation.y = -solar_phase


func show_message(message: String) -> void:
	message_timer = 3.0

	if is_instance_valid(message_label):
		message_label.text = message.to_upper()
		message_panel.visible = true


func respawn_player() -> void:
	player.position = get_player_spawn_position()
	player.velocity = Vector3.ZERO
	climbing = false
	show_message("RETURNED TO LANDING ZONE")


func get_player_spawn_position() -> Vector3:
	return Vector3(SPAWN_POSITION.x, get_terrain_height(SPAWN_POSITION.x, SPAWN_POSITION.z) + 0.2, SPAWN_POSITION.z)


func _input(event: InputEvent) -> void:
	if not game_started:
		return

	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(mission_story) and mission_story.open:
			mission_story._set_open(false)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1 and is_instance_valid(mission_panel):
			mission_panel.visible = not mission_panel.visible
		if event.keycode == KEY_F2:
			storm_drill_active = not storm_drill_active
			show_message("DUST STORM DRILL %s" % ("ENGAGED" if storm_drill_active else "RELEASED"))
		if event.keycode == KEY_F:
			collect_nearby_sample()
		if event.keycode == KEY_C:
			uplink_science_data()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and (not is_instance_valid(mission_story) or not mission_story.open):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clampf(
			camera_pivot.rotation.x - event.relative.y * MOUSE_SENSITIVITY,
			deg_to_rad(-60.0),
			deg_to_rad(60.0)
		)


func _process(delta: float) -> void:
	if not game_started:
		return

	ui_timer += delta
	mission_elapsed += delta
	telemetry_clock += delta
	update_mars_weather(delta)
	update_mars_day_night()

	if ui_timer >= UI_UPDATE_INTERVAL:
		update_hud(ui_timer)
		ui_timer = 0.0

	if telemetry_clock >= 0.25:
		telemetry_clock = 0.0
		update_mission_control()


func _physics_process(delta: float) -> void:
	if not game_started:
		return

	effect_time += delta

	var direction := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var has_input := direction.length() > 0.0

	var forward := -camera_pivot.global_transform.basis.z
	var right := camera_pivot.global_transform.basis.x

	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var movement := (forward * -direction.y + right * direction.x).normalized()

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	var on_floor := player.is_on_floor()

	if on_floor:
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	var jetpack_wanted := (
		Input.is_action_pressed("jetpack")
		and jetpack_fuel > 0.0
		and jetpack_recharge_timer <= 0.0
	)

	update_climb_state(delta, direction, movement, jetpack_wanted)
	update_jetpack(delta)

	if climbing:
		process_climbing(direction)
	else:
		process_walking(delta, direction, movement, player.is_on_floor())

	player.move_and_slide()

	if player.is_on_wall():
		wall_normal = player.get_wall_normal()

	wrap_player_at_map_edge()

	update_model_orientation(delta, movement, has_input)
	update_character_animation(has_input)

	if message_timer > 0.0:
		message_timer -= delta

		if message_timer <= 0.0:
			message_label.text = ""
			message_panel.visible = false


func wrap_player_at_map_edge() -> void:
	var limit_x := WORLD_WIDTH * 0.5 - WORLD_EDGE_MARGIN
	var limit_z := WORLD_DEPTH * 0.5 - WORLD_EDGE_MARGIN
	var previous_position := player.position
	var wrapped := false
	if player.position.x > limit_x:
		player.position.x = -limit_x
		wrapped = true
	elif player.position.x < -limit_x:
		player.position.x = limit_x
		wrapped = true
	if player.position.z > limit_z:
		player.position.z = -limit_z
		wrapped = true
	elif player.position.z < -limit_z:
		player.position.z = limit_z
		wrapped = true
	if not wrapped:
		return
	var source_x := clampf(previous_position.x, -WORLD_WIDTH * 0.5, WORLD_WIDTH * 0.5)
	var source_z := clampf(previous_position.z, -WORLD_DEPTH * 0.5, WORLD_DEPTH * 0.5)
	var height_above_source := previous_position.y - get_terrain_height(source_x, source_z)
	player.position.y = get_terrain_height(player.position.x, player.position.z) + height_above_source
	# Avoid physics interpolation drawing a long sweep across the map during a rebase.
	player.reset_physics_interpolation()


func get_wrapped_horizontal_distance(from_position: Vector2, to_position: Vector2) -> float:
	var dx := absf(from_position.x - to_position.x)
	var dz := absf(from_position.y - to_position.y)
	dx = minf(dx, WORLD_WIDTH - dx)
	dz = minf(dz, WORLD_DEPTH - dz)
	return Vector2(dx, dz).length()


func process_walking(delta: float, direction: Vector2, movement: Vector3, on_floor: bool) -> void:
	var has_input := direction.length() > 0.0

	if not on_floor:
		player.velocity.y -= GRAVITY * delta
	elif player.velocity.y < 0.0:
		player.velocity.y = 0.0

	var sprinting := Input.is_action_pressed("sprint") and has_input
	var speed := SPRINT_SPEED if sprinting else WALK_SPEED

	if on_floor and has_input:
		var floor_normal := player.get_floor_normal()
		var slope_angle := acos(clampf(floor_normal.y, -1.0, 1.0))
		var downhill := Vector3(floor_normal.x, 0.0, floor_normal.z)

		if downhill.length() > 0.001 and movement.dot(downhill.normalized()) < -0.2:
			var effort := smoothstep(deg_to_rad(20.0), deg_to_rad(FLOOR_MAX_ANGLE_DEG), slope_angle)
			speed *= lerpf(1.0, UPHILL_MIN_SPEED_FACTOR, effort)

	var target_velocity := movement * speed
	var move_rate := 0.0

	if on_floor:
		move_rate = ACCELERATION if has_input else BRAKING
	else:
		move_rate = ACCELERATION * AIR_CONTROL if has_input else AIR_DRAG

	player.velocity.x = move_toward(player.velocity.x, target_velocity.x, move_rate * delta)
	player.velocity.z = move_toward(player.velocity.z, target_velocity.z, move_rate * delta)

	var wants_jump := jump_buffer_timer > 0.0 or (Input.is_action_pressed("jump") and on_floor)

	if wants_jump and coyote_timer > 0.0:
		player.velocity.y = JUMP_FORCE
		jump_buffer_timer = 0.0
		coyote_timer = 0.0


func get_surface_up(surface_normal: Vector3) -> Vector3:
	var up_dir := Vector3.UP - surface_normal * surface_normal.dot(Vector3.UP)

	if up_dir.length() < 0.05:
		return Vector3.UP

	return up_dir.normalized()


func update_climb_state(delta: float, direction: Vector2, movement: Vector3, jetpack_wanted: bool) -> void:
	climb_cooldown = maxf(climb_cooldown - delta, 0.0)

	var on_floor := player.is_on_floor()
	var on_wall := player.is_on_wall()

	if climbing:
		if Input.is_action_just_pressed("jump"):
			player.velocity = wall_normal * CLIMB_JUMP_AWAY + Vector3.UP * JUMP_FORCE
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
			stop_climbing()
			return

		if jetpack_wanted:
			stop_climbing()
			return

		if on_wall:
			climb_lost_timer = 0.0
		else:
			climb_lost_timer += delta

		var climbing_down := direction.y > 0.1

		if climb_lost_timer > CLIMB_LOST_GRACE or (on_floor and (not on_wall or climbing_down)):
			stop_climbing()

		return

	var pushing_into_wall := false

	if on_wall and movement.length() > 0.0:
		var flat_normal := Vector3(wall_normal.x, 0.0, wall_normal.z)

		if flat_normal.length() > 0.05:
			pushing_into_wall = movement.dot(-flat_normal.normalized()) > CLIMB_ENTRY_PUSH_DOT

	if pushing_into_wall and not jetpack_wanted and climb_cooldown <= 0.0:
		wall_contact_time += delta

		if wall_contact_time >= CLIMB_ENTRY_TIME:
			start_climbing()
	else:
		wall_contact_time = 0.0


func start_climbing() -> void:
	climbing = true
	wall_contact_time = 0.0
	climb_lost_timer = 0.0

	if not climb_hint_shown:
		climb_hint_shown = true
		show_message("CLIMBING  -  SPACE: JUMP OFF   E: JETPACK")


func stop_climbing() -> void:
	climbing = false
	wall_contact_time = 0.0
	climb_lost_timer = 0.0
	climb_cooldown = CLIMB_COOLDOWN
	climb_move_amount = 0.0


func process_climbing(direction: Vector2) -> void:
	var surface_normal := wall_normal
	var up_dir := get_surface_up(surface_normal)

	var camera_right := camera_pivot.global_transform.basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()

	var side := camera_right - surface_normal * surface_normal.dot(camera_right)

	if side.length() < 0.2:
		side = up_dir.cross(surface_normal)

	side = side.normalized()

	var speed := CLIMB_SPEED * (1.6 if Input.is_action_pressed("sprint") else 1.0)
	climb_move_amount = direction.length()

	player.velocity = (up_dir * -direction.y + side * direction.x) * speed - surface_normal * CLIMB_STICK_SPEED


func sample_ground() -> Dictionary:
	var space_state := get_world_3d().direct_space_state
	var from := player.global_position + Vector3.UP * 1.0
	var to := player.global_position + Vector3.DOWN * 1.5
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)

	return space_state.intersect_ray(query)


func update_model_orientation(delta: float, movement: Vector3, has_input: bool) -> void:
	if astronaut_model == null:
		return

	var blend := 1.0 - exp(-14.0 * delta)
	var target_quat := Quaternion.IDENTITY
	var target_offset := 0.0

	if climbing:
		var up_dir := get_surface_up(wall_normal)
		var side := up_dir.cross(wall_normal).normalized()

		target_quat = Basis(side, up_dir, wall_normal).get_rotation_quaternion()
		model_yaw = atan2(wall_normal.x, wall_normal.z)
		ground_normal = Vector3.UP

	else:
		if has_input:
			var target_angle := atan2(-movement.x, -movement.z)
			model_yaw = lerp_angle(model_yaw, target_angle, minf(12.0 * delta, 1.0))

		var target_normal := Vector3.UP

		if player.is_on_floor():
			var hit := sample_ground()

			if not hit.is_empty():
				target_normal = hit["normal"]
				var hit_position: Vector3 = hit["position"]
				target_offset = clampf(hit_position.y - player.global_position.y, -MAX_FOOT_DROP, 0.0)

		ground_normal = ground_normal.lerp(target_normal, blend).normalized()
		var tilt := Quaternion.IDENTITY.slerp(Quaternion(Vector3.UP, ground_normal), GROUND_TILT_AMOUNT)
		target_quat = tilt * Basis(Vector3.UP, model_yaw).get_rotation_quaternion()

	model_quat = model_quat.slerp(target_quat, blend)
	astronaut_model.basis = Basis(model_quat)
	model_height_offset = lerpf(model_height_offset, target_offset, blend)
	astronaut_model.position.y = model_height_offset + MODEL_FOOT_OFFSET


func hold_rest_pose() -> void:
	if rest_pose_applied:
		return

	if astronaut_animation.is_playing():
		astronaut_animation.stop()

	if skeleton != null:
		skeleton.reset_bone_poses()
		if anim_idle == "":
			apply_relaxed_standing_arm_pose()

	rest_pose_applied = true


func apply_relaxed_standing_arm_pose() -> void:
	# Some astronaut rigs ship without an idle clip and default to an A-pose.
	# Lower the arms and add a small elbow bend for a relaxed standing EVA stance.
	if skeleton == null:
		return
	var found_left := false
	var found_right := false
	for bone_index in range(skeleton.get_bone_count()):
		var bone_name := String(skeleton.get_bone_name(bone_index)).to_lower().replace("_", "").replace("-", "").replace(" ", "")
		var is_forearm := bone_name.contains("forearm") or bone_name.contains("lowerarm")
		if bone_name.contains("hand"):
			continue
		var side := 0
		if bone_name.contains("left") or bone_name.ends_with("arml") or bone_name.begins_with("larm"):
			side = -1
		elif bone_name.contains("right") or bone_name.ends_with("armr") or bone_name.begins_with("rarm"):
			side = 1
		if side == 0:
			continue
		var is_upper_arm := bone_name.contains("upperarm") or (bone_name.ends_with("arm") and not is_forearm)
		if is_upper_arm:
			# Opposite signs lower the mirrored left and right arms toward the body.
			var angle := deg_to_rad(50.0 * float(side))
			skeleton.set_bone_pose_rotation(bone_index, Quaternion(Vector3.FORWARD, angle))
			if side < 0:
				found_left = true
			else:
				found_right = true
		elif is_forearm:
			# A gentle bend avoids the straight, mannequin-like arm line.
			var elbow_bend := deg_to_rad(12.0 * float(side))
			skeleton.set_bone_pose_rotation(bone_index, Quaternion(Vector3.FORWARD, elbow_bend))
	if not found_left or not found_right:
		push_warning("No complete left/right upper-arm pair found for the relaxed idle fallback; check the astronaut rig bone names.")


func update_character_animation(has_input: bool) -> void:
	if astronaut_animation == null:
		return

	var on_floor := player.is_on_floor()
	var planar_speed := Vector2(player.velocity.x, player.velocity.z).length()
	var desired := ""
	var speed_scale := 1.0

	if climbing:
		desired = anim_climb if anim_climb != "" else anim_walk
		speed_scale = climb_move_amount * 1.4

	elif has_input and on_floor and planar_speed > 0.25:
		var running := Input.is_action_pressed("sprint") and anim_run != ""
		desired = anim_run if running else anim_walk

		var reference_speed := SPRINT_SPEED if running else WALK_SPEED
		var reference_rate := RUN_ANIM_RATE if running else WALK_ANIM_RATE
		speed_scale = reference_rate * clampf(planar_speed / reference_speed, 0.25, 1.0)

	elif not on_floor and anim_air != "":
		desired = anim_air

	else:
		desired = anim_idle

	if desired == "":
		hold_rest_pose()
		return

	rest_pose_applied = false

	if astronaut_animation.current_animation != desired or not astronaut_animation.is_playing():
		astronaut_animation.play(desired, 0.15)

	astronaut_animation.speed_scale = speed_scale


func update_jetpack(delta: float) -> void:
	if jetpack_recharge_timer > 0.0:
		jetpack_recharge_timer = maxf(jetpack_recharge_timer - delta, 0.0)

		if jetpack_recharge_timer == 0.0:
			jetpack_fuel = JETPACK_DURATION
			show_message("JETPACK RECHARGED")

	var using_jetpack := (
		Input.is_action_pressed("jetpack")
		and jetpack_fuel > 0.0
		and jetpack_recharge_timer <= 0.0
	)

	if using_jetpack:
		player.velocity.y = minf(player.velocity.y + JETPACK_THRUST * delta, 12.0)
		jetpack_fuel = maxf(jetpack_fuel - delta, 0.0)

		if jetpack_fuel <= 0.0:
			jetpack_recharge_timer = JETPACK_RECHARGE_TIME
			show_message("JETPACK EMPTY - RECHARGING")


# ------------------------------------------------------------------ mission control
func create_mission_control() -> void:
	mission_canvas = CanvasLayer.new()
	mission_canvas.layer = 8
	add_child(mission_canvas)
	mission_panel = create_card(mission_canvas, Vector2.ZERO, Vector2(368.0, 410.0))
	mission_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mission_panel.position = Vector2(-390.0, 188.0)
	mission_panel.z_index = 10
	mission_panel.visible = true
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	mission_panel.add_child(box)
	var heading := Label.new()
	heading.text = "MISSION CONSOLE  /  AEOLIS"
	heading.add_theme_font_size_override("font_size", 14)
	heading.add_theme_color_override("font_color", HUD_PRIMARY)
	box.add_child(heading)
	var caveat := Label.new()
	caveat.text = "SURFACE MISSION  /  FLIGHT SYSTEMS SIMULATED"
	caveat.add_theme_font_size_override("font_size", 9)
	caveat.add_theme_color_override("font_color", HUD_SECONDARY)
	box.add_child(caveat)
	mission_status_label = Label.new()
	mission_status_label.add_theme_font_size_override("font_size", 10)
	mission_status_label.add_theme_color_override("font_color", HUD_PRIMARY)
	box.add_child(mission_status_label)
	mission_progress_bar = make_progress_bar(box, HUD_GREEN)
	var link_title := Label.new()
	link_title.text = "LANDER RELAY  /  LINK QUALITY"
	link_title.add_theme_font_size_override("font_size", 9)
	link_title.add_theme_color_override("font_color", HUD_CYAN)
	box.add_child(link_title)
	communication_bar = make_progress_bar(box, HUD_CYAN)
	telemetry_label = Label.new()
	telemetry_label.add_theme_font_size_override("font_size", 10)
	telemetry_label.add_theme_color_override("font_color", HUD_SECONDARY)
	box.add_child(telemetry_label)
	var orbit_title := Label.new()
	orbit_title.text = "ORBITAL RELAY GEOMETRY  /  SCHEMATIC"
	orbit_title.add_theme_font_size_override("font_size", 9)
	orbit_title.add_theme_color_override("font_color", HUD_CYAN)
	box.add_child(orbit_title)
	orbital_widget = RadarWidget.new()
	orbital_widget.custom_minimum_size = Vector2(120.0, 62.0)
	orbital_widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(orbital_widget)
	timeline_label = Label.new()
	timeline_label.add_theme_font_size_override("font_size", 9)
	timeline_label.add_theme_color_override("font_color", HUD_SECONDARY)
	box.add_child(timeline_label)
	update_mission_control()


func collect_nearby_sample() -> void:
	if not is_instance_valid(player):
		return
	var nearest_index := -1
	var effective_sample_range := SAMPLE_RANGE * lerpf(1.0, 0.55, storm_intensity)
	var nearest_distance := effective_sample_range
	for i in range(SAMPLE_POSITIONS.size()):
		if sample_collected[i]:
			continue
		var p: Vector2 = SAMPLE_POSITIONS[i]
		var distance := get_wrapped_horizontal_distance(
			Vector2(player.global_position.x, player.global_position.z), p
		)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_index = i
	if nearest_index < 0:
		show_message("NO SAMPLE IN RANGE  |  STORM SCAN RANGE %.1f m" % effective_sample_range)
		return
	sample_collected[nearest_index] = true
	science_data_buffer += 1
	show_message("SAMPLE SECURED: %s  |  DATA BUFFERED" % SAMPLE_NAMES[nearest_index].to_upper())
	if is_instance_valid(mission_story):
		mission_story.on_sample_collected(nearest_index, SAMPLE_NAMES[nearest_index])
	update_mission_control()


func uplink_science_data() -> void:
	if science_data_buffer <= 0:
		show_message("NO NEW SCIENCE DATA TO UPLINK")
		return
	if not is_instance_valid(player):
		return
	relay_distance = get_wrapped_horizontal_distance(
		Vector2(player.global_position.x, player.global_position.z),
		Vector2(SPAWN_POSITION.x, SPAWN_POSITION.z)
	)
	if relay_distance > 115.0:
		show_message("UPLINK UNAVAILABLE: MOVE CLOSER TO LANDER RELAY")
		return
	uplink_count += science_data_buffer
	science_data_buffer = 0
	show_message("SCIENCE UPLINK RECEIVED  |  USER SEGMENT ACTIVE")
	if is_instance_valid(mission_story):
		mission_story.on_uplink_received(uplink_count)
	update_mission_control()


func create_placeholder_astronaut() -> void:
	var suit := StandardMaterial3D.new()
	suit.albedo_color = Color(0.77, 0.81, 0.78)
	suit.metallic = 0.12
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.2, 0.22)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.86, 0.52, 0.17)
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.27
	torso_mesh.height = 0.85
	var torso := MeshInstance3D.new()
	torso.mesh = torso_mesh
	torso.material_override = suit
	torso.position.y = 0.95
	astronaut_model.add_child(torso)
	var helmet_mesh := SphereMesh.new()
	helmet_mesh.radius = 0.19
	helmet_mesh.height = 0.38
	var helmet := MeshInstance3D.new()
	helmet.mesh = helmet_mesh
	helmet.material_override = dark
	helmet.position = Vector3(0.0, 1.52, 0.0)
	astronaut_model.add_child(helmet)
	var visor_mesh := SphereMesh.new()
	visor_mesh.radius = 0.145
	visor_mesh.height = 0.22
	var visor := MeshInstance3D.new()
	visor.mesh = visor_mesh
	visor.material_override = gold
	visor.position = Vector3(0.0, 1.53, -0.075)
	astronaut_model.add_child(visor)
	var pack_mesh := BoxMesh.new()
	pack_mesh.size = Vector3(0.38, 0.5, 0.22)
	var pack := MeshInstance3D.new()
	pack.mesh = pack_mesh
	pack.material_override = dark
	pack.position = Vector3(0.0, 1.0, 0.27)
	astronaut_model.add_child(pack)
	for side in [-1.0, 1.0]:
		var limb_mesh := CapsuleMesh.new()
		limb_mesh.radius = 0.09
		limb_mesh.height = 0.65
		var arm := MeshInstance3D.new()
		arm.mesh = limb_mesh
		arm.material_override = suit
		arm.position = Vector3(side * 0.34, 0.97, 0.0)
		arm.rotation.z = side * -0.14
		astronaut_model.add_child(arm)
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.105
		leg_mesh.height = 0.74
		var leg := MeshInstance3D.new()
		leg.mesh = leg_mesh
		leg.material_override = suit
		leg.position = Vector3(side * 0.14, 0.38, 0.0)
		astronaut_model.add_child(leg)
	var chest_mesh := BoxMesh.new()
	chest_mesh.size = Vector3(0.2, 0.24, 0.06)
	var chest := MeshInstance3D.new()
	chest.mesh = chest_mesh
	chest.material_override = gold
	chest.position = Vector3(0.0, 1.08, -0.24)
	astronaut_model.add_child(chest)


func update_mission_control() -> void:
	if not is_instance_valid(player) or not is_instance_valid(mission_status_label):
		return
	relay_distance = get_wrapped_horizontal_distance(
		Vector2(player.global_position.x, player.global_position.z),
		Vector2(SPAWN_POSITION.x, SPAWN_POSITION.z)
	)
	communication_quality = clampf(100.0 * (1.0 - maxf(relay_distance - 25.0, 0.0) / 115.0), 0.0, 100.0)
	var collected := 0
	for flag in sample_collected:
		if flag:
			collected += 1
	var ground_status := "ACTIVE" if collected < SAMPLE_POSITIONS.size() else "SCIENCE COMPLETE"
	var user_status := "ANALYSIS ACTIVE" if uplink_count > 0 else "AWAITING DATA"
	var nearest_sample_distance := INF
	for i in range(SAMPLE_POSITIONS.size()):
		if sample_collected[i]:
			continue
		var sample_position: Vector2 = SAMPLE_POSITIONS[i]
		var sample_distance := get_wrapped_horizontal_distance(
			Vector2(player.global_position.x, player.global_position.z), sample_position
		)
		nearest_sample_distance = minf(nearest_sample_distance, sample_distance)
	var objective_line := "NEXT SAMPLE  %.0f m" % nearest_sample_distance if nearest_sample_distance < INF else "ALL SAMPLES SECURED"
	mission_status_label.text = "FLIGHT SEGMENTS\nLAUNCH   COMPLETE     SPACE   COMPLETE\nGROUND  %s\nUSER     %s\nSCIENCE  %d / %d SAMPLES\n%s" % [ground_status, user_status, collected, SAMPLE_POSITIONS.size(), objective_line]
	if is_instance_valid(mission_progress_bar):
		mission_progress_bar.value = 100.0 * float(collected) / float(SAMPLE_POSITIONS.size())
	if is_instance_valid(communication_bar):
		communication_bar.value = communication_quality
	var minutes := int(mission_elapsed / 60.0)
	var seconds := int(mission_elapsed) % 60
	var local_hour := int(floor(local_mars_hour))
	var local_minute := int(floor((local_mars_hour - float(local_hour)) * 60.0))
	telemetry_label.text = "MET  %02d:%02d  /  SOL %02d  LMST %02d:%02d  %s\nLANDER RANGE  %03.0f m  /  LINK %02.0f%%\nDUST %s %02.0f%%  /  VIS ~%03.0f m\nSIM SOLAR OUTPUT  %02.0f%%\nDATA BUFFER  %d  /  RETURNED  %d" % [minutes, seconds, simulated_sol_number, local_hour, local_minute, solar_phase_label, relay_distance, communication_quality, storm_status, storm_intensity * 100.0, storm_visibility_m, simulated_solar_output, science_data_buffer, uplink_count]
	timeline_label.text = "MISSION TIMELINE\nT+00  DEPLOYMENT COMPLETE\nT+01  SURFACE OPERATIONS ACTIVE\n%s  SCIENCE DOWNLINK" % ("DONE " if uplink_count > 0 else "NEXT ")
	if is_instance_valid(orbital_widget):
		var phase := fposmod(mission_elapsed * 0.08, TAU)
		var relay := Vector2(cos(phase) * 0.74, sin(phase) * 0.74)
		var mars := Vector2.ZERO
		var lander := Vector2(0.23, -0.12)
		orbital_widget.set_blips([relay, mars, lander])
