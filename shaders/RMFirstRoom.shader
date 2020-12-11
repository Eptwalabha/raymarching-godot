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
	
	float c = cos(time);
	float s = sin(time);
	vec3 q = p - vec3(0., 0, -1.);
	
	q.xz *= mat2(vec2(c, s), vec2(-s, c));
	
	float sphere = sdSphere(q, .4);
	float box = sdBox(q, vec3(.3));
	float d = mix(sphere, box, sin(time * 2.));
//	d = min(q.y + 2., d);

	return d;
}

vec3 getNormal(vec3 p) {
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


float getDiffuse(vec3 normal, vec3 light) {
	return clamp(dot(normal, light), 0., 1.);
}

float getSpecular(vec3 normal, vec3 light, float power) {
	vec3 h = normalize(normal + light);
	return pow(max(dot(h, normal), 0.0), power);
}

float getShadow(vec3 p, vec3 light, float time) {
	vec3 delta = light - p;
	vec3 lightDirection = normalize(delta);
	vec3 normal = getNormal(p);
	float shadow = RayMarcher(p + lightDirection * 0.08, lightDirection, time);
	float diffuse = getDiffuse(normal, lightDirection);
	if (shadow < length(delta)) {
		diffuse *= .4;
	}
	return diffuse + .02;
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
		vec3 light = vec3(3., 5., 2.);
		vec3 lightDirection = normalize(light - p);
		vec3 normal = getNormal(p);
		float spec = getSpecular(normal, dr, 200.);
		float dif = getShadow(p, light, TIME);
		vec3 materialColor = vec3(.9, 0.35, .18);
		float amb = .02;
		c = materialColor * (dif + spec) + amb;
		
	}
	ALBEDO.xyz = c;
}