shader_type spatial;
render_mode world_vertex_coords;
render_mode unshaded;

const float SURFACE_DISTANCE = 0.0001;
const float MAX_DISTANCE = 20.;
const int MAX_STEP = 150;

varying vec3 v;
varying vec3 rO;

float r21(vec2 p) {
	return fract(pow(sin(dot(p, vec2(27918.294, 1892090.0))), .124));
}

float smin(float a, float b, float t) {
	float h = clamp(0.5 + 0.5 * (b - a) / t, 0., 1.);
	return mix( b, a, h ) - t * h * (1. - h);
}

float sdTorus(vec3 p, float r1, float r2) {
	float d = length(p.xz) - r1;
	return length(vec2(d, p.y)) - r2;
}

float GetDist(vec3 p, float time) {
	float c = cos(time);
	float s = sin(time);
	p.xy *= mat2(vec2(c, -s), vec2(s, c));
	float s2 = sin(time * 2.3) * .5 + .5;
	return sdTorus(p, .4 + s2 * .1, .1 + s2 * .05);
}

vec3 GetNormal(vec3 p, float time) {
	vec2 e = vec2(1.e-3, 0.);
	return normalize(GetDist(p, time) - vec3(
		GetDist(p - e.xyy, time),
		GetDist(p - e.yxy, time),
		GetDist(p - e.yyx, time)
	));
}

float RayMarcher(vec3 ro, vec3 rd, float time) {
	float dO = 0.;
	float dS;
	
	for (int i = 0; i < MAX_STEP; i++) {
		vec3 p = ro + dO * rd;
		dS = GetDist(p, time);
		dO += dS;
		if (abs(dS) < SURFACE_DISTANCE || dO > MAX_DISTANCE) {
			break;
		}
	}
	return dO;
}

float getLight(vec3 p, vec3 lp, float time) {
	vec3 d = lp - p;
	vec3 l = normalize(d);
	vec3 n = GetNormal(p, time);
	float diff = clamp(dot(n, l), 0., 1.);
	float shadow = RayMarcher(p + l * 0.008, l, time);
	if (shadow < length(d)) {
		return diff * .3;
	}
	return diff;
}

float linearDepth(sampler2D text, vec2 screen_uv, mat4 inv_proj) {
	float depth = texture(text, screen_uv).x;
	vec3 ndc = vec3(screen_uv, depth) * 2.0 - 1.0;
	vec4 view = inv_proj * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

void vertex() {
	rO = (inverse(WORLD_MATRIX) * CAMERA_MATRIX[3]).xyz;
	v = (inverse(WORLD_MATRIX) * vec4(VERTEX, 1.)).xyz;
}

void fragment() {
	float linear_depth = linearDepth(DEPTH_TEXTURE, SCREEN_UV, INV_PROJECTION_MATRIX);
	vec3 dr = normalize(v - rO);
	float d = RayMarcher(rO, dr, TIME);
	vec3 c = vec3(0.);
	
	if (d > MAX_DISTANCE || d > linear_depth) {
		discard;
	} else {
		vec3 p = rO + dr * d;
		vec3 light1 = vec3(.6, 10., -.8);
		float amb = clamp(0.5 + 0.5 * p.y, 0., 1.);
		float dif1 = getLight(p, light1, TIME);
		c += vec3(0.8) * dif1 * amb + .02;
	}
	ALBEDO.xyz = c;
}