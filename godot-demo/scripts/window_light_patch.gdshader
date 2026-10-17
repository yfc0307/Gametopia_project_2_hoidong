shader_type canvas_item;
render_mode light_only, blend_add;
uniform vec4 tint : source_color = vec4(1.0, 0.85, 0.62, 1.0);
uniform float patch_strength : hint_range(0.0, 2.0) = 0.65;
uniform float direction : hint_range(-0.5,0.5) = 0.20;
void fragment() {
	float x = UV.x - UV.y * direction;
	float bands = (smoothstep(0.06,0.10,x)-smoothstep(0.23,0.27,x))
		+ (smoothstep(0.39,0.43,x)-smoothstep(0.55,0.59,x))
		+ (smoothstep(0.71,0.75,x)-smoothstep(0.87,0.91,x));
	float fade = smoothstep(0.0,0.12,UV.y) * (1.0-smoothstep(0.55,1.0,UV.y));
	COLOR = vec4(tint.rgb, tint.a * patch_strength * bands * fade);
}
