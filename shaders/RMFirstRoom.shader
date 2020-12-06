shader_type spatial;
render_mode world_vertex_coords;
render_mode unshaded;

const float SURFACE_DISTANCE = 0.0001;
const float MAX_DISTANCE = 20.;
const int MAX_STEP = 300;

varying vec3 v;
varying vec3 rO;

float sdSphere(vec3 p, float radius) {
	return length(p) - radius;
}

float sdBox(vec3 p, vec3 box) {
	vec3 q = abs(p) - box;
	return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.);
}

float GetDist(vec3 p, float time) {
	
	float sphere = sdSphere(p - vec3(0., 0, -.8), .4);
	float box = sdBox(p - vec3(0., 0, -.8), vec3(.3));
	
	return mix(sphere, box, sin(time * 2.));
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
	float shadow = RayMarcher(p + l * 0.008, l, time);
	if (shadow < length(d)) {
		return diff * .3;
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
	
	if (d > MAX_DISTANCE) {
		discard;
    } else {
		vec3 p = rO + dr * d;
		vec3 light1 = vec3(3., 5., 0.);
		vec3 light2 = vec3(-2., 10., 0.);
		float amb = clamp(0.5 + 0.5 * p.y, 0., 1.);
		float dif1 = getLight(p, light1, TIME);
		float dif2 = getLight(p, light2, TIME);
		c += vec3(0.8) * dif1 * amb + .02;
		c += dif2;
	}
	ALBEDO.xyz = c;
}