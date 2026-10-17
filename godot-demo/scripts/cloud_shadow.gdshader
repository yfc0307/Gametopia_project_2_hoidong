shader_type canvas_item;
render_mode unshaded, blend_mul;
uniform sampler2D cloud_map : filter_linear, repeat_disable;
uniform vec2 light_origin;
uniform vec2 light_extent = vec2(1500.0);
uniform float strength : hint_range(0.0,0.7) = 0.35;
varying vec2 world_point;
void vertex(){ world_point=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy; }
void fragment(){
	vec2 uv=(world_point-light_origin)/light_extent+vec2(0.5);
	float radial=1.0-smoothstep(0.6,1.0,length(uv-vec2(0.5))*2.0);
	float transmission=clamp(texture(cloud_map,uv).r/max(radial,0.01),0.0,1.0);
	float edge=smoothstep(0.0,0.08,UV.x)*(1.0-smoothstep(0.92,1.0,UV.x));
	edge*=smoothstep(0.0,0.10,UV.y)*(1.0-smoothstep(0.8,1.0,UV.y));
	float shade=(1.0-transmission)*strength*edge*smoothstep(0.0,0.3,radial);
	COLOR=vec4(vec3(1.0)-shade*vec3(1.0),1.0);
}
