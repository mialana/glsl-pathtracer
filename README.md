Path Tracer Part IV: Global Illumination
======================

**University of Pennsylvania, CIS 561: Advanced Computer Graphics, Homework 5**

Overview
------------
You will implement a new light integrator function: `Li_Full`. This integrator
will compute both the direct lighting and global illumination at each ray intersection
to produce a more converged image in a shorter period of
time. Compare the result of using `Li_Naive` to render the
basic Cornell Box scene to the result of using the `Li_Full`:

![](./images/readme-images/cornellBoxNaive.png) ![](./images/readme-images/cornellBoxFull.png)

Notice how the `Li_Full` result is much less noisy and a bit brighter; this is
because each ray path is much more likely to receive light from a light source
as each intersection directly samples a light.

Useful Reading
---------
Once again, you will find the textbook will be very helpful when implementing
this homework assignment. We recommend referring to the following chapters:
* 14.5: Path Tracing

The Light Transport Equation
--------------
#### L<sub>o</sub>(p, &#969;<sub>o</sub>) = L<sub>e</sub>(p, &#969;<sub>o</sub>) + &#8747;<sub><sub>S</sub></sub> f(p, &#969;<sub>o</sub>, &#969;<sub>i</sub>) L<sub>i</sub>(p, &#969;<sub>i</sub>) V(p', p) |dot(&#969;<sub>i</sub>, N)| _d_&#969;<sub>i</sub>

* __L<sub>o</sub>__ is the light that exits point _p_ along ray &#969;<sub>o</sub>.
* __L<sub>e</sub>__ is the light inherently emitted by the surface at point _p_
along ray &#969;<sub>o</sub>.
* __&#8747;<sub><sub>S</sub></sub>__ is the integral over the sphere of ray
directions from which light can reach point _p_. &#969;<sub>o</sub> and
&#969;<sub>i</sub> are within this domain.
* __f__ is the Bidirectional Scattering Distribution Function of the material at
point _p_, which evaluates the proportion of energy received from
&#969;<sub>i</sub> at point _p_ that is reflected along &#969;<sub>o</sub>.
* __L<sub>i</sub>__ is the light energy that reaches point _p_ from the ray
&#969;<sub>i</sub>. This is the recursive term of the LTE.
* __V__ is a simple visibility test that determines if the surface point _p_' from
which &#969;<sub>i</sub> originates is visible to _p_. It returns 1 if there is
no obstruction, and 0 is there is something between _p_ and _p_'. This is really
only included in the LTE when one generates &#969;<sub>i</sub> by randomly
choosing a point of origin in the scene rather than generating a ray and finding
its intersection with the scene.
* The __absolute-value dot product__ term accounts for Lambert's Law of Cosines.

Updating this README (5 points)
-------------
Make sure that you fill out this `README.md` file with your name and PennKey,
along with your test renders. You should render each of the new scenes we have
provided you, once with each integrator type. At minimum we expect renders using
the default sample count and recursion depth, but you are encouraged to try
rendering scenes with more samples to get nicer looking results.


`Li_Full`'s overall code body (10 points)
--------------
As with `Li_Naive`, `Li_Full` will use a `for` loop to iteratively bounce
your ray throughout the scene. This means you will once again need a `throughput`
variable to track how your light is dampened by the surfaces off of which your
ray scatters. Additionally, you will need an `accumulated_light` variable to track
the overall color sent back to your camera, since unlike in `Li_Naive` we will be
sampling our direct illumination at every intersection.

The structure of `Li_Full` will be similar to `Li_Naive`, but as we will discuss in
the next section there are some notable alterations and optimizations.

Computing the direct lighting component (25 points)
----------
To begin, we recommend that you write a function at the bottom of `pathtracer.light.glsl`
that returns the result of computing the multiple importance sampled direct light
at a particular intersection in your scene. This function will be nearly identical
to the body of your `Li_MISDirect`, but it should take in an already-computed point
of intersection rather than a `Ray` to intersect with the scene. You will probably want
additional function inputs, but we will leave it to you to determine what they might be
as you write the function.

In `Li_Full`, whenever your ray has intersected a diffuse or microfacet surface, you should
compute the multiple importance sampled direct light at that point. Then, you should add
that direct light to your `accumulated_light`, remembering to multiply the direct light by
your `throughput` to account for ray bounces past the first one.

Just like in your direct lighting `Li` functions, we are going to treat the direct
lighting contribution on specular surfaces as black. That is why we don't bother to
compute the MIS when we hit specular materials. Instead, you should have a boolean 
variable that tracks whether or not the surface your ray previously intersected was
specular; whenever this variable is `true`, you should add your next intersection's
`Le` to your `accumulated_light` (also remembering to multiply by `throughput`).
This way, you will still be able to see light sources reflected in mirrors, but won't
waste time computing MIS for specular surfaces when the direct-sampled half of MIS
never gives useful information.

__Note that this indicates that you should NOT add a
surface's `Le` to your accumulated light when your last intersection was NOT specular.__
This is because we already sampled the direct illumination on the surface with MIS, so
we would be doubly sampling it if we did add `Le`. There is a section later on in the
writeup that discusses this further.

As one final optimization, in your MIS computation, you should just return the
`Lo` of the direct-light-sampled &#969;<sub>i</sub> if the light chosen by `Sample_Li`
was a point light or spot light (you will want to add another `out` variable to
`Sample_Li` to determine this). Since a BSDF-sampled ray can never intersect a point
or spot light, it is __point__-less (haha) to use MIS in this case. 

