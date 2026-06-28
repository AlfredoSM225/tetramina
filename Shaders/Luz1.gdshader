shader_type canvas_item;

uniform vec4 color_luz : source_color = vec4(1.0, 0.9, 0.5, 1.0);
uniform float intensidad_base : hint_range(0.0, 10.0) = 2.5;
uniform float velocidad_pulsacion : hint_range(0.0, 20.0) = 4.0;
uniform float amplitud_pulsacion : hint_range(0.0, 1.0) = 0.4;
uniform float radio_difuminado : hint_range(0.0, 5.0) = 1.5;

void fragment() {
    // === LA SOLUCIÓN REFORZADA ===
    // En lugar de un render_mode global, usamos "filter_linear" aquí dentro.
    // Esto le dice a Godot que suavice esta lectura de textura en específico.
    vec4 tex_color = texture(TEXTURE, UV, filter_linear);
    
    // Animación de pulsación orgánica
    float onda = sin(TIME * velocidad_pulsacion);
    float intensidad_actual = intensidad_base + (onda * amplitud_pulsacion);
    
    // Simulación matemática de difuminado (Blur) usando el filtro lineal
    vec4 blur = texture(TEXTURE, UV + vec2(0.0, TEXTURE_PIXEL_SIZE.y * radio_difuminado), filter_linear) +
                texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y * radio_difuminado), filter_linear) +
                texture(TEXTURE, UV + vec2(TEXTURE_PIXEL_SIZE.x * radio_difuminado, 0.0), filter_linear) +
                texture(TEXTURE, UV - vec2(TEXTURE_PIXEL_SIZE.x * radio_difuminado, 0.0), filter_linear);
    
    // Promediamos el muestreo del difuminado combinándolo con el pixel central
    vec4 color_suavizado = (tex_color + blur) / 5.0;
    
    // Mezcla final: aplicamos el brillo difuso respetando la transparencia (Alpha)
    vec3 brillo = color_suavizado.rgb * color_luz.rgb * intensidad_actual;
    
    COLOR = vec4(tex_color.rgb + brillo, tex_color.a);
}
