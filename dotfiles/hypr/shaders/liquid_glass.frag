#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

void main() {
    vec2 uv = v_texcoord;
    
    // Vetor a partir do centro da tela
    vec2 dir = uv - vec2(0.5);
    float dist = length(dir);

    // Amostragem de contraste de alta frequência (detecta texto, código e janelas em primeiro plano)
    vec2 px = vec2(0.0008, 0.0008);
    vec3 c_center = texture(tex, uv).rgb;
    vec3 c_right  = texture(tex, uv + vec2(px.x, 0.0)).rgb;
    vec3 c_up     = texture(tex, uv + vec2(0.0, px.y)).rgb;
    
    float high_freq = max(length(c_center - c_right), length(c_center - c_up));

    // PROTEÇÃO TOTAL DO PRIMEIRO PLANO:
    // Bordas nítidas de texto, ícones e janelas em foco em primeiro plano anulam a aberração (fator 0.0).
    // Apenas fundos difusos, desfoques e gradientes de segundo plano recebem a dispersão óptica.
    float background_weight = smoothstep(0.05, 0.015, high_freq);

    // Força refinada e sutil (dispersão delicada sem agressividade visual)
    float strength = 0.0008 * smoothstep(0.25, 0.95, dist) * background_weight;

    vec2 r_offset = dir * strength;
    vec2 b_offset = -dir * strength;

    float r = texture(tex, uv + r_offset).r;
    float g = c_center.g;
    float b = texture(tex, uv + b_offset).b;
    float a = texture(tex, uv).a;

    fragColor = vec4(r, g, b, a);
}