Computing the ray bounce and global illumination (15 points)
-------
Separately from your direct lighting term, you should use an entirely new
2D uniform random variable to generate a new BSDF-based &#969;<sub>i</sub> using `Sample_f`.
This ray will be used to determine the direction of your
ray bounce and global illumination computation.
You will multiply the color obtained from `Sample_f` with
your ray throughput, along with the absolute-dot-product term and the 1/_pdf_
term. This effectively compounds the inherent material colors of all surfaces
this ray has bounced from so far, so that when we incorporate the lighting
this particular ray bounce receives _directly_, it is attenuated by __all__ of
the surfaces our ray has __previously__ hit. To this end, BEFORE you have updated
throughput, multiply it with the direct lighting term from above and
add the result to your accumulated ray color. We don't want to incorporate
our current intersection's material properties into the throughput as that would
double-count its coloring when combined with the direct light. Finally, make sure to update the
ray that your `for` loop is using to originate from your current
intersection and travel in the direction of the &#969;<sub>i</sub> that you
just computed.

Correctly accounting for direct lighting (10 points)
-------
Since your path tracer computes the direct lighting a given intersection
receives as its own term, your path tracer must __not__ include _too much_
light. This means that every ray which already computed the direct lighting term
should __not__ incorporate the `Le` term of the light transport equation into
its light contribution. In other words, unless a particular ray came directly
from the camera or from a perfectly specular surface, `Le` should be ignored.

Example Renders
-------
Once you have implemented `Li_Full`, you should be able to replicate these renders:

`PT_cornellBox.json`

![](./images/readme-images/cornellBoxFull.png)

`PT_cornellBoxSpotLight.json`

![](./images/readme-images/spotLightFull.png)

`PT_cornellBoxPointLight.json`

![](./images/readme-images/pointLightFull.png)

`PT_roughMirrorBoxUniform.json`

![](./images/readme-images/roughMirrorFull.png)

Environment lighting (10 points)
---------
In the `Sample_Li` function we provided you, there is a preprocessor
directive that currently disables sampling the scene's environment
light. Remove the directive so that your `num_lights` is equal to
`N_LIGHTS + 1`.

Then, fill out the body of the `else` statment in `Sample_Li` to allow
the environment map accessed via the `u_EnvironmentMap` `sampler2D` to
act as a light source. To do this, you should cosine-sample the hemisphere
at your intersection, then return the map's color at the UV coordinates
determined by the `sampleSphericalMap` function provided in
`pathtracer.defines.glsl`. Of course, make sure you perform a shadow test
to make sure your &#969;<sub>i</sub> can actually see the environment map.
Since the environment map is intended to fill the space where no objects exist
(allowing there to be something besides a black void), &#969;<sub>i</sub>
sees the environment map only if it hits nothing in your scene.

Additionally, make sure that whenever your `Ray` in `Li_Full` hits nothing
that you return the environment map's color instead of black so that you can
see it with your primary camera rays.

Below are some renders of various scenes with environment lighting enabled:

`PT_cornellBoxNoLights.json`

![](./images/readme-images/cornellBoxEnvMapNoLights.png)

`PT_cornellBox.json`

![](./images/readme-images/cornellBoxEnvMap.png)

`PT_mirrorBoxDemo.json`

![](./images/readme-images/mirrorBoxEnvMap.png)

`PT_roughMirrorBoxUniform.json`

![](./images/readme-images/roughMirrorEnv.png)


Custom scenes (30 points)
-----------
Since you are only implementing a new integrator this week, you will have time
available to design and render scenes of your own. Please create and
render __at least three__ unique scenes. They should not be variations on the
Cornell box! We want you to have unique material for your demo reel (and some
first-hand experience working with the JSON format we have made for scenes).
We expect each image to be a __minimum of 512x512 pixels__, but at least one
larger image is recommended for better demo reel quality. Make sure you take
your screenshots after letting the renderer converge for a while.

We ask that your custom scenes showcase the more visually impressive components
of your path tracer, such as a scene that includes a microfacet mirror surface
and several glass materials of various indices of refraction. Additionally,
texture maps, normal maps, and microfacet roughness maps are encouraged. You may
try to render scenes containing triangle meshes, but bear in mind that they will
take a while if your meshes have a high number of faces.

Extra credit (30 points maximum)
-----------
Choose any extra credit from a previous path tracer homework assignment and
implement it, provided of course that you did not previously do so. As always,
you are free to implement a feature not listed as extra credit if it is not a
required feature of some other assignment, e.g. a subsurface scattering BXDF.

Submitting your project
--------------
Along with your project code, make sure that you fill out this `README.md` file
with your name and PennKey, along with your test renders.

Rather than uploading a zip file to Canvas, you will simply submit a link to
the committed version of your code you wish us to grade. If you click on the
__Commits__ tab of your repository on Github, you will be brought to a list of
commits you've made. Simply click on the one you wish for us to grade, then copy
and paste the URL of the page into the Canvas submission form.

Path Tracer Part III: Multiple Importance Sampling and Microfacet Materials
======================

**University of Pennsylvania, CIS 561: Advanced Computer Graphics, Homework 4**

Overview
------------
You will implement another `Li` function in order to use multiple importance
sampling to better estimate the direct illumination received by points in your scene.
You will test this integrator on the provided Veach scene files, which incorporate
microfacet surfaces of varying roughness and light sources of varying size.

