vec2 normalize_uv = vec2(0.1591, 0.3183);

vec2 sampleSphericalMap(vec3 v)
{
    // U is in the range [-PI, PI], V is [-PI/2, PI/2]
    vec2 uv = vec2(atan(v.z, v.x), asin(v.y));
    // Convert UV to [-0.5, 0.5] in U&V
    uv *= normalize_uv;
    // Convert UV to [0, 1]
    uv += 0.5;
    return uv;
}

vec3 sampleFromInsideSphere(vec2 xi, out float pdf)
{
    return vec3(0.);
}

#if N_AREA_LIGHTS
vec3 DirectSampleAreaLight(int idx,
                           vec3 view_point,
                           vec3 view_nor,
                           int num_lights,
                           out vec3 wiW,
                           out float pdf)
{
    AreaLight light = areaLights[idx];
    int type = light.shapeType;
    Ray shadowRay;

    if (type == RECTANGLE) {
        Transform lightXform = light.transform;

        vec4 point4d = vec4(rng() * 2.f - 1.f, rng() * 2.f - 1.f, 0.f, 1.f);
        vec3 p = (lightXform.T * point4d).xyz;

        vec3 lightNor = normalize(lightXform.invTransT * vec3(0.f, 0.f, 1.f));
        float cosTheta = dot(lightNor, -normalize(p - view_point));

        if (cosTheta <= 0.f) {
            pdf = 0.f;
            return vec3(0.f);
        }

        pdf = 1.f / (2.f * lightXform.scale.x * 2.f * lightXform.scale.y); // 1 / SurfaceArea
        float r = distance(p, view_point);

        pdf = pdf * r * r / cosTheta;

        wiW = normalize(p - view_point);

        shadowRay = SpawnRay(view_point, wiW);
        Intersection shadowIsect = sceneIntersect(shadowRay);
        if (shadowIsect.obj_ID != light.ID) {
            return vec3(0.f);
        }

        return light.Le * float(num_lights);

    } else if (type == SPHERE) {
        // To be supplied in a future assignment
    }

    return vec3(0.);
}
#endif

#if N_POINT_LIGHTS
vec3 DirectSamplePointLight(int idx, vec3 view_point, int num_lights, out vec3 wiW, out float pdf)
{
    PointLight light = pointLights[idx];

    wiW = light.pos - view_point;

    pdf = 1.f;

    Ray shadowRay = SpawnRay(view_point, normalize(light.pos - view_point));
    Intersection shadowIsect = sceneIntersect(shadowRay);

    float dist = distance(view_point, light.pos);
    if (shadowIsect.t <= dist) {
        return vec3(0.f);
    }

    return light.Le / (dist * dist) * float(num_lights);
}
#endif

#if N_SPOT_LIGHTS
vec3 DirectSampleSpotLight(int idx, vec3 view_point, int num_lights, out vec3 wiW, out float pdf)
{
    SpotLight light = spotLights[idx];
    // TODO hw03
    return vec3(0.);
}
#endif

vec3 Sample_Li(vec3 view_point, vec3 nor, out vec3 wiW, out float pdf)
{
    // Choose a random light from among all of the
    // light sources in the scene, including the environment light
    int num_lights = N_LIGHTS;

#define ENV_MAP 0
#if ENV_MAP
    int num_lights = N_LIGHTS + 1;
#endif
    int randomLightIdx = int(rng() * num_lights);

    // Chose an area light
    if (randomLightIdx < N_AREA_LIGHTS) {
#if N_AREA_LIGHTS
        return DirectSampleAreaLight(randomLightIdx, view_point, nor, num_lights, wiW, pdf);
#endif
    }
    // Chose a point light
    else if (randomLightIdx < N_AREA_LIGHTS + N_POINT_LIGHTS) {
#if N_POINT_LIGHTS
        return DirectSamplePointLight(randomLightIdx - N_AREA_LIGHTS,
                                      view_point,
                                      num_lights,
                                      wiW,
                                      pdf);
#endif
    }
    // Chose a spot light
    else if (randomLightIdx < N_AREA_LIGHTS + N_POINT_LIGHTS + N_SPOT_LIGHTS) {
#if N_SPOT_LIGHTS
        return DirectSampleSpotLight(randomLightIdx - N_AREA_LIGHTS - N_POINT_LIGHTS,
                                     view_point,
                                     num_lights,
                                     wiW,
                                     pdf);
#endif
    }
    // Chose the environment light
    else {
        // TODO
    }
    return vec3(0.);
}
