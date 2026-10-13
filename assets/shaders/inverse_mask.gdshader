shader_type canvas_item;

uniform sampler2D mask_texture : filter_linear, repeat_disable;
uniform float mask_scale = 1.0;

void fragment() {
	float screen_aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 mask_size = vec2(textureSize(mask_texture, 0));
	vec2 point = (UV - 0.5) * vec2(screen_aspect, 1.0);
	float mask = 0.0;
	if (mask_scale > 0.0001) {
		vec2 mask_uv = point / (vec2(mask_size.x / mask_size.y, 1.0) * mask_scale) + 0.5;
		if (all(greaterThanEqual(mask_uv, vec2(0.0))) && all(lessThanEqual(mask_uv, vec2(1.0)))) {
			mask = texture(mask_texture, mask_uv).a;
		}
	}
	COLOR = vec4(COLOR.rgb, 1.0 - mask);
}
