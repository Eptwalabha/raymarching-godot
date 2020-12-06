shader_type canvas_item;

uniform float v_meta : hint_range(0., 1.);
uniform float v_mix : hint_range(0., 2.);
uniform vec3 light = vec3(0., 5., 0.);
uniform vec3 look_at = vec3(0., 0., 0.);
uniform vec3 camera = vec3(-3., 3., -3.);
uniform float zoom : hint_range(.2, 2.);
uniform float speed : hint_range(-1., 1.);
uniform float time_offset = 0.;

const float SURFACE_DISTANCE = 0.001;
const float MAX_DISTANCE = 100.;
const int MAX_STEP = 100;

float sdSphere(vec3 p, float radius) {
    return length(p) - radius;
}

float sdInfiniSphere(vec3 p, vec3 c, float r) {
	vec3 p2 = mod(p + .5 * c, c) - .5 * c;
	return sdSphere(p2, r);
}

float sdBox(vec3 p, vec3 box) {
	vec3 q = abs(p) - box;
	return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.);
}

float smin(float a, float b, float t) {
	float h = clamp(0.5 + 0.5 * (b - a) / t, 0., 1.);
	return mix( b, a, h ) - t * h * (1. - h);
}

float GetDist(vec3 p) {
    
    float s1 = sdSphere(p - vec3(3.8, 3., 0.), 3.8);
	float s2 = sdSphere(p - vec3(-3.8, 3., 0.), 3.8);
    
    float meta = smin(s1, s2, v_meta);
    
	float s3 = sdSphere(p - vec3(0., 3., 2.), 3.);
    
	float inf = sdInfiniSphere(p - vec3(5., 1., 0.), vec3(10., 10., 10.), .8);
    
	float d = p.y + 3.;
    
	float box = sdBox(p - vec3(0., 3., 2.), vec3(2., 1.5, 2.) -.05);
	box = abs(box) - .05;
    
    d = min(d, mix(box, s3, v_mix));
    d = max(-meta, d);
    
    return min(d, inf);
}

vec3 GetNormal(vec3 p) {
	vec2 e = vec2(1.e-3, 0.);
	return normalize(GetDist(p) - vec3(
		GetDist(p - e.xyy),
		GetDist(p - e.yxy),
		GetDist(p - e.yyx)
	));
}

float RayMarcher(vec3 ro, vec3 rd) {
	float dO = 0.;
	float dS;
	for (int i = 0; i < MAX_STEP; i++) {
		vec3 p = ro + dO * rd;
		dS = GetDist(p);
		dO += dS;
		if (dS < SURFACE_DISTANCE || dO > MAX_DISTANCE) {
//            dO = float(i);
			break;
		}
	}
	return dO;
}

vec3 getDirection(vec3 rO, vec3 lk, vec2 uv, float z) {
	vec3 f = normalize(lk - rO);
	vec3 r = cross(vec3(0., 1., 0.), f);
	vec3 u = cross(f, r);
	vec3 c = rO + f * z;
	return (c + uv.x * r + uv.y * u) - rO; 
}

float getLight(vec3 p, vec3 lp) {
	vec3 d = lp - p;
	vec3 l = normalize(d);
	vec3 n = GetNormal(p);
	float diff = clamp(dot(n, l), 0., 1.);
	float shadow = RayMarcher(p + l * .05, l);
	if (shadow < length(d)) {
		return diff * .3;
	}
	return diff;
}

vec3 background(vec3 p) {
	vec3 bg = vec3(0.);
	float y = p.y * .5 + .5;
	bg += (1. - y) * vec3(1., .2, .8);
	return bg;
}

void fragment() {

	vec2 uv = UV - .5;
	uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	uv.y = - uv.y;
	
	float t = TIME * speed + time_offset;
	vec3 rO = vec3(camera.x * sin(t), camera.y, -camera.z * cos(t));
	vec3 dr = getDirection(rO, vec3(0., 2., 0.), uv, zoom);
	
	float d = RayMarcher(rO, dr);
    
    vec3 c = vec3(0.);
    
	if (d <= MAX_DISTANCE) {
		float diff = getLight(rO + dr * d, vec3(5., 15., -2.));
		c = vec3(diff);
		c = mix(c, background(dr), smoothstep(10., 100., d));
    } else {
		c = background(dr);
	}

    COLOR.xyz = c;
}