Provided Code
-------
We have provided you with updated and new files for your existing path tracer
base code. Please copy your existing files into the folder containing your `.pro` file,
but __DO NOT__ replace any of the files we have provided with this assignment.
For some of your files, you may have to add function implementations to
various files to make your project compile again. However, just to re-iterate,
it is vital that you __DO NOT__ replace any of the files we have given you
for this assignment.

Useful Reading
---------
Once again, you will find the textbook will be very helpful when implementing
this homework assignment. We recommend referring to the following chapters:
* 8.4: Microfacet Models
* 9.2: Material Interface and Implementations
* 13.10: Importance Sampling

The Light Transport Equation
--------------
#### L<sub>o</sub>(p, &#969;<sub>o</sub>) = L<sub>e</sub>(p, &#969;<sub>o</sub>) + &#8747;<sub><sub>S</sub></sub> f(p, &#969;<sub>o</sub>, &#969;<sub>i</sub>) L<sub>i</sub>(p, &#969;<sub>i</sub>) V(p', p) |dot(&#969;<sub>i</sub>, N)| _d_&#969;<sub>i</sub>

* __L<sub>o</sub>__ is the light that exits point _p_ along ray &#969;<sub>o</sub>.
* __L<sub>e</sub>__ is the light inherently emitted by the surface at point _p_
along ray &#969;<sub>o</sub>.
* __&#8747;<sub><sub>S</sub></sub>__ is the integral over the sphere of ray
directions from which light can reach point _p_. &#969;<sub>o</sub> and
&#969;<sub>i</sub> are within this domain.
* __f__ is the Bidirectional Scattering Distribution Function of the material at
point _p_, which evaluates the proportion of energy received from
&#969;<sub>i</sub> at point _p_ that is reflected along &#969;<sub>o</sub>.
* __L<sub>i</sub>__ is the light energy that reaches point _p_ from the ray
&#969;<sub>i</sub>. This is the recursive term of the LTE.
* __V__ is a simple visibility test that determines if the surface point _p_' from
which &#969;<sub>i</sub> originates is visible to _p_. It returns 1 if there is
no obstruction, and 0 is there is something between _p_ and _p_'. This is really
only included in the LTE when one generates &#969;<sub>i</sub> by randomly
choosing a point of origin in the scene rather than generating a ray and finding
its intersection with the scene.
* The __absolute-value dot product__ term accounts for Lambert's Law of Cosines.

Updating this README (5 points)
-------------
Make sure that you fill out this `README.md` file with your name and PennKey,
along with your test renders. You should render each of the new scenes we have
provided you, once with each integrator type. At minimum we expect renders using
the default sample count and recursion depth, but you are encouraged to try
rendering scenes with more samples to get nicer looking results.

Microfacet BRDFs 
-------------
We have provided an implementation of the `f_microfacet_refl` function for you. If you want
to see how these materials interact with light, try rendering
`PT_roughMirrorBoxUniform.json` using your `Li_Naive`:

![](./images/readme-images/roughMirror_naive.png)

`Pdf_Li` function (5 points)
---------
Complete the implementation of the `Pdf_Li` function newly provided in `pathtracer.light.glsl`.
This function should return the PDF of a given light source when viewed from `view_point` along
`wiW`. In other words, it computes the same kind of PDF that `Sample_Li` does, but doesn't do any
additional computations.

You will need to use this function when implementing your new `Li` integrator in order to compute
one of the PDFs needed to evaluate multiple importance sampling.

`Li_DirectMIS` Function (80 points)
-----------
One of the main components of this homework assignment is to write an integrator
that implements __multiple importance sampling__ to more effectively estimate
the direct illumination within a scene containing light sources of different
sizes and materials of different glossiness. In `pathtracer.frag.glsl`,
you will write a new function called `Li_DirectMIS` that will generate __two__
direct lighting sample rays. One ray will be the
same as before: a ray that travels directly to a point on the chosen light
source. The other light sample ray will generated using the BSDF sampling
technique used in your `Li_Naive`, except __it will only return light color
if it intersects the light source you chose to sample__. You will then weight each
of these energy samples according to the Power Heuristic and average them
together to produce an overall sample color. Note that the BSDF-sampled ray is
__not__ a recursive ray as it was in the `NaiveIntegrator`, but just another
direct illumination sampling ray.

Remember, you will need __four__ distinct PDF values in order to evaluate the
Power Heuristic:
- The PDF of your light-sampled ray with respect to that light
- The PDF of your light-sampled ray with respect to your intersection's BSDF
- The PDF of your BSDF-sampled ray with respect to your intersection's BSDF
- The PDF of your BSDF-sampled ray with respect to the light you chose with your
light source sampling

Power Heuristic (10 points)
----------
At the bottom of `pathtracer.light.bsdf`, you will find the declaration of
the `PowerHeuristic` function. Implement this function so it can be used in
your implementation of `Li_DirectMIS`.

MIS Example Renders
--------
Each of the images below was produced using multiple importance sampling.

`PT_cornellBoxTwoLights.json`

![](./images/readme-images/cornellBoxTwoLightsMIS.png)

`PT_roughMirrorBoxUniform.json`

![](./images/readme-images/roughMirror_MIS.png)

Veach Scene Examples
------
Here are renders of `PT_veachScene.json` using `Li_Naive`, `Li_DirectSimple`, and `Li_DirectMIS`:

`Li_Naive`

![](./images/readme-images/veach_naive.png)

`Li_DirectSimple`

![](./images/readme-images/veach_direct.png)

`Li_DirectMIS`

![](./images/readme-images/veach_mis.png)

