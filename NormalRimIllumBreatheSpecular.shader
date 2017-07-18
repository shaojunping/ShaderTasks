Shader "TSHD/NormalRimIllumBreatheSpecular"
{
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		[NoScaleOffset]_BumpMap ("Normal Map", 2D) = "bump" {}
		_BumpScale ("Bump Scale", Float) = 1.0
		
		[NoScaleOffset]_EmissionMaskTex ("Emission Mask Tex", 2D) = "black" {}
		_EmissionScale ("Emission Scale", Range (0.0, 10)) = 0
		_AlbedoScale ("AlbedoScale", Range (0.0, 1.0)) = 1

		_RimColor ("Rim Color", Color) = (0.0,0.0,0.0,1.0)
		_RimPower ("Rim Power", Range(0.5,10)) = 3.0
		_RimLevel ("Rim Level",Range(0,3)) = 0.5
        _RimDir("Rim Direction(W>0 Direction Rim,or esle Full Rim)",Vector) =(1,1,0,1)

		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
		_SpecularScale ("Specular Scale", Range (0.0, 1.0)) = 1

		[KeywordEnum(Enable, Disable)] _Breathe ("Enable Breathe", Float) = 1
		_EmissionBreTimeFrequency("Breathe Frequency",Range(0, 15)) = 0.1
        _EmissionBreAreaScale ("Breathe Strength",Range(0, 2)) = 1.3
	}
	SubShader {
		Tags { "RenderType"="Opaque" }

        LOD 100
		Pass { 
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _BREATHE_ENABLE _BREATHE_DISABLE
			// make fog work
            #pragma multi_compile_fog
			#include "Lighting.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float _BumpScale;

			sampler2D _EmissionMaskTex;
			fixed _EmissionScale;

			float _AlbedoScale;

			sampler2D _DistortTexture; 
			float4 _DistortTexture_ST;

			float _EmissionBreTimeFrequency;
			float _EmissionBreAreaScale;

			float _SpecularScale;
			fixed4 _Specular;
			float _Gloss;

			half4 _RimColor;
			half  _RimPower, _RimLevel;
			float4 _RimDir;
			fixed3 _LightDir;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 TtoW0 : TEXCOORD1;  
				float4 TtoW1 : TEXCOORD2;  
				float4 TtoW2 : TEXCOORD3;
				float scale  : TEXCOORD4;
				UNITY_FOG_COORDS(5) 
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				//o.uv.zw = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				
				float3 worldPos = mul(_Object2World, v.vertex).xyz;  
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
				// Compute the matrix that transform directions from tangent space to world space
				// Put the world position in w component for optimization
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
				
				UNITY_TRANSFER_FOG(o,o.pos);
				float ss = 1.0;
				#if _BREATHE_ENABLE
					ss = sin(_Time.w * _EmissionBreTimeFrequency);
				#endif
				o.scale = (ss + 2.5)*_EmissionBreAreaScale*0.5;

				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				// Get the position in world space		
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				// Compute the light and view dir in world space
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));//
				//fixed3 lightDir = normalize(_LightDir.xyz);
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				
				// Get the normal in tangent space
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.xy));
				bump.xy *= _BumpScale;
				bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
				// Transform the narmal from tangent space to world space
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				//return fixed4(ambient, 1.0);
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump, lightDir));
				//return fixed4((diffuse  + ambient) * _AlbedoScale, 1.0);
				fixed3 halfDir = normalize(lightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bump, halfDir)), _Gloss) * _SpecularScale;
				//return fixed4(specular , 1.0);
				fixed3 emissionMaskColor = tex2D(_EmissionMaskTex, i.uv).rgb;
				emissionMaskColor *= _EmissionScale * i.scale;

				fixed  fresnel = 1 - dot(viewDir, bump);
				half3   rim    = _RimColor.rgb * pow(fresnel, _RimPower) *_RimLevel;
				half rimMask   =    _RimDir.w>0 ? saturate(dot(bump, _RimDir.xyz)) : 1;    
				rim			   *= rimMask;
				fixed3 finalCol = albedo * _Color.rgb * _AlbedoScale + diffuse + specular + emissionMaskColor + rim;
				UNITY_APPLY_FOG(i.fogCoord, finalCol);
				//return fixed4( rim, 1.0);
				return fixed4(finalCol, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}

