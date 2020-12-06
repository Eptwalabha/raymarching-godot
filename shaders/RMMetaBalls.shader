shader_type spatial;
render_mode world_vertex_coords;
render_mode unshaded;

uniform vec3 light = vec3(0., 5., 0.);

const float SURFACE_DISTANCE = 0.001;
const float MAX_DISTANCE = 100.;
const int MAX_STEP = 300;

varying vec3 v;
varying vec3 rO;

float sdSphere(vec3 p, float radius) {
	return length(p) - radius;
}

float smin(float a, float b, float t) {
	float h = clamp(0.5 + 0.5 * (b - a) / t, 0., 1.);
	return mix( b, a, h ) - t * h * (1. - h);
}

float GetDist(vec3 p, float time) {
	
	float big = sdSphere(p - vec3(cos(time * .2) * 0.534, sin(time * .7) * .432, -.8), .3);
	float small = sdSphere(p - vec3(cos(time * 1.234) * .5, sin(time * 2.), -.8), .2);
	
	return smin(big, small, .2);
}

vec3 GetNormal(vec3 p) {
	vec2 e = vec2(1.e-3, 0.);
	return normalize(GetDist(p, 0.) - vec3(
		GetDist(p - e.xyy, 0.),
		GetDist(p - e.yxy, 0.),
		GetDist(p - e.yyx, 0.)
	));
}

float RayMarcher(vec3 ro, vec3 rd, float time) {
	float dO = 0.;
	float dS;
	for (int i = 0; i < MAX_STEP; i++) {
		vec3 p = ro + dO * rd;
		dS = GetDist(p, time);
		dO += dS;
		if (dS < SURFACE_DISTANCE || dO > MAX_DISTANCE) {
			break;
		}
	}
	return dO;
}

float getLight(vec3 p, vec3 lp, float time) {
	vec3 d = lp - p;
	vec3 l = normalize(d);
	vec3 n = GetNormal(p);
	float diff = clamp(dot(n, l), 0., 1.);
	float shadow = RayMarcher(p + l * 0.005, l, time);
	if (shadow < length(d)) {
		return diff * .1;
	}
	return diff;
}

void vertex() {
	rO = (inverse(WORLD_MATRIX) * CAMERA_MATRIX[3]).xyz;
	v = (inverse(WORLD_MATRIX) * vec4(VERTEX, 1.)).xyz;
}

void fragment() {
	
	vec3 dr = normalize(v - rO);
	
	float d = RayMarcher(rO, dr, TIME);
	vec3 c = vec3(0.);
	
	if (d <= MAX_DISTANCE) {
		vec3 p = rO + dr * d;
		float dif = getLight(p, vec3(0., 0., 2.), TIME);
		c += vec3(0.8) * dif * .6 + .04;
	}
	ALBEDO.xyz = c;
}