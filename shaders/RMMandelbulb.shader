shader_type spatial;
render_mode world_vertex_coords;
render_mode unshaded;

uniform sampler2D colors;

const float SURFACE_DISTANCE = 0.001;
const float MAX_DISTANCE = 200.;
const int MAX_STEP = 200;

varying vec3 v;
varying vec3 rO;


vec2 sdMandelbulb(vec3 p, float time, int iteration) {
	p = p.xzy;
	vec3 zn = p;
	float powr = 4.;
	float t0 = 1.;
	float d = 1.;
	float rho = 0., th = 0., phi = 0.;

	for (int i = 0; i < iteration; i++) {
		rho = length(zn);
		if (rho > 2.0)
			break;
			
		th = atan(zn.y / zn.x) * powr;
		phi = (asin(zn.z / rho) + time * .5) * powr;
		d = pow(rho, powr) * powr * d + 1.0;
		rho = pow(rho, powr);
		
		zn = vec3(cos(th) * cos(phi), sin(th) * cos(phi), sin(phi));
		zn = zn * rho + p;
		
		t0 = min(t0, rho);
	}
	return vec2(0.5 * log(rho) * rho / d, t0);
}

float sdSphere(vec3 p, float radius) {
	return length(p) - radius;
}

float sdBox(vec3 p, vec3 box) {
	vec3 q = abs(p) - box;
	return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.);
}

vec2 GetDist(vec3 p, float time) {
	float zoom = .8;
	return sdMandelbulb(p * zoom, time, 5) / zoom;
}

vec3 GetNormal(vec3 p) {
	vec2 e = vec2(1.e-3, 0.);
	return normalize(GetDist(p, 0.).x - vec3(
		GetDist(p - e.xyy, 0.).x,
		GetDist(p - e.yxy, 0.).x,
		GetDist(p - e.yyx, 0.).x
	));
}

vec2 RayMarcher(vec3 ro, vec3 rd, float time) {
	vec2 dO = vec2(0.);
	vec2 dS;
	
	for (int i = 0; i < MAX_STEP; i++) {
		vec3 p = ro + dO.x * rd;
		dS = GetDist(p, time);
		dO += dS.x;
		if (dS.x < SURFACE_DISTANCE || dO.x > MAX_DISTANCE) {
			break;
		}
	}
	return dO;
}

float getShadow(vec3 ro, vec3 rd, float k ){ 
	float penumbra = 1.0, h = 0.0, t = 0.01;
	for (int i = 0; i < 50; ++i){
		h = (ro + rd).x;
		if (h < 0.001) {
			return 0.02;
		}
		penumbra = min(penumbra, k * h / t);
		t += clamp(h, 0.01, 2.0);
	}
	return penumbra;
}

float getLight(vec3 p, vec3 lp, float time) {
	vec3 d = lp - p;
	vec3 l = normalize(d);
	vec3 n = GetNormal(p);
	float diff = clamp(dot(n, l), 0., 1.);
	float shadow = RayMarcher(p + l * 0.001, l, time).x;
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
	
	vec2 d = RayMarcher(rO, dr, TIME);
	vec3 c = vec3(0.);
	
	if (d.x > MAX_DISTANCE) {
		discard;
    } else {
		
		vec3 p = rO + dr * d.x;
		vec3 light = vec3(30., 50., -10.);
		float diff = getLight(p, light, TIME);
		float shade = getShadow(p, normalize(light - p), 10.);
		
		vec3 mat = texture(colors, vec2(smoothstep(0., 1., d.y), 0.)).xyz;
		vec3 tc0 = 0.5 + 0.5 * sin(3.0 + -3.1451 * p.y + vec3(.7, .2, .8));
		mat = vec3(0.9, 0.8, 0.6) *  0.2 * tc0;
		vec3 l = light * diff * shade + .2;
		c = mat * l;
		
//		p.y = pow(clamp(p.y, 0.0, 1.0), 0.55);
//		c = mat + diff * amb;
//		c += mat * diff * amb + .02;
	}
	ALBEDO.xyz = c;
}