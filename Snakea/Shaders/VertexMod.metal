//
//  VertexMod.metal
//  Snakea
//
//  Created by Matthew  Eatough on 17/12/2022.
//

#include <metal_stdlib>
#include "../Common.h"
#include "common.metal"
using namespace metal;

kernel void vertexModifiers(constant Vertex *vertices [[ buffer(0) ]],
                            device float3 *outputPos [[buffer(1) ]],
                            device float3 *outputNorm [[ buffer(2) ]],
                            constant float4x4 *jointMatrices [[ buffer(3) ]],
                            constant ModelConstants &modelConstants [[ buffer(4) ]],
                            uint vid [[ thread_position_in_grid ]])
{
    
    float4 position = float4(vertices[vid].position, 1.0);
    float4 normal = float4(vertices[vid].normal, 1.0);
    
    if (modelConstants.useBones == 1)
    {
//        Joint is the index in the joint matrix, and weights is how much that joint affects this vertex
        float4 weights = vertices[vid].weights;
        ushort4 joints = vertices[vid].joints;
        position =
        weights.x * (jointMatrices[joints.x] * position) +
        weights.y * (jointMatrices[joints.y] * position) +
        weights.z * (jointMatrices[joints.z] * position) +
        weights.w * (jointMatrices[joints.w] * position);
        normal =
        weights.x * (jointMatrices[joints.x] * normal) +
        weights.y * (jointMatrices[joints.y] * normal) +
        weights.z * (jointMatrices[joints.z] * normal) +
        weights.w * (jointMatrices[joints.w] * normal);
    }
    
//    Since the acceleration structure moves things already
//    outputPos[vid] = position.xyz;
    outputPos[vid] = (modelConstants.modelMatrix * position).xyz;
    outputNorm[vid] = modelConstants.normalMatrix * normal.xyz;
    
    return;
}

