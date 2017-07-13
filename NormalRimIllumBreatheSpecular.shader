Shader "TSHD/NormalRimIllumBreatheSpecular" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0

		_EmissionMaskTex ("Emission Mask Tex", 2D) = "white" {}
		_EmissionScale ("Emission Scale", Range (0.0, 10)) = 0
		_AlbedoScale ("AlbedoScale", Range (0.0, 1.0)) = 1

        _RimColor ("Rim Color", Color) = (0.0,0.0,0.0,1.0)
		_RimPower ("Rim Power", Range(0.5,10)) = 3.0
		_RimLevel ("Rim Level",Range(0,3)) = 0.5
        _RimDir("Rim Direction(W>0 Direction Rim,or esle Full Rim)",Vector) =(1,1,0,1)
		
		_Specular ("Specular Color", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
		_SpecularScale ("Specular Scale", Range (0.0, 1.0)) = 1

		[KeywordEnum(Enable, Disable)] _Breathe ("Enable Breathe", Float) = 1
		_EmissionBreTimeFrequency("Breathe Frequency",Float) = 0.1
        _EmissionBreAreaScale ("Breathe Strength",Range(0, 2)) = 1.3

	}
	SubShader {
		Tags { "RenderType"="Opaque" }

        LOD 100
		Pass { 
			Tags { "LightMode"="ForwardBase" }
			//ZWrite Off
            //Blend SrcAlpha OneMinusSrcAlpha
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

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 lightDir: TEXCOORD1;
				float3 viewDir : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
				float3 worldViewDir : TEXCOORD4;
				//#ifndef LIGHTMAP_OFF
				//	half2 uvLM : TEXCOORD5;
				//#endif
				UNITY_FOG_COORDS(5)
				#if _BREATHE_ENABLE
				float scale: TEXCOORD6;
				#endif
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				TANGENT_SPACE_ROTATION;
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
				o.worldNormal = mul(_Object2World, v.normal);
				o.worldViewDir = WorldSpaceViewDir(v.vertex);
				UNITY_TRANSFER_FOG(o,o.pos);
				#if _BREATHE_ENABLE
					float ss = sin(_Time.w * _EmissionBreTimeFrequency);
					o.scale = (ss + 2.5)*_EmissionBreAreaScale*0.5;
				#endif
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
			 	fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				fixed3 albedo = tex2D(_MainTex, i.uv).rgb;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));
			 	fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
			 	fixed3 emissionMaskColor = tex2D(_EmissionMaskTex, i.uv).rgb;
            
				#if _BREATHE_ENABLE
					emissionMaskColor *= _EmissionScale * i.scale;
				#else
					emissionMaskColor *= _EmissionScale;
				#endif
				
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
				
				half rim = 1.0f -saturate(dot(tangentNormal, tangentViewDir));
				half rimMask =_RimDir.w>0 ? saturate(dot(tangentNormal.xyz, _RimDir.xyz)) : 1;    
				fixed3 rimColor =_RimColor.rgb *pow(rim,_RimPower) *_RimLevel*rimMask;  
				fixed3 finalRGB = albedo * _Color.rgb * _AlbedoScale + diffuse + specular * _SpecularScale + emissionMaskColor + rimColor;
				return fixed4(finalRGB, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}
