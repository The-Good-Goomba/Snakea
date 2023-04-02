//
//  common.metal
//  Snakea
//
//  Created by Matthew  Eatough on 5/11/2022.
//

#include <metal_stdlib>
#include "../Common.h"
#include <MetalPerformanceShaders/MetalPerformanceShaders.h>
using namespace metal;

using Intersection = MPSIntersectionDistancePrimitiveIndexInstanceIndexCoordinates;

struct ModArgVector
{
    float magnitude;
    float zAngle;
    float xyAngle;
};

// Interpolates vertex attribute of an arbitrary type across the surface of a triangle
// given the barycentric coordinates and triangle index in an intersection struct
template<typename T> inline T interpolateVertexAttribute(constant T *attributes, Intersection intersection) {
  float3 uvw;
  uvw.xy = intersection.coordinates;
  uvw.z = 1.0 - uvw.x - uvw.y;
  unsigned int triangleIndex = intersection.primitiveIndex;
  T T0 = attributes[triangleIndex * 3 + 0];
  T T1 = attributes[triangleIndex * 3 + 1];
  T T2 = attributes[triangleIndex * 3 + 2];
  return uvw.x * T0 + uvw.y * T1 + uvw.z * T2;
}

inline float3 interpolateNormal(constant float3 *normal, uint index) {
  float3 T0 = normal[index * 3 + 0];
  float3 T1 = normal[index * 3 + 1];
  float3 T2 = normal[index * 3 + 2];
  return (T0 + T1 + T2) * 0.333;
}

inline VertexColourData interpolateVertexColourData(constant VertexColourData *attributes, Intersection intersection)
{
    float3 uvw;
    uvw.xy = intersection.coordinates;
    uvw.z = 1.0 - uvw.x - uvw.y;
    unsigned int triangleIndex = intersection.primitiveIndex;
    VertexColourData T0 = attributes[triangleIndex * 3 + 0];
    VertexColourData T1 = attributes[triangleIndex * 3 + 1];
    VertexColourData T2 = attributes[triangleIndex * 3 + 2];
    
    return { uvw.x * T0.uv + uvw.y * T1.uv + uvw.z * T2.uv,
        uvw.x * T0.colour + uvw.y * T1.colour + uvw.z * T2.colour };
}


// Uses the inversion method to map two uniformly random numbers to a three dimensional
// unit hemisphere where the probability of a given sample is proportional to the cosine
// of the angle between the sample direction and the "up" direction (0, 1, 0)
inline float3 sampleCosineWeightedHemisphere(float2 u) {
  float phi = 2.0f * M_PI_F * u.x;
  
  float cos_phi;
  float sin_phi = sincos(phi, cos_phi);
  
  float cos_theta = sqrt(u.y);
  float sin_theta = sqrt(1.0f - cos_theta * cos_theta);
  
  return float3(sin_theta * cos_phi, cos_theta, sin_theta * sin_phi);
}

// Maps two uniformly random numbers to the surface of a two-dimensional area light
// source and returns the direction to this point, the amount of light which travels
// between the intersection point and the sample point on the light source, as well
// as the distance between these two points.
inline void sampleAreaLight(constant AreaLight & light,
                            float2 u,
                            float3 position,
                            thread float3 & lightDirection,
                            thread float3 & lightColor,
                            thread float & lightDistance)
{
  // Map to -1..1
  u = u * 2.0f - 1.0f;
  
  // Transform into light's coordinate system
  float3 samplePosition = light.position +
  light.right * u.x +
  light.up * u.y;
  
  // Compute vector from sample point on light source to intersection point
  lightDirection = samplePosition - position;
  
  lightDistance = length(lightDirection);
  
  float inverseLightDistance = 1.0f / max(lightDistance, 1e-3f);
  
  // Normalize the light direction
  lightDirection *= inverseLightDistance;
  
  // Start with the light's color
  lightColor = light.color;
  
  // Light falls off with the inverse square of the distance to the intersection point
  lightColor *= (inverseLightDistance * inverseLightDistance);
  
  // Light also falls off with the cosine of angle between the intersection point and
  // the light source
  lightColor *= saturate(dot(-lightDirection, light.forward));
}

// Aligns a direction on the unit hemisphere such that the hemisphere's "up" direction
// (0, 1, 0) maps to the given surface normal direction
inline float3 alignHemisphereWithNormal(float3 sample, float3 normal) {
  // Set the "up" vector to the normal
  float3 up = normal;
  
  // Find an arbitrary direction perpendicular to the normal. This will become the
  // "right" vector.
  float3 right = normalize(cross(normal, float3(0.0072f, 1.0f, 0.0034f)));
  
  // Find a third vector perpendicular to the previous two. This will be the
  // "forward" vector.
  float3 forward = cross(right, up);
  
  // Map the direction on the unit hemisphere to the coordinate system aligned
  // with the normal.
  return sample.x * right + sample.y * up + sample.z * forward;
}

inline ModArgVector vectorToEuler(float3 input)
{
    ModArgVector output;
    output.magnitude = fast::sqrt(input.x * input.x + input.y * input.y + input.z * input.z);
    output.xyAngle = fast::atan(input.y / input.x);
    output.zAngle = fast::acos(input.z / output.magnitude);
    
    return output;
}

inline float magnitude(float3 input)
{
    return fast::sqrt(input.x * input.x + input.y * input.y + input.z * input.z);
}
inline float magnitude(float2 input)
{
    return fast::sqrt(input.x * input.x + input.y * input.y);
}

inline float angle(float3 input1, float3 input2)
{
    return fast::acos(dot(input1, input2)/(magnitude(input1)*magnitude(input2)));
}

inline float angle(float2 input1, float2 input2)
{
    return fast::acos(dot(input1, input2)/(magnitude(input1)*magnitude(input2)));
}

inline bool pointIsAboveLine(float2 v1, float2 v2, float2 p)
{
//    float m = (v1.y - v2.y)/(v1.x - v2.x);
//
//    if ((p.y - v1.y) >= m * (p.x - v1.x))
//    {
//        return true;
//    }
    if ((p.y - v1.y) * (v1.x - v2.x) - (v1.y - v2.y) * (p.x - v1.x) >= 0 )
    {
        return true;
    }
    return false;
}
