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

        if (isect.t == INFINITY) {
            break;
        }

        if (length(isect.Le) > 0.f) {
            Lo += isect.Le * throughput;
            break;
        }

        vec3 woW = -ray.direction;     // in
        vec2 xi = vec2(rng(), rng());  // in

        vec3 wiW;                      // out
        float pdf;                     // out
        int sampledType;               // out

        vec3 bsdf = Sample_f(isect, woW, xi, wiW, pdf, sampledType);

        if (pdf <= 0.f) {
            break;
        }

        float lambertTerm = max(0.f, AbsDot(wiW, isect.nor));
        vec3 thisIterThroughput = (bsdf * lambertTerm) / pdf;

        throughput *= thisIterThroughput;

        // generate next ray
        vec3 pPrime = ray.origin + ray.direction * isect.t;
        ray = SpawnRay((ray.origin + (isect.t * ray.direction)) + (isect.nor * RayEpsilon), wiW);
    }

    return Lo;
}

void main()
{
    seed = uvec2(u_Iterations, u_Iterations + 1) * uvec2(gl_FragCoord.xy);

    Ray ray = rayCast();

    vec3 thisIterationColor = Li_Naive(ray);

    vec3 accumulatedColor = mix(texture(u_AccumImg, fs_UV).rgb,
                                thisIterationColor,
                                1.f / float(u_Iterations));

    out_Col = vec4(accumulatedColor, 1.f);
}
