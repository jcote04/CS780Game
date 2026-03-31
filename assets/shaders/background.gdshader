shader_type canvas_item;

uniform float scroll_speed_x : hint_range(-1.0, 1.0) = 0.02;
uniform float scroll_speed_y : hint_range(-1.0, 1.0) = 0.02;

void fragment() {
    vec2 uv = UV + vec2(scroll_speed_x, scroll_speed_y) * TIME;
    COLOR = texture(TEXTURE, uv);
}