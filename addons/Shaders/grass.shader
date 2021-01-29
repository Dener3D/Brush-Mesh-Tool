shader_type spatial;
render_mode blend_mix,depth_draw_always,cull_disabled,diffuse_burley,specular_schlick_ggx,unshaded;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform sampler2D noise : hint_black;
uniform vec4 top_color : hint_color;
uniform float specular;
uniform float metallic;
uniform float proximity_fade_distance;
uniform float alpha_scissor_threshold;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;


void vertex() {
	if (!OUTPUT_IS_SRGB) {
		COLOR.rgb = mix( pow((COLOR.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)), vec3(2.4)), COLOR.rgb* (1.0 / 12.92), lessThan(COLOR.rgb,vec3(0.04045)) );
	}
	vec3 world_position = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	VERTEX.x += sin(TIME) * clamp(VERTEX.y,0,1) * 0.2;
	
	
}



void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	float depth_tex = textureLod(DEPTH_TEXTURE,SCREEN_UV,0.0).r;
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV*2.0-1.0,depth_tex*2.0-1.0,1.0);
	world_pos.xyz/=world_pos.w;
	albedo_tex *= COLOR;
	ALBEDO = albedo.rgb * (mix(top_color.rgb, albedo_tex.rgb, clamp(UV.y,0,1)));
	ALPHA = albedo.a * albedo_tex.a;
	
	
	ALPHA*=clamp(1.0-smoothstep(world_pos.z+proximity_fade_distance,world_pos.z,VERTEX.z),0.0,1.0);
	ALPHA_SCISSOR=alpha_scissor_threshold;
}
