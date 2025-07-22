# GLSL Pathtracer

![img](images/readme-images/thumbnail.png)

**[Demo Video](https://youtu.be/pW9bWNrxd6Y)**

### Overview

A GLSL-based application to showcase different rendering methods associated with the Monte Carlo Light Transport algorithm.

### Build Instructions

The easiest way to get this program running is to use an IDE like QT Creator and select the project root file at `shaderPathtracer.pro`.

### Hardware Compatibility

Note, any JSON scenes that contains an OBJ file reference will fail to load on MacOS (due to GPU limitations).

### Results

Naive Integrator:

![img](./images/compiled-results-diagrams/naive_results.png)

Direct Simple Integrator:

![img](./images/compiled-results-diagrams/directsimple_results.png)

Direct MIS Integrator:

![img](./images/compiled-results-diagrams/directmis_results.png)

Full Integrator:

![img](./images/compiled-results-diagrams/full_results.png)