Extra credit (30 points maximum)
-----------
In addition to the features listed below, you may choose to implement __any
feature you can think of__ as extra credit, provided you propose the idea to the
course staff through Piazza first.

__You must provide renders of your implemented features to receive credit for
them.__

#### Microfacet BTDF Functions (20 points)
Implement a BTDF that uses a microfacet distribution to generate its sample
rays. You will also have to add a new `Material` type to support this BxDF.

You will also have to
add code to the `JSONLoader` class in order to load and render a scene that uses
this new material.

#### Custom scene (10 points)
Now that you have implemented several different BSDFs and have written an
efficient global illumination integrator, you should try to create a customized
JSON scene of your own to render. We encourage everyone to be creative so you
all have unique material for your demo reels. Note that a custom scene that
includes one of the extra credit features listed above is a requirement of
those features implicitly; you must create an entirely novel scene (i.e. not
a variation on the Cornell box) to receive this extra credit.

Submitting your project
--------------
Along with your project code, make sure that you fill out this `README.md` file
with your name and PennKey, along with your test renders.

Rather than uploading a zip file to Canvas, you will simply submit a link to
the committed version of your code you wish us to grade. If you click on the
__Commits__ tab of your repository on Github, you will be brought to a list of
commits you've made. Simply click on the one you wish for us to grade, then copy
and paste the URL of the page into the Canvas submission form.

Path Tracer Part II: Direct Lighting Estimation and Specular Materials
======================

**University of Pennsylvania, CIS 561: Advanced Computer Graphics, Homework 3**

Overview
------------
You will implement two distinct components for your path tracer: a new `Li` function
to estimate the direct lighting in a scene by sampling points
on light surfaces, and a collection of BSDFs to handle specular reflective and
transmissive materials. You may implement and test these features in any order
you see fit.

Setting up your code
-----------
In order to have access to all of the skeleton code, you must copy the contents of this repository's `src` folder into your Qt project's `src` folder. The same goes for the provided `glsl` folder. Also make sure that you then copy your Qt project into this Git repository so you can properly commit it.

Useful Reading
---------
Once again, you will find the textbook will be very helpful when implementing
this homework assignment. We recommend referring to the following chapters:
* 5.5: Working With Radiometric Integrals
* 8.2: Specular Reflection and Transmission
* 14.1.3: Specular Reflection and Transmission
* 14.2: Sampling Light Sources
* 14.3: Direct Lighting

The Light Transport Equation
--------------
#### L<sub>o</sub>(p, &#969;<sub>o</sub>) = L<sub>e</sub>(p, &#969;<sub>o</sub>) + &#8747;<sub><sub>S</sub></sub> f(p, &#969;<sub>o</sub>, &#969;<sub>i</sub>) L<sub>i</sub>(p, &#969;<sub>i</sub>) V(p', p) |dot(&#969;<sub>i</sub>, N)| _d_&#969;<sub>i</sub>

* __L<sub>o</sub>__ is the light that exits point _p_ along ray &#969;<sub>o</sub>.
* __L<sub>e</sub>__ is the light inherently emitted by the surface at point _p_
along ray &#969;<sub>o</sub>.
* __&#8747;<sub><sub>S</sub></sub>__ is the integral over the sphere of ray
directions from which light can reach point _p_. &#969;<sub>o</sub> and
&#969;<sub>i</sub> are within this domain.
* __f__ is the Bidirectional Scattering Distribution Function of the material at
point _p_, which evaluates the proportion of energy received from
&#969;<sub>i</sub> at point _p_ that is reflected along &#969;<sub>o</sub>.
* __L<sub>i</sub>__ is the light energy that reaches point _p_ from the ray
&#969;<sub>i</sub>. This is the recursive term of the LTE.
* __V__ is a simple visibility test that determines if the surface point _p_' from
which &#969;<sub>i</sub> originates is visible to _p_. It returns 1 if there is
no obstruction, and 0 is there is something between _p_ and _p_'. This is really
only included in the LTE when one generates &#969;<sub>i</sub> by randomly
choosing a point of origin in the scene rather than generating a ray and finding
its intersection with the scene.
* The __absolute-value dot product__ term accounts for Lambert's Law of Cosines.

Debugging Tips
========
Since your code executes entirely on the GPU, you will be unable to use breakpoints to debug it. Furthermore, any GLSL compiler errors you get will be printed in your Application Output window rather than the compiler errors tab. Here are some tips for debugging your project:
- Run your program early and often! If you try to implement every feature, only to run your program and get dozens of GLSL compiler errors, you will not have fun trying to track them all down!
- Refer to the auto-generated `pathtracer.all.glsl` file to determine the lines of code that are causing GLSL compiler errors. Just don't make the mistake of editing this file as it is not read by the GLSL compiler; it is just generated for your convenience.
- It's always helpful to debug numeric values by setting the Red, Green, and/or Blue channel of a pixel to some number you wish to debug. For instance, you can debug a ray direction by returning it as a color (making sure to remap it to the range [0, 1] first).


Specular BRDFs (10 points)
-----------
You must implement the `Sample_f_specular_refl` function found in `pathtracer.bsdf.glsl`.
Since this BRDF is perfectly specular, this function should generate &#969;<sub>i</sub>
by reflecting &#969;<sub>o</sub> about the surface normal. Remember, `Sample_f` remaps
&#969;<sub>o</sub> into local tangent space (the surface normal is assumed to be aligned
with the Z axis), so computing &#969;<sub>i</sub> is trivial and does not even need GLSL's
`reflect` function. Note that we have already "implemented" the specular cases of `f` and `Pdf` for you; these both return 0. This is because we will assume that &#969;<sub>i</sub> has a zero
percent chance of being randomly set to the exact mirror of &#969;<sub>o</sub> by any other
`BxDF`'s `Sample_f`, hence a PDF of zero.

