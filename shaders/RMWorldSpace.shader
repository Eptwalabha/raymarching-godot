shader_type spatial;
render_mode world_vertex_coords;
render_mode unshaded;

const float SURFACE_DISTANCE = 0.0001;
const float MAX_DISTANCE = 200.;
const int MAX_STEP = 300;

varying vec3 v;
varying vec3 rO;

float sdSphere(vec3 p, float radius) {
	return length(p) - radius;
}

float sdInfiniSphere(vec3 p, vec3 c, float r) {
	vec3 p2 = mod(p + .5 * c, c) - .5 * c;
	return length(p2) - r;
}

float GetDist(vec3 p, float time) {
	vec3 q = p - vec3(0., .6, 0.);
	float d = sdInfiniSphere(q, vec3(5.), .3);
	return max(abs(q.y) - .5, d);
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
		if (dS < SURFACE_DISTANCE || dO > MAX_DISTANCE) {
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

vec3 background(vec3 p) {
	vec3 bg = vec3(0.);
	return vec3(1. - pow(abs(p.y), .01));
}

void vertex() {
	rO = CAMERA_MATRIX[3].xyz;
	v = VERTEX;
}

void fragment() {
	
	vec3 dr = normalize(v - rO);
	
	float d = RayMarcher(rO, dr, TIME);
	vec3 c = background(dr);
	
	if (d <= MAX_DISTANCE) {
		vec3 p = rO + dr * d;
		vec3 light1 = vec3(0., 2., 0.);
		float amb = clamp(0.5 + 0.5 * p.y, 0., 1.);
		float dif1 = getLight(p, light1, TIME);
		vec3 c2 = vec3(0.8) * dif1 * amb + .02;
		c = mix(c2, c, smoothstep(30., 200., d));
	}
	ALBEDO.xyz = c;
}