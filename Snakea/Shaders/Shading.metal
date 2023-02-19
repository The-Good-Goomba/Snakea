//
//  Shading.metal
//  Snakea
//
//  Created by Matthew  Eatough on 14/11/2022.
//

#include <metal_stdlib>
#include "../Common.h"
#include "common.metal"
using namespace metal;

// All this does is create all the rays with their direction
kernel void primaryRays(constant RayData & rd [[buffer(0)]],
                        device Ray *rays [[buffer(1)]],
                        device float2 *random [[buffer(2)]],
                        texture2d<half, access::write> t [[texture(0)]],
                        uint2 tid [[thread_position_in_grid]])
{
    if (tid.x < rd.width && tid.y < rd.height) {
        float2 pixel = (float2)tid;
        float2 r = random[(tid.y % 16) * 16 + (tid.x % 16)];
        pixel += r;
        float2 uv = (float2)pixel / float2(rd.width, rd.height);
        uv = uv * 2.0 - 1.0;
        constant CameraToShader & camera = rd.camera;
        unsigned int rayIdx = tid.y * rd.width + tid.x;
        device Ray & ray = rays[rayIdx];
        ray.origin = camera.position;
        ray.direction = normalize(uv.x * camera.right + uv.y * camera.up +
                                  camera.forward);
        ray.minDistance = 0;
        ray.maxDistance = INFINITY;
        ray.colour = half3(1.0);
        t.write(half4(0.0), tid);
    }
}




kernel void shadeKernel(uint2 tid [[thread_position_in_grid]],
                        constant RayData & uniforms [[ buffer(0) ]],
                        device Ray *rays [[ buffer(1) ]],
                        device Ray *shadowRays [[ buffer(2) ]],
                        device Intersection *intersections [[ buffer(3) ]],
                        constant ShaderMesh *meshes [[ buffer(4) ]],
                        constant float2 *random [[ buffer(5) ]],
                        constant TextureData *textureData [[ buffer(6) ]],
                        texture2d<half, access::read> textureAtlas [[ texture(0) ]]
                        )
{
    if (tid.x < uniforms.width && tid.y < uniforms.height) {
        unsigned int rayIdx = tid.y * uniforms.width + tid.x;
        device Ray & ray = rays[rayIdx];
        device Ray & shadowRay = shadowRays[rayIdx];
        device Intersection & intersection = intersections[rayIdx];
        half3 colour = ray.colour;
        
        // 1
        if (ray.maxDistance >= 0.0 && intersection.distance >= 0.0) {

            ShaderMesh mesh = meshes[intersection.instanceIndex];
            
            uint offset = 0;
            uint i = 0;
            while (intersection.primitiveIndex * 3 >= offset)
            {
                i++;
                offset += mesh.submeshes[(i - 1)].bufferLength;
            }
            i--;
            

            float3 intersectionPoint = ray.origin + ray.direction * intersection.distance;
            float3 surfaceNormal = interpolateVertexAttribute(mesh.normals,intersection);
            surfaceNormal = normalize(surfaceNormal);
            // 2
            float2 r = random[(tid.y % 16) * 16 + (tid.x % 16)];
            float3 lightDirection;
            float3 lightColor;
            float lightDistance;
            sampleAreaLight(uniforms.light, r, intersectionPoint, lightDirection, lightColor, lightDistance);
            lightColor *= saturate(dot(surfaceNormal, lightDirection));

            VertexColourData bruh = interpolateVertexColourData(mesh.generics, intersection);


            float2 baseUV = float2(bruh.uv.x, bruh.uv.y);
            float2 d;
            baseUV = modf(baseUV, d);
            if ( baseUV.x < 0)
                baseUV.x += 1;
            if ( baseUV.y < 0)
                baseUV.y += 1;

            ushort2 colourUV = ushort2((baseUV * textureData[mesh.submeshes[i].colourTextureIndex].size) + textureData[mesh.submeshes[i].colourTextureIndex].offset);

            colour *= textureAtlas.read(colourUV).xyz;

            shadowRay.origin = intersectionPoint + surfaceNormal * 1e-3;
            shadowRay.direction = lightDirection;
            shadowRay.maxDistance = lightDistance - 1e-3;
            shadowRay.colour = half3(lightColor) * colour;

            float3 sampleDirection = sampleCosineWeightedHemisphere(r);
            sampleDirection = alignHemisphereWithNormal(sampleDirection,
                                                        surfaceNormal);
            ray.origin = intersectionPoint + surfaceNormal * 1e-3f;
            ray.direction = sampleDirection;
            ray.colour = colour;
        }
        else {
          ray.maxDistance = -1.0;
            shadowRay.maxDistance = -1.0;
        }
    }
}


kernel void shadowKernel(uint2 tid [[thread_position_in_grid]],
             constant RayData & uniforms [[ buffer(0) ]],
             device Ray *shadowRays [[ buffer(1) ]],
             device float *intersections [[ buffer(2) ]],
             texture2d<half, access::read_write> renderTarget)
{
    if (tid.x < uniforms.width && tid.y < uniforms.height) {
        unsigned int rayIdx = tid.y * uniforms.width + tid.x;
        device Ray & shadowRay = shadowRays[rayIdx];
        float intersectionDistance = intersections[rayIdx];
            if (shadowRay.maxDistance >= 0.0
                  && intersectionDistance <= 0.0) {
              half3 colour = shadowRay.colour;
              colour += renderTarget.read(tid).xyz;
              renderTarget.write(half4(colour, 1.0), tid);
            }
    }
}

kernel void accumulateKernel(constant RayData & rd,
                             texture2d<half> renderTex,
                             texture2d<half, access::read_write> t,
                             uint2 tid [[thread_position_in_grid]])
{
    if (tid.x < rd.width && tid.y < rd.height)
    {
        half3 colour = renderTex.read(tid).xyz;
        if (rd.frameIndex > 0)
        {
            half3 prevColor = t.read(tid).xyz;
            prevColor *= rd.frameIndex;
            colour += prevColor;
            colour /= (rd.frameIndex + 1);
        }
        t.write(half4(colour, 1.0), tid);
    }
}

