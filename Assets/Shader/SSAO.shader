Shader "Hidden/SSAO"
{
    SubShader
    {
            CGINCLUDE
            #include "SSAO.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            sampler2D _MainTex, _AOTex;; 
            float _SampleCount, _Radius, _RangeCheck, _AOInt;
            float4x4 _VMatrix, _PMatrix;
            float4 _AOCol;
            
            fixed4 frag (v2f i) : SV_Target
            {
                float eyeDepth = GetEyeDepth(i.uv);
                float4 wPos = GetWorldPos(i.uv);//world pos 
                float3 wNor = GetWorldNormal(i.uv);//world normal
                float3 wTan = GetRandomVec(i.uv);
                float3 wBin = cross(wNor, wTan);
                wTan = cross(wBin, wNor);
                float3x3 TBN_Line = float3x3(wTan, wBin, wNor);

                float ao = 0;
                int sampleCount = (int)_SampleCount;
                [unroll(128)]
                for(int j = 0; j < sampleCount; j++)
                {
                    //float3 offDir = _OffDirs[j];
                    float3 offDir = GetRandomVecHalf(j * i.uv);
                    float scale = j / _SampleCount;
                    scale = lerp(0.01, 1, scale * scale);
                    offDir *= scale * _Radius;
                    float weight = smoothstep(0,0.2,length(offDir));
                    offDir = mul(offDir, TBN_Line);

                    float4 offPosW = float4(offDir, 0) + wPos;
                    float4 offPosV = mul(_VMatrix, offPosW);
                    float4 offPosC = mul(_PMatrix, offPosV);
                    float2 offPosScr = offPosC.xy / offPosC.w;
                    offPosScr = offPosScr * 0.5 + 0.5;
                    float sampleDepth = GetEyeDepth(offPosScr);
                    float sampleZ = offPosC.w;                    
                    float rangeCheck = smoothstep(0, 1.0, _Radius / abs(sampleZ - sampleDepth) * _RangeCheck * 0.1);
                    float selfCheck = (sampleDepth < eyeDepth - 0.08) ?  1 : 0;                    
                    ao += (sampleDepth < sampleZ) ?  1 * rangeCheck * selfCheck * _AOInt * weight : 0;
                }
                ao = 1 - saturate((ao / sampleCount));
                return ao;
                float4 scrTex = tex2D(_MainTex, i.uv);
                return ao * scrTex;
            }
            ENDCG

        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_final 

            fixed4 frag_final (v2f i) : SV_Target
            {
                float4 scrTex = tex2D(_MainTex, i.uv);
                float4 aoTex = tex2D(_AOTex, i.uv);
                //return aoTex;
                float4 finalCol = lerp(scrTex * _AOCol, scrTex, aoTex.x);
                return finalCol;
            }

            ENDCG
        }
    }
}
