shader_type canvas_item;

uniform vec4 mod : source_color = vec4(1.0);

void fragment() {
  vec4 color = texture(TEXTURE, UV);
  if (color == vec4(1.0))
    color *= mod;
  COLOR = color;
}