You can test if your Specular BRDF implementation works by rendering
`PT_mirrorBox.json` using your `Li_Naive` function. Your image should look like this:

![](./images/readme-images/NaiveMirrorBox.png)

Specular BTDFs (15 Points)
-------------
Like `Sample_f_specular_refl`, you must implement `Sample_f_specular_trans`.
This function is a little more involved, however, as
you not only must generate &#969;<sub>i</sub> by refracting &#969;<sub>o</sub>,
but you must also check for total internal reflection and return black if it
would occur. Remember, this function only handles transmission, so it should not
compute the color that would be returned by total internal reflection if it were
to be simulated. You must also make sure to check whether your ray is entering
or leaving the object with which it has intersected; you can do this by
comparing the direction of &#969;<sub>o</sub> to the direction of your normal
(remember, you are in tangent space so this is pretty easy). If your ray is
leaving a transmissive object, you should compute its index of refraction as
etaB / etaA rather than the other way around.

Also note, we have provided a `Refract` function in `pathtracer.defines.glsl`
for your convenience.

You can test if your `Sample_f_specular_trans` implementation works by rendering
`PT_transmitBox.json` with `Li_Naive`. Your image should look like this:

![](./images/readme-images/NaiveTransmitBox.png)

Handling dielectric materials (8 points)
------------
In `pathtracer.bsdf.h` you will find a function named `FresnelDielectricEval`.
This function is intended to compute the Fresnel reflection coefficient at a given
point of intersection on a surface. For surfaces that are less physically accurate, such
as entirely reflective and entirely transmissive ones, we skip computing this coefficient
and instead hard-code it to 1 (reflective) or 0 (transmissive). For more physically
accurate materials, such as glass, `FresnelDielectricEval` must be used to evaluate the
Fresnel reflection coefficient. Implement this function so that it
correctly computes how reflective a surface point on a dielectric material
should be given its indices of refraction and the angle between the incident ray
and the surface normal.

You can test if your `FresnelDielectricEval` implementation works by rendering
`PT_glassBallBox.json` with `Li_Naive`. Your image should look like this:

![](./images/readme-images/NaiveGlassBallBox.png)

