shader_type canvas_item;
render_mode unshaded;
uniform vec4 shadow_color : source_color = vec4(0.25, 0.13, 0.065, 0.32);
uniform vec2 contact_center = vec2(0.5, 0.93);
uniform vec2 contact_radius = vec2(0.43, 0.065);
uniform float lift : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 radius = contact_radius * mix(vec2(1.0), vec2(1.12, 1.55), lift);
	float distance_from_center = length((UV - contact_center) / max(radius, vec2(0.001)));
	float opacity = pow(max(0.0, 1.0 - distance_from_center * distance_from_center), mix(2.2, 3.0, lift));
	COLOR = vec4(shadow_color.rgb, shadow_color.a * opacity * mix(1.0, 0.48, lift));
}
