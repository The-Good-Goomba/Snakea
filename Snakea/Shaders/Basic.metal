//
//  Basic.metal
//  Snakea
//
//  Created by Matthew  Eatough on 27/10/2022.
//

#include <metal_stdlib>
#include "../Common.h"
#include "common.metal"

using namespace metal;



struct Amongus {
    float4 position [[position]];
    float2 uv;
};

constant float2 quadVertices[] = {
    float2(-1, -1),
    float2(-1,  1),
    float2( 1,  1),
    float2(-1, -1),
    float2( 1,  1),
    float2( 1, -1)
};

vertex Amongus vertexShader(unsigned short vid [[vertex_id]])
{
    float2 position = quadVertices[vid];
    Amongus out;
    out.position = float4(position, 0, 1);
    float2 texCoords;
    texCoords.x = ((position.x + 1) / 2.0);
    texCoords.y = ((-position.y + 1) / 2.0);
    out.uv = texCoords;
    return out;
}

fragment half4 fragmentShader(Amongus in [[stage_in]],
                               texture2d<half, access::sample> tex [[ texture(0) ]])
{
    constexpr sampler s(min_filter::nearest,
                        mag_filter::nearest,
                        mip_filter::none);
    half3 colour = tex.sample(s, in.uv).xyz;
    return half4(colour, 1.0);
}

