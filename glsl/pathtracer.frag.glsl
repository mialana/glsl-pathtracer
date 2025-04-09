const float FOVY = 19.5f * PI / 180.0;

Ray rayCast()
{
    vec2 offset = vec2(rng(), rng());
    vec2 ndc = (vec2(gl_FragCoord.xy) + offset) / vec2(u_ScreenDims);
    ndc = ndc * 2.f - vec2(1.f);

    float aspect = u_ScreenDims.x / u_ScreenDims.y;
    vec3 ref = u_Eye + u_Forward;
    vec3 V = u_Up * tan(FOVY * 0.5);
    vec3 H = u_Right * tan(FOVY * 0.5) * aspect;
    vec3 p = ref + H * ndc.x + V * ndc.y;

    return Ray(u_Eye, normalize(p - u_Eye));
}

// Procedure:
// 1. Check where ray intersects. Account for if hit light or nothing.
// 2. Compute LTE, where `ray` is the incoming ray.
// 3. Sample a new ray bounce and iterate again.

// Find one Li using an iterative form of raytracing.
vec3 Li_Naive(Ray ray)
{
    vec3 Lo = vec3(0.f);
    // keeps track of the light energy being passed at each bounce of the ray.
    vec3 throughput = vec3(1.f);  // necessary for when surfaces can be emissive as well.

    for (int i = 0; i < MAX_DEPTH; i++) {
        Intersection isect = sceneIntersect(ray);
        vec3 currLe;

        if (isect.t == INFINITY) {
            break;
        }
        currLe = isect.Le;

        if (length(currLe) > 0.f) {
            // Lo += currLe * throughput;
            Lo = vec3(1.f);
            break;
        }
        Lo = vec3(isect.t / 100.f);

        vec3 p = ray.origin;
        vec3 wo = -ray.direction;
        vec3 wi;
        float pdf;


        vec3 nor = isect.nor;
        Lo = nor;




    }

    return Lo;
}

void main()
{
    seed = uvec2(u_Iterations, u_Iterations + 1) * uvec2(gl_FragCoord.xy);

    Ray ray = rayCast();

    // TODO: Implement Li_Naive
    vec3 thisIterationColor = Li_Naive(ray);

    // TODO: Set out_Col to the weighted sum of thisIterationColor
    // and all previous iterations' color values.
    // Refer to pathtracer.defines.glsl for what variables you may use
    // to acquire the needed values.

    // out_Col = vec4(0.5 * (ray.direction + vec3(1.)), 1.);

    out_Col = vec4(thisIterationColor, 1.);
}
