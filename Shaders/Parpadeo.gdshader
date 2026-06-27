shader_type canvas_item;
uniform bool activado = false;
uniform float velocidad_parpadeo = 5.0;

uniform float opacidad_minima = 0.3; 

void fragment() {
	vec4 color_original = texture(TEXTURE, UV);
	
	if (activado) {
		float onda = (sin(TIME * velocidad_parpadeo) + 1.0) / 2.0;
		
		float alpha_dinamico = mix(opacidad_minima, 1.0, onda);
		
		COLOR = vec4(color_original.rgb, color_original.a * alpha_dinamico);
	} else {
		COLOR = color_original;
	}
}