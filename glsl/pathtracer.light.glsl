
vec2 normalize_uv = vec2(0.1591, 0.3183);
vec2 sampleSphericalMap(vec3 v) {
    // U is in the range [-PI, PI], V is [-PI/2, PI/2]
    vec2 uv = vec2(atan(v.z, v.x), asin(v.y));
    // Convert UV to [-0.5, 0.5] in U&V
    uv *= normalize_uv;
    // Convert UV to [0, 1]
    uv += 0.5;
    return uv;
}

vec3 sampleFromInsideSphere(vec2 xi, out float pdf) {

    return vec3(0.);
}

#if N_AREA_LIGHTS
vec3 DirectSampleAreaLight(int idx,
                           vec3 view_point, vec3 view_nor,
                           out vec3 wiW, out float pdf) {
    int type = areaLights[idx].shapeType;
    Ray shadowRay;

    if(type == RECTANGLE) {
        // TODO
    }
    else if(type == SPHERE) {
        // To be supplied in a future assignment
    }

    Intersection isect = sceneIntersect(shadowRay);
    if(isect.obj_ID == areaLights[idx].ID) {
        // Multiply by N+1 to account for sampling it 1/(N+1) times.
        // +1 because there's also the environment light
        return (N_LIGHTS + 1) * areaLights[idx].Le;
    }
}
#endif

#if N_POINT_LIGHTS
vec3 DirectSamplePointLight(int idx,
                            vec3 view_point,
                            out vec3 wiW, out float pdf) {
    // TODO
    return vec3(0.);
}
#endif

#if N_SPOT_LIGHTS
vec3 DirectSampleSpotLight(int idx,
                           vec3 view_point,
                           out vec3 wiW, out float pdf) {
    // TODO
    return vec3(0.);
}
#endif

vec3 DirectLightSample(vec3 view_point, vec3 nor, out vec3 wiW, out float pdf) {
    // Choose a random light from among all of the
    // light sources in the scene, including the environment light
    int randomLightIdx = int(rng() * (N_LIGHTS + 1));
    // Chose an area light
    if(randomLightIdx < N_AREA_LIGHTS) {
#if N_AREA_LIGHTS
        return DirectSampleAreaLight(randomLightIdx, view_point, nor, wiW, pdf);
#endif
    }
    // Chose a point light
    else if(randomLightIdx < N_AREA_LIGHTS + N_POINT_LIGHTS) {
#if N_POINT_LIGHTS
        return DirectSamplePointLight(randomLightIdx - N_AREA_LIGHTS, view_point, wiW, pdf);
#endif
    }
    // Chose a spot light
    else if(randomLightIdx < N_AREA_LIGHTS + N_POINT_LIGHTS + N_SPOT_LIGHTS) {
#if N_SPOT_LIGHTS
        return DirectSampleSpotLight(randomLightIdx - N_AREA_LIGHTS - N_POINT_LIGHTS, view_point, wiW, pdf);
#endif
    }
    // Chose the environment light
    else {
        // TODO
    }
    return vec3(0.);
}

