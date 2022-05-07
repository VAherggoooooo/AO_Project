Shader "Hidden/BilateralBlur"
{
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        CGINCLUDE
        #include "SSAO.cginc"
        sampler2D _MainTex;
        sampler2D _AOTex;
        float4 _MainTex_TexelSize, _AOTex_TexelSize;
        float _BlurRadius;
        float _BilaterFilterFactor;
        
        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };
        
        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
            float2 delta : TEXCOORD1;
        };
        
        v2f vert_h (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv;
            o.delta = _AOTex_TexelSize.xy * float2(_BlurRadius, 0);
            return o;
        }

        v2f vert_v (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv;
            o.delta = _AOTex_TexelSize.xy * float2(0, _BlurRadius);
            return o;
        }
        
        
        half CompareNormal(float3 nor1,float3 nor2)
        {
        	return smoothstep(_BilaterFilterFactor,1.0,dot(nor1,nor2));
        }
        
        half4 frag(v2f i) : SV_Target
        {
            float2 uv = i.uv;
            float2 delta = i.delta;
            float2 uv0a = i.uv - delta;
            float2 uv0b = i.uv + delta;	
            float2 uv1a = i.uv - 2.0 * delta;
            float2 uv1b = i.uv + 2.0 * delta;
            float2 uv2a = i.uv - 3.0 * delta;
            float2 uv2b = i.uv + 3.0 * delta;
            
            float3 normal = GetWorldNormal(uv);
            float3 normal0a = GetWorldNormal(uv0a);
            float3 normal0b = GetWorldNormal(uv0b);
            float3 normal1a = GetWorldNormal(uv1a);
            float3 normal1b = GetWorldNormal(uv1b);
            float3 normal2a = GetWorldNormal(uv2a);
            float3 normal2b = GetWorldNormal(uv2b);
            
            float4 col = tex2D(_AOTex, uv);
            float4 col0a = tex2D(_AOTex, uv0a);
            float4 col0b = tex2D(_AOTex, uv0b);
            float4 col1a = tex2D(_AOTex, uv1a);
            float4 col1b = tex2D(_AOTex, uv1b);
            float4 col2a = tex2D(_AOTex, uv2a);
            float4 col2b = tex2D(_AOTex, uv2b);
            
            float w = 0.37004405286;
            float w0a = CompareNormal(normal, normal0a) * 0.31718061674;
            float w0b = CompareNormal(normal, normal0b) * 0.31718061674;
            float w1a = CompareNormal(normal, normal1a) * 0.19823788546;
            float w1b = CompareNormal(normal, normal1b) * 0.19823788546;
            float w2a = CompareNormal(normal, normal2a) * 0.11453744493;
            float w2b = CompareNormal(normal, normal2b) * 0.11453744493;
            
            float3 result = w * col.rgb;
            result += w0a * col0a.rgb;
            result += w0b * col0b.rgb;
            result += w1a * col1a.rgb;
            result += w1b * col1b.rgb;
            result += w2a * col2a.rgb;
            result += w2b * col2b.rgb;
            
            result /= w + w0a + w0b + w1a + w1b + w2a + w2b;
            return float4(result, 1.0);
        }

        ENDCG

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_h
            #pragma fragment frag
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_v
            #pragma fragment frag
            ENDCG
        }
    }    
}