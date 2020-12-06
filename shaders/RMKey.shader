shader_type spatial;
render_mode world_vertex_coords;
render_mode unshaded;

const float SURFACE_DISTANCE = 0.0001;
const float MAX_DISTANCE = 20.;
const int MAX_STEP = 150;

varying vec3 v;
varying vec3 rO;

float smin(float a, float b, float t) {
	float h = clamp(0.5 + 0.5 * (b - a) / t, 0., 1.);
	return mix( b, a, h ) - t * h * (1. - h);
}

float sdSphere(vec3 p, float radius) {
	return length(p) - radius;
}

float sdBox(vec3 p, vec3 box) {
	vec3 q = abs(p) - box;
	return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.);
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
	vec3 pa = p - a, ba = b - a;
	float h = clamp( dot(pa, ba) / dot(ba, ba), 0., 1.);
	return length(pa - ba * h) - r;
}

float sdRing(vec3 p, float a, float b, float h) {
	float d = abs(length(p.xz) - a) - b;
	return max(d, abs(p.y) - h);
}

float sdKey(vec3 p, float time) {
	vec3 q = p - vec3(0., 0., -.5);
	
	float am = .7 * time;
	float ang = 4.71239; // ang = 3 * pi / 2
	mat2 m = mat2(vec2(cos(am), -sin(am)),
				vec2(sin(am), cos(am)));
	mat2 m2 = mat2(vec2(cos(ang), -sin(ang)),
				vec2(sin(ang), cos(ang)));
	q.xz *= m;
	q.yz *= m2;
	
	q.z -= sin(time*.5) * .1;
	
	float d = sdBox(q, vec3(.1));
	d = sdCapsule(q, vec3(0., 0., .13), vec3(0., 0., -.6), .05);
	d = smin(d, sdRing(q - vec3(0., 0., .3), .14, .05, .03), .02);
	
	float key = sdBox(q - vec3(.15, 0., -.45), vec3(.09, .035, .1));
	key = max(-sdBox(q - vec3(0.3, 0., -.45), vec3(.1, .1, .06)), key);
	key = max(-sdBox(q - vec3(0.25, 0., -.425), vec3(.1, .1, .03)), key);
	key = max(-sdBox(q - vec3(0.15, 0.03, -.425), vec3(.03, .02, .2)), key);
	key = max(-sdBox(q - vec3(0.23, -0.035, -.425), vec3(.03, .02, .2)), key);
	d = smin(d, key, .03);
//	float d = sdRing()
	return d - .005;
}

float GetDist(vec3 p, float time) {
	float d = max(-sdBox(p, vec3(.6, .9, 1.2)), sdBox(p - vec3(0., 0., -10.), vec3(10.)));
	float key = sdKey(p, time);
	return min(d, key);
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
		vec3 light1 = vec3(.6);
		float amb = clamp(0.5 + 0.5 * p.y, 0., 1.);
		float dif1 = getLight(p, light1, TIME);
		c += vec3(0.8) * dif1 * amb + .02;
	}
	ALBEDO.xyz = c;
}