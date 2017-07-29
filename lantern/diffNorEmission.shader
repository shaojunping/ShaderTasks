Shader "TSHD/diffNorEmission" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB) A (Emission Scale)", 2D) = "white" {}
		_BumpMap ("Normal (RGB)", 2D) = "white" {}
		_BumpScale ("Bump Scale", Range(-10,10)) = 1.0
		_EmissionScale ("Emission Scale", Range(0,1)) = 2.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex, _BumpMap;

		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
		};

		half _EmissionScale, _BumpScale;
		fixed4 _Color;

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			fixed3 bump = UnpackNormal (tex2D (_BumpMap, IN.uv_BumpMap));
			bump.xy *= _BumpScale;
			bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
			o.Normal = bump;
			o.Alpha = c.a;
			o.Emission = c.rgb * c.a * _EmissionScale;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
