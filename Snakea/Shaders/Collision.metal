//
//  Collision.metal
//  Snakea
//
//  Created by Matthew  Eatough on 1/2/2023.
//

#include <metal_stdlib>
#include "../Common.h"
#include "common.metal"
using namespace metal;

struct Vector3D
{
    float3 vector;
    float mag;
    
    Vector3D(float3 v)
    {
        vector = v;
        mag = magnitude(v);
    }
};

inline float distanceFromEdge(float2 v1, float2 v2, float2 c)
{
    float d = INFINITY;
    if ( dot((v2 - v1), (c - v1)) >=  0 && dot((v1 - v2), (c - v2)) >= 0 )
    {
        float theta = angle(c - v2, v1 - v2);
        d = magnitude(c - v2) * fast::sin(theta);
    }
    return d;
}

kernel void collisionSphereTriangle(uint2 id [[ thread_position_in_grid ]],
                                    device Sphere *entities [[ buffer(0) ]],
                                    constant collisionBufferObject *objects [[ buffer(1) ]],
                                    texture2d<half, access::write> collisionTrue [[texture(0)]])
{
//    id.x is the triangle of the collision test
//    id.y is the sphere
    uint o = 0;
    while (id.x > objects[o].triangleCount)
    {
        id.x -= objects[o].triangleCount;
        o++;
    }
    
    collisionBufferObject object = objects[o];
    
    float3 n1 = object.normals[3 * id.x + 0];
    float3 n2 = object.normals[3 * id.x + 1];
    float3 n3 = object.normals[3 * id.x + 2];
    
    float3 normal = n1 + n2 + n3;
    collisionTrue.write(half4(0,0,0,1), id);
    
    if ( 0 > dot(normal, entities[id.y].velocity))
    {
        float3 v1 = object.vertices[3 * id.x + 0];
        float3 v2 = object.vertices[3 * id.x + 1];
        float3 v3 = object.vertices[3 * id.x + 2];
        
        float3 newPos = entities[id.y].position + entities[id.y].velocity;
        float3 dir = newPos - v1;
        
        float theta1 = angle(dir,normal);
        float distanceFromPlane = magnitude(dir) * fast::cos(theta1);
        
//        If it's not colliding with the plane, its not colliding with the triangle
        if (distanceFromPlane >= entities[id.y].radius) return;
       
        
        float3 pointOnPlane = newPos + distanceFromPlane * normal;
        
//        Snap the triangle to a plane with vertices 1 & 2 vertical
        Vector3D v2v1 = Vector3D(v2 - v1);
        
        float2 nV1 = float2(0,0);
        float2 nV2 = float2(0,v2v1.mag);
        theta1 = angle(v2v1.vector, v3 - v1);
        float2 nV3 = fast::distance(v1, v3) * float2(fast::sin(theta1),fast::cos(theta1));
        float theta2 = angle(v2v1.vector, pointOnPlane - v1);
        float2 c;
        if ((angle(v3 - v1, pointOnPlane - v1) + theta2 == theta1) ||
            (angle(v3 - v1, pointOnPlane - v1) + theta1 == theta2))
        {
            c = magnitude(pointOnPlane - v1) * float2(fast::sin(theta2),fast::cos(theta2));
    //        Check if the point lies within the triangle
            if (pointIsAboveLine(nV2, nV3, c) && pointIsAboveLine(nV3, nV1, c))
            {
    //            Do something
    //            It is the distance the circle is from the plane away
                entities[id.y].velocity = float3(0,0,0);
//                entities[id.y].velocity += normal * distanceFromPlane;
                collisionTrue.write(half4(1,1,1,1), id);
                return;
            }
        } else {
            c = magnitude(pointOnPlane - v1) * float2(-fast::sin(theta2),fast::cos(theta2));
        }
        
        float radius = fast::sqrt(entities[id.y].radius * entities[id.y].radius - distanceFromPlane * distanceFromPlane);
        
//        Check if the circle collides with an edge
//        Edge 1 v1 -> v2 (v1 -> v2 is vertical)
        float d = INFINITY;
        if(c.y > 0 && c.y < v2.y)
        {
            d = abs(c.x);
        }
//        Edge 2 v2 -> v3
        d = min(distanceFromEdge(nV2, nV3, c), d);
//        Edge 3 v1 -> v3
        d = min(distanceFromEdge(nV1, nV3, c), d);

        if (d != INFINITY && d < radius)
        {
            entities[id.y].velocity = float3(0,0,0);
//            entities[id.y].velocity += normal * fast::sqrt(radius * radius - d*d);
            collisionTrue.write(half4(1,1,1,1), id);
            return;
        }
        
//        Check collision with vertices
        d = magnitude(c);
        d = min(magnitude(c - nV2), d);
        d = min(magnitude(c - nV3), d);
        
        if (d < radius)
        {
            entities[id.y].velocity = float3(0,0,0);
//            entities[id.y].velocity += normal * fast::sqrt(radius * radius - d*d);
            collisionTrue.write(half4(1,1,1,1), id);
            return;
        }
        
    }
    collisionTrue.write(half4(0,0,0,1), id);
    
}




