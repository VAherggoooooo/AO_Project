#ifndef SSAO_CGINC 
#define SSAO_CGINC 

#include "UnityCG.cginc"         
#include "UnityGBuffer.cginc"

sampler2D _CameraGBufferTexture2;
float4x4 _VPMatrix_invers;
sampler2D _CameraDepthTexture;

float Hash(float2 p)
{
    return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

float3 GetRandomVec(float2 p)
{
    float3 vec = float3(0, 0, 0);
    vec.x = Hash(p) * 2 - 1;
    vec.y = Hash(p * p) * 2 - 1;
    vec.z = Hash(p * p * p) * 2 - 1;
    return normalize(vec);
}

float3 GetRandomVecHalf(float2 p)
{
    float3 vec = float3(0, 0, 0);
    vec.x = Hash(p) * 2 - 1;
    vec.y = Hash(p * p) * 2 - 1;
    vec.z = saturate(Hash(p * p * p) + 0.2);
    return normalize(vec);
}

float4 GetWorldPos(float2 uv)
{
    float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
#if defined(UNITY_REVERSED_Z)
    rawDepth = 1 - rawDepth;
#endif
    float4 ndc = float4(uv.xy * 2 - 1, rawDepth * 2 - 1, 1);
    float4 wPos = mul(_VPMatrix_invers, ndc);
    wPos /= wPos.w;
    return wPos;
}

float GetEyeDepth(float2 uv)
{
    float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
    return LinearEyeDepth(rawDepth);
}

float3 GetWorldNormal(float2 uv)
{    
    float3 wNor = tex2D(_CameraGBufferTexture2, uv).xyz * 2.0 - 1.0; //world normal
    return wNor;

}

#endif