#include "camera.h"

#include <mycpp/myglm.h>

Camera::Camera()
    : Camera(400, 400)
{
    look = glm::vec3(0, 0, -1);
    up = glm::vec3(0, 1, 0);
    right = glm::vec3(1, 0, 0);
}

Camera::Camera(unsigned int w, unsigned int h)
    : Camera(w, h, glm::vec3(0, 5.5, -30), glm::vec3(0, 2.5, 0), glm::vec3(0, 1, 0))
{}

Camera::Camera(unsigned int w,
               unsigned int h,
               const glm::vec3& e,
               const glm::vec3& r,
               const glm::vec3& worldUp)
    : fovy(45)
    , width(w)
    , height(h)
    , near_clip(0.1f)
    , far_clip(1000)
    , eye(e)
    , ref(r)
    , world_up(worldUp)
{
    RecomputeAttributes();
}

void Camera::RecomputeAttributes()
{
    look = glm::normalize(ref - eye);
    right = glm::normalize(glm::cross(look, world_up));
    up = glm::cross(right, look);

    float tan_fovy = tan(glm::radians(fovy / 2));
    float len = glm::length(ref - eye);
    aspect = width / static_cast<float>(height);
    V = up * len * tan_fovy;
    H = right * len * aspect * tan_fovy;
}

glm::mat4 Camera::getViewProj()
{
    return glm::perspective(glm::radians(fovy), width / (float)height, near_clip, far_clip)
           * glm::lookAt(eye, ref, up);
}

void Camera::Reset()
{
    fovy = 45.f;
    eye = glm::vec3(0, 0, 12);
    ref = glm::vec3(0, 0, 0);
    world_up = glm::vec3(0, 1, 0);
    RecomputeAttributes();
}

void Camera::RotateAboutUp(float deg)
{
    glm::mat4 rotation = glm::rotate(glm::mat4(1.0f), deg, up);
    ref = ref - eye;
    ref = glm::vec3(rotation * glm::vec4(ref, 1));
    ref = ref + eye;
    RecomputeAttributes();
}

void Camera::RotateAboutRight(float deg)
{
    glm::mat4 rotation = glm::rotate(glm::mat4(1.0f), deg, right);
    ref = ref - eye;
    ref = glm::vec3(rotation * glm::vec4(ref, 1));
    ref = ref + eye;
    RecomputeAttributes();
}

void Camera::RotateTheta(float deg)
{
    glm::mat4 rotation = glm::rotate(glm::mat4(1.0f), deg, right);
    eye = eye - ref;
    eye = glm::vec3(rotation * glm::vec4(eye, 1.f));
    eye = eye + ref;
    RecomputeAttributes();
}

void Camera::RotatePhi(float deg)
{
    glm::mat4 rotation = glm::rotate(glm::mat4(1.0f), deg, up);
    eye = eye - ref;
    eye = glm::vec3(rotation * glm::vec4(eye, 1.f));
    eye = eye + ref;
    RecomputeAttributes();
}

void Camera::Zoom(float amt)
{
    glm::vec3 translation = look * amt;
    eye += translation;
}

void Camera::TranslateAlongLook(float amt)
{
    glm::vec3 translation = look * amt;
    eye += translation;
    ref += translation;
}

void Camera::TranslateAlongRight(float amt)
{
    glm::vec3 translation = right * amt;
    eye += translation;
    ref += translation;
}

void Camera::TranslateAlongUp(float amt)
{
    glm::vec3 translation = up * amt;
    eye += translation;
    ref += translation;
}
