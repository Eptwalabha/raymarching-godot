shader_type spatial;
render_mode world_vertex_coords;
render_mode unshaded;

uniform vec3 light = vec3(0., 5., 0.);

const float SURFACE_DISTANCE = 0.001;
const float MAX_DISTANCE = 150.;
const int MAX_STEP = 200;

varying vec3 v;
varying vec3 rO;

float sdInfiniSphere(vec3 p, vec3 c, float r) {
	vec3 p2 = mod(p + .5 * c, c) - .5 * c;
	return length(p2) - r;
}

float sdBox(vec3 p, vec3 box) {
	vec3 q = abs(p) - box;
	return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.);
}

float GetDist(vec3 p, float time) {
	return sdInfiniSphere(p - vec3(0., time, 6.), vec3(6.), .4);
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
	float shadow = RayMarcher(p + l * SURFACE_DISTANCE * 10., l, time);
	if (shadow < length(d)) {
		return diff * .3;
	}
	return diff;
}

vec3 background(vec3 p) {
	vec3 bg = vec3(0.);
	return vec3(1. - pow(abs(p.y), .01));
}

void vertex() {
	rO = (inverse(WORLD_MATRIX) * CAMERA_MATRIX[3]).xyz;
	v = (inverse(WORLD_MATRIX) * vec4(VERTEX, 1.)).xyz;
}

void fragment() {
	
	vec3 dr = normalize(v - rO);
	
	float d = RayMarcher(rO, dr, TIME);
	vec3 c = background(dr);
	
	if (d <= MAX_DISTANCE) {
		float shade = clamp(0., 1., getLight(rO + dr * d, vec3(0., 50., 0.), TIME));
		c = mix(vec3(shade), c, smoothstep(30., 120., d));
	}
	ALBEDO.xyz = c;
}