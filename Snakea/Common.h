//
//  Common.h
//  Snakea
//
//  Created by Matthew  Eatough on 25/10/2022.
//

#ifndef Common_h
#define Common_h

#import <simd/simd.h>

typedef struct SceneConstants {
    float totalGameTime;
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 viewMatrix;
} SceneConstants;

typedef struct ModelConstants {
    matrix_float4x4 modelMatrix;
    matrix_float3x3 normalMatrix;
    int useBones;
} ModelConstants;

typedef struct Vertex{
    vector_float3 position;
    vector_float3 normal;
    vector_ushort4 joints;
    vector_float4 weights;
} Vertex;

typedef enum {
    tVertices = 0,
    tOutpos = 1,
    tOutnorm = 2,
    tJointMatrices = 3,
    tObjId = 4,
    tObjCount = 5
} TransformationIndices;

typedef struct Material{
    vector_float4 colour;
    float shininess;
    float metallic;
    float roughness;
    float ambientOcclusion;
    vector_float3 specularColour;
    
    int useBaseTexture;
    int useNormalMapTexture;
} Material;

typedef struct VertexColourData{
    vector_float2 uv;
    vector_float3 colour;
} VertexColourData;

typedef enum{
    Position = 0,
    Normal = 1,
    Joints = 2,
    Weights = 3,
    UV = 4,
    Colour = 5
} VertexIndices;

typedef enum {
    hasSkeletonindex = 1,

} FunctionConstantsIndex;

typedef struct CameraToShader {
    vector_float3 position;
    vector_float3 right;
    vector_float3 up;
    vector_float3 forward;
} CameraToShader;

typedef struct AreaLight{
    vector_float3 position;
    vector_float3 forward;
    vector_float3 right;
    vector_float3 up;
    vector_float3 color;
} AreaLight;

typedef struct RayData
{
    unsigned int width;
    unsigned int height;
    unsigned int blocksWide;
    unsigned int frameIndex;
    CameraToShader camera;
    AreaLight light;
} RayData;

typedef struct SubmeshInfo {
    uint32_t bufferLength;
    uint8_t colourTextureIndex;
    uint8_t normalTextureIndex;
    uint8_t aoTextureIndex;
} SubmeshInfo;

typedef struct TextureData {
    vector_float2 offset;
    vector_float2 size;
} TextureData;

typedef struct Sphere
{
    vector_float3 position;
    vector_float3 velocity;
    float radius;
} Sphere;

#if __METAL_VERSION__

typedef struct ShaderMesh
{
    constant VertexColourData* generics;
    constant float3* normals;
    constant float3* positions;
    constant SubmeshInfo* submeshes;
} ShaderMesh;

struct Ray {
    packed_float3 origin;
    float minDistance;
    packed_float3 direction;
    float maxDistance;
    half3 colour;
};

#else

#import <Metal/Metal.h>
#import <Foundation/Foundation.h>

typedef struct ShaderMesh
{
    uint64_t generics;
    uint64_t normals;
    uint64_t positions;
    uint64_t submeshes;
} ShaderMesh;

#endif

#endif /* Common_h */
