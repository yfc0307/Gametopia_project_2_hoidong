shader_type canvas_item;
render_mode unshaded;
uniform float clock = 0.0;
uniform float cloud_amount : hint_range(0.0,1.0) = 0.45;
uniform float cloud_speed = 0.045;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
	vec2 wind=vec2(clock*cloud_speed*2.0,clock*cloud_speed*0.23);
	vec2 p=UV*4.0+wind+vec2(7.5,3.1);
	float cloud=noise(p)*0.75+noise(p*2.0)*0.25;
	cloud=smoothstep(0.28,0.72,cloud);
	float transmission=1.0-clamp(cloud_amount*1.8,0.0,0.97)*cloud;
	float radial=1.0-smoothstep(0.6,1.0,length(UV-vec2(0.5))*2.0);
	COLOR=vec4(vec3(radial*transmission),1.0);
}