`Li_Direct_Simple` function (30 points)
----
You will write another `Li` function in `pathtracer.frag.glsl`, this time so
that it performs light source importance sampling and evaluates the light energy that a
given point receives __directly__ from light sources. That means that this function's
ray will bounce only once. Much of the code in this
`Li` is the same as the code you wrote for `Li_Naive`, but
rather than calling `Sample_f` to generate a &#969;<sub>i</sub>, you
will instead call the `Sample_Li` function found in `pathtracer.light.glsl`.
Once you have done this, you can evaluate the remaining components of
the Light Transport Equation (you will already have Li, &#969;<sub>i</sub>, and your PDF).
`Sample_Li` invokes a few additional functions that you will have to implement; we will detail them below. 

`Sample_Li` functions
------
In `pathtracer.light.glsl`, you will find a function called `Sample_Li`. This
function takes in the location of an intersection, and that intersection's normal,
and outputs the energy of a light source viewed along a computed &#969;<sub>i</sub>
and its corresponding PDF. &#969;<sub>i</sub> will be chosen by sampling a random point
on a randomly-selected light source and computing the vector from the view point to that
point. We have filled in the body for you; it already chooses a light source at random
from the set of all light sources in the scene and invokes the appropriate function
to sample that light. Below are their descriptions.

`DirectSampleAreaLight` (12 points)
----
You must implement the `DirectSampleAreaLight` function to perform several actions:
* Compute a random point on the surface of the AreaLight indicated by `idx`, making use
of the light source's `Transform` and the `rng` function. You may assume that an untransformed
rectangular area light has a surface normal of `(0,0,1)`, a side length of 2, and is centered at the origin (i.e. its X and Y coords span the range [-1, 1]).
* Compute the PDF of the chosen point with respect to the area of the AreaLight
* Convert the PDF to be with respect to the light source's solid angle projection
on `view_point`.
* Set &#969;<sub>i</sub> to the normalized vector from the reference
 point to the generated light source point.
* Check to see if &#969;<sub>i</sub> reaches the light source, or if it intersects
another object along the way. If there is an occluder, return black.
* Return the light emitted along &#969;<sub>i</sub>, making sure to scale it by `num_lights`
to account for the fact that a given light source is only sampled `1/num_lights` times on average.

`DirectSamplePointLight` (10 points)
----
You must implement the `DirectSamplePointLight` function to perform several actions:
* Generate &#969;<sub>i</sub> by normalizing a vector from `view_point` to the light source's
position.
* Set the PDF equal to the nonzero value of a Dirac Delta Distribution, since our &#969;<sub>i</sub>
is guaranteed to go towards our light
* Find the intersection of a shadow feeler ray with your scene. If the point of intersection has a
`t` value greater than the distance between `view_point` and the light, then the light is NOT occluded.
* Return black if occluded, or the light's `Le` divided by the squared distance between it and
`view_point` if not occluded.
* Remember to scale your light energy proportional to the number of lights in the scene!

If you render `PT_cornellBoxPointLight.json` with `Li_Direct`, your scene should look like this:

![](./images/readme-images/DirectCornellBoxPointLight.png)

`DirectSampleSpotLight` (10 points)
----
This function is almost identical to `DirectSamplePointLight`, with a few exceptions:
* An untransformed spot light is assumed to lie at the origin and point along the Z axis.
* Only `view_point`s that lie within the spot light's `outerAngle` receive light energy.
* `view_point`s that lie between the spot light's `innerAngle` and `outerAngle` receive reduced
light energy. The amount of reduction is a cubic falloff; you should use `smoothstep` with the
inner and outer angles as its edge arguments, and `view_point`'s relative angle as its `x` argument.

If you render `PT_cornellBoxSpotLight.json` with `Li_Direct`, your scene should look like this:

![](./images/readme-images/DirectCornellBoxSpotLight.png)

Direct Lighting Example Renders
--------
Once you have implemented the `Li_Direct_Simple` and all its requisite
functions, you should be able to produce the following image by rendering
the default scene:

![](./images/readme-images/DirectCornellBox.png)

You should also render `PT_cornellBoxTwoLights.json` to make sure you've remembered to scale
your direct light samples correctly:

![](./images/readme-images/DirectCornellBoxTwoLights.png)

In contrast, should you render this scene with the Naive Integrator, you should
see the following image instead:

![](./images/readme-images/NaiveCornellBox.png)

Consider asking yourself why the second image is so much noisier than the
first.

Updating this README (5 points)
-------------
Make sure that you fill out this `README.md` file with your name and PennKey,
along with your test renders. You should render each of the scenes we have
provided you, once with each integrator type. At minimum we expect renders using
the default sample count and recursion depth, but you are encouraged to try
rendering scenes with more samples to get nicer looking results.

Extra credit (30 points maximum)
-----------
In addition to the features listed below, you may choose to implement __any
feature you can think of__ as extra credit, provided you propose the idea to the
course staff through Piazza first.


#### Conductive Materials' Fresnel Reflectance (8 points)
Implement a `FresnelConductorEvaluate` function to compute
the Fresnel reflectance coefficients for metallic surfaces. Unlike the
`FresnelDielectricEvaluate` function, `FresnelConductorEvaluate` evaluates an entire color for its
reflectance coefficient rather than a single float.

#### `Spectrum` struct (20 points)
In order to more accurately represent the reflectance of metals, we should use
a model of representing color that accounts for all wavelengths of light rather
than just the red, green, and blue channels. To this end, implement a `Spectrum`
struct that stores bins of light energy wavelengths and is capable of converting
this data to a single `vec3`.

Submitting your project
--------------
Along with your project code, make sure that you fill out this `README.md` file
with your name and PennKey, along with your test renders.

Rather than uploading a zip file to Canvas, you will simply submit a link to
the committed version of your code you wish us to grade. If you click on the
__Commits__ tab of your repository on Github, you will be brought to a list of
commits you've made. Simply click on the one you wish for us to grade, then copy
and paste the URL of the page into the Canvas submission form.

Path Tracer Part I: Naive Integration, Sampling Functions, and Diffuse Materials
======================

**University of Pennsylvania, CIS 561: Advanced Computer Graphics, Homework 2**

Overview
------------
This homework assignment marks the beginning of your implementation of a Monte Carlo
path tracer. You will work within two code bases for this assignment. The first
allows you to test a collection of functions that allow you to generate sample
points in a variety of domains. Sampling the surfaces of different shapes is very
important in a path tracer; not only does one have to cast rays in random
directions within a hemisphere, but if one wants to sample rays to area
lights, one needs to sample points on the surfaces of these lights.

The second code base is the actual path tracer code you will work with
for the next few weeks. You will implement a na&#239;ve Monte Carlo path
tracer by writing functions to generate random ray samples within a
hemisphere so that you can compute the lighting a surface intersection receives.
You will also implement the bidirectional scattering distribution function of
a simple Lambertian diffuse material. The most important
part of this assignment is reading through the base code and understanding how
all of the path tracer's components work together to produce an image.

Useful Reading
---------
You will find the textbook to be very helpful when implementing
this homework assignment. We recommend referring to the following chapters:
* 7.1 - 7.3: Sampling and Reconstruction
* 8.1: Basic Reflection Interface
* 8.3: Lambertian Reflection
* 9.1: BSDF
* 9.2: Material and Interface Implementations
* 5.4: Radiometry
* 13.1 - 13.3: Monte Carlo Integration

The Light Transport Equation
--------------
#### L<sub>o</sub>(p, &#969;<sub>o</sub>) = L<sub>e</sub>(p, &#969;<sub>o</sub>) + &#8747;<sub><sub>S</sub></sub> f(p, &#969;<sub>o</sub>, &#969;<sub>i</sub>) L<sub>i</sub>(p, &#969;<sub>i</sub>) V(p', p) |dot(&#969;<sub>i</sub>, N)| _d_&#969;<sub>i</sub>

* __L<sub>o</sub>__ is the light that exits point _p_ along ray &#969;<sub>o</sub>.
* __L<sub>e</sub>__ is the light inherently emitted by the surface at point _p_
along ray &#969;<sub>o</sub>.
* __&#8747;<sub><sub>S</sub></sub>__ is the integral over the sphere of ray
directions from which light can reach point _p_. &#969;<sub>o</sub> and
&#969;<sub>i</sub> are within this domain.
* __f__ is the Bidirectional Scattering Distribution Function of the material at
point _p_, which evaluates the proportion of energy received from
&#969;<sub>i</sub> at point _p_ that is reflected along &#969;<sub>o</sub>.
* __L<sub>i</sub>__ is the light energy that reaches point _p_ from the ray
&#969;<sub>i</sub>. This is the recursive term of the LTE.
* __V__ is a simple visibility test that determines if the surface point _p_' from
which &#969;<sub>i</sub> originates is visible to _p_. It returns 1 if there is
no obstruction, and 0 is there is something between _p_ and _p_'. This is really
only included in the LTE when one generates &#969;<sub>i</sub> by randomly
choosing a point of origin in the scene rather than generating a ray and finding
its intersection with the scene.
* The __absolute-value dot product__ term accounts for Lambert's Law of Cosines.

Updating this README (5 points)
-------------
Make sure that you fill out the beginning of this `README.md` file with your name and PennKey,
along with your example screenshots. You should take screenshots of your OpenGL window with each of the provided scenes rendered.

Debugging Tips
========
Since your code executes entirely on the GPU, you will be unable to use breakpoints to debug it. Furthermore, any GLSL compiler errors you get will be printed in your Application Output window rather than the compiler errors tab. Here are some tips for debugging your project:
- Run your program early and often! If you try to implement every feature, only to run your program and get dozens of GLSL compiler errors, you will not have fun trying to track them all down!
- Refer to the auto-generated `pathtracer.all.glsl` file to determine the lines of code that are causing GLSL compiler errors. Just don't make the mistake of editing this file as it is not read by the GLSL compiler; it is just generated for your convenience.
- It's always helpful to debug numeric values by setting the Red, Green, and/or Blue channel of a pixel to some number you wish to debug. For instance, you can debug a ray direction by returning it as a color (making sure to remap it to the range [0, 1] first).

Warp Functions Code
===================
In order to fully complete the path tracer portion of this assignment, you
will need to implement some sample warping functions. The `sample_warping`
folder contains base code that will help you visualize and test your
sampling implementations. Below are descriptions of the functions you
will need to implement in this code.

Square Sampling Functions (10 points)
--------
In `sampler.cpp`, you will find a function called `generateSamples`. In this
function, fill out the switch statement cases for generating grid-aligned
samples and stratified samples. Each of the samples generated should fall within
the range [0, 1) on the X and Y axes. You may refer to the method used to
generate purely random samples to see how to use the provided `rng32` random
number generator. The [PCG web site](http://www.pcg-random.org/) goes into
detail as to why the RNG32 is a superior random number generator to, say,
`std::rand()`.

Sample Warping Functions (25 points)
------
In `warpfunctions.cpp`, you will find a collection of functions that throw
runtime exceptions:
* `squareToDiskUniform`
* `squareToDiskConcentric`
* `squareToSphereUniform`
* `squareToHemisphereUniform`
* `squareToHemisphereCosine`

Replace the runtime exceptions with code that takes the input square sample and
warps it to the surface of the shape indicated by the function name. For the
disk warp functions, there are two implementations. For
`squareToDiskUniform`, implement a "polar" mapping where one square axis maps
to a disc radius and the other axis maps to an angle on the disc. For
`squareToDiskConcentric`, implement [Peter Shirley's warping method](https://pdfs.semanticscholar.org/4322/6a3916a85025acbb3a58c17f6dc0756b35ac.pdf)
that better preserves relative sample distances.

Likewise, there are two implementations for hemisphere sampling. Unlike the disc
sampling functions, these methods are meant to have very different distributions
of samples. For `squareToHemisphereUniform`, you must distribute all square
samples uniformly across the hemisphere surface. For `squareToHemisphereCosine`,
you must bias the warped samples toward the pole of the hemisphere and away from
the base.

If you refer to `utils.h`, you will find some useful values defined, such as
`INV_PI`, which make your computations slightly faster.

__Note that you do NOT need to implement the sphere cap warping function for this
assignment.__

Sample Warping Probability Density Functions (10 points)
-------------
As you implemented the warping functions above, you likely noticed additional
functions with the suffix `PDF`. You must implement these functions so that they
return the result of the probability density function associated with each
warping method, using the sample point as input to the PDF. Note that most of
the PDFs will return a constant value regardless of the input point, but some
of them _are_ dependent on it. Once you have implemented all of the sample
warping functions, you can test your PDF implementations by pressing the button
at the bottom of the GUI. Each of your PDFs should evaluate to approximately
1.0, by definition.

Example Images
-------------
Below are images of the images you should expect to generate using 1024 samples
and, unless otherwise noted, grid sampling. Some of the images have had their
camera moved for better illustration of point distribution.

Grid Sampling

![img](./images/readme-images/grid.png)

Stratified Sampling

![img](./images/readme-images/stratified.png)

Disc Warping (Uniform)

![img](./images/readme-images/discunif.png)

Disc Warping (Concentric)

![img](./images/readme-images/diskcon.png)

Sphere

![img](./images/readme-images/sphere.png)

Hemisphere (Uniform)

![img](./images/readme-images/hemiunif.png)

Hemisphere (Cosine Weighted)

![img](./images/readme-images/hemicos.png)

Path Tracer Code
===============
Once you have implemented your sample warping functions, you can copy
your implementations of the functions in `warpfunctions.cpp` into 
`pathTracer.sampleWarping.glsl`. You will have to modify them slightly
to fit with GLSL types, but the math logic will be the same.

The path tracer base code is quite extensive, and you will need to spend
some time reading through it to understand what you're working with. There
are more files provided in the base code than we will work with for this homework;
the following is a list of classes, functions, and files that you __will__
need to examine in order to understand this assignment:
- `noOp.frag.glsl`
- `pathTracer.frag.glsl`
        - `Li_Naive()`
        - `main()`
- `pathTracer.bsdf.glsl`
        - `f_diffuse()`
        - `Sample_f_diffuse()`
- `pathTracer.sampleWarping.glsl`

Intersection functions
------------
We have provided you with implementations of various shape intersection functions, defined in `pathtracer.intersection.glsl`. Since you implemented ray-scene, ray-sphere, and ray-square intersection in homework 1, we felt it was simpler to provide you with intersection functionality in this assignment so as to reduce your search space when debugging your code. Feel free to read through this section of code in order to better understand how the provided functions work.

BSDFs
-----
You will find all of the functions used to evaluate BSDF properties in `pathtracer.bsdf.glsl`. For this homework assignment, you will just be implementing the BRDF of perfectly diffuse materials.

We have provided thoroughly-commented implementations of the `BSDF` evaluating functions
`f()`, `Sample_f()`, and `Pdf()`. Make sure you read through them
to understand what they each do.

Lambertian BRDFs (15 points)
------------
At the top of `pathtracer.bsdf.glsl`, you will find `f_diffuse()` and `Sample_f_diffuse()`. At the bottom of this file, you will also find a `TODO` comment inside `Pdf()`. For each of these functions, implement the appropriate representation of a Lambertian material. For `Sample_f()`, this means implementing cosine-weighted hemisphere sampling to generate `wi`, since while diffuse surfaces scatter light uniformly in the hemisphere, they are still affected by Lambert's Law of Cosines.

If you'd like to test your Lambertian `Sample_f` implementation, once you've begun your implementation of `Li_Naive`, you can output your `wi` direction as color (make sure to remap it from [-1, 1] to [0, 1]):

![img](./images/readme-images/cornellBoxLambertSample_fAsColor.png)

Implementing `Li_Naive` (30 points)
-------------
Within `pathtracer.frag.glsl`, you will find the `Li_Naive` function. This function should iteratively evaluate the energy emitted from the scene along a ray path back to the camera. It must find the interection of the input ray with the scene and evaluat the result of the light transport equation at the point of intersection.

Below is a list of functions and variables you will find useful while implementing `Li_Naive`:
- `sceneIntersect()`, found in `pathtracer.intersection.glsl`
- `Intersection.Le`. `Intersection` is defined in `pathtracer.defines.glsl`.
- `Intersection.material`
- `SpawnRay()`, defined in `pathtracer.defines.glsl`.
- `Sample_f()`, defined in `pathtracer.bsdf.glsl`.
- `MAX_DEPTH`, defined in `pathtracer.defines.glsl`

Additionally, here is a list of code elements you should use when implementing `Li_Naive`:
- A `vec3` you use to accumulate your ray's light energy as it bounces
- A `vec3` you use to track your ray's throughput as it bounces
- A `for` loop that iteratively bounces your ray through the scene (there is a `MAX_DEPTH` defined in `pathTracer.defines.glsl`).

Note that if the intersection with
the scene is on an object with any `Le` greater than 0, then `Li_Naive` should only
evaluate and return the light emitted directly from the intersection.

For this assignment, you only need to handle intersections whose material type is `DIFFUSE_REFL`. We will handle additional material types in future assignments.

At this point, you can produce a render, but it will only ever be a single sample per pixel of your scene. If you render the Cornell Box scene provided, it will look something like this:

![img](./images/readme-images/onePassCornell.png)

Summing up render passes in `main` (5 points)
------------
In order to produce a render that converges, you will need to add code to `main` that combines your just-computed render iteration with all of the previously computed iterations. The previous iterations are all stored in the `sampler2D` `u_AccumImg`. Use the weighted averaging method we discussed in class using the `mix` function to combine these two colors, and output their combined value. Now, after letting your Cornell Box scene converge for a few seconds, it should look something like this:

![img](./images/readme-images/cornellBoxNoHDR.png)

High Dynamic Range conversion (5 points)
---------
You are still missing one crucial step in making your image physically accurate. Within `noOp.frag.glsl`, there is a pair of comments referring to the Reinhard operator and gamma correction. You must take your render, which has its colors stored as high dynamic range RGB values, and convert it to standard RGB range by first applying the Reinhard operator to its colors then gamma correcting them. Once you have done this, your render should look like this:

![img](./images/readme-images/cornellBoxNaive.png)

Extra credit (30 points maximum)
-----------
In addition to the features listed below, you may choose to implement __any
feature you can think of__ as extra credit, provided you propose the idea to the
course staff through Piazza first.

#### Lambertian Transmission BTDF (5 points)
Implement a `Material` type `DIFFUSE_TRANS` which implements a Lambertian __transmission__ model. This is virtually identical to
a Lambertian reflection model, but the hemisphere in which rays are sampled is
on the other side of the surface normal compared to the hemisphere of Lambertian
reflection.

Submitting your project
--------------
Along with your project code, make sure that you fill out this `README.md` file
with your name and PennKey, along with your test renders.

Rather than uploading a zip file to Canvas, you will simply submit a link to
the committed version of your code you wish us to grade. If you click on the
__Commits__ tab of your repository on Github, you will be brought to a list of
commits you've made. Simply click on the one you wish for us to grade, then copy
and paste the URL of the page into the Canvas submission form.
