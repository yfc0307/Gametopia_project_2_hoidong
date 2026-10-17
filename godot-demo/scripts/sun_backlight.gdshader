shader_type canvas_item;
uniform float rim_strength : hint_range(0.0, 3.0) = 1.8;
uniform float face_brightness : hint_range(0.8, 1.0) = 0.97;
uniform float rim_width : hint_range(1.0,20.0) = 5.0;
varying float rim;
void fragment() {
	float alpha = texture(TEXTURE, UV).a;
	float upper_alpha = texture(TEXTURE, UV - vec2(0.0,rim_width) * TEXTURE_PIXEL_SIZE).a;
	rim = clamp(alpha-upper_alpha,0.0,1.0);
	COLOR.rgb *= face_brightness;
}
void light() {
	LIGHT = vec4(LIGHT_COLOR.rgb * COLOR.rgb * LIGHT_ENERGY * (0.32 + rim * rim_strength), LIGHT_COLOR.a);
}
