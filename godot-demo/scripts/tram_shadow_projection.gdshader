shader_type canvas_item;
render_mode unshaded, blend_mul;
uniform sampler2D tram_texture : filter_linear, repeat_disable;
uniform vec4 tram_rect;
uniform vec4 image_rect;
uniform vec4 window_rect;
uniform float shadow_slant = 0.28;
uniform float darkness : hint_range(0.0,1.0) = 0.90;
varying vec2 world_point;
void vertex(){world_point=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
void fragment(){
	float blocked=0.0;
	for(int i=1;i<20;i++){
		float source_y=window_rect.y+window_rect.w*float(i)/20.0;
		// Only sources upstream of this receiver can cast a downward shadow.
		if(source_y>=world_point.y){continue;}
		vec2 sample_world=world_point-vec2(shadow_slant,1.0)*(world_point.y-source_y);
		vec2 window_uv=(sample_world-window_rect.xy)/window_rect.zw;
		vec2 uv=(sample_world-tram_rect.xy)/tram_rect.zw;
		if(all(greaterThanEqual(uv,vec2(0.0))) && all(lessThanEqual(uv,vec2(1.0)))
			&& all(greaterThanEqual(window_uv,vec2(0.0))) && all(lessThanEqual(window_uv,vec2(1.0)))){
			blocked=max(blocked,texture(tram_texture,uv).a);
		}
	}
	float edge=smoothstep(0.0,0.035,UV.y)*(1.0-smoothstep(0.90,1.0,UV.y));
	// Moving the effect rectangle must never put a shadow over the window or tram.
	edge*=smoothstep(window_rect.y+window_rect.w,window_rect.y+window_rect.w+8.0,world_point.y);
	COLOR=vec4(vec3(1.0-clamp(blocked*darkness*edge,0.0,0.98)),1.0);
}
