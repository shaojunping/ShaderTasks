// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'


/*
	TGameShader - Character - PlayCharacter


*/
Shader "TGame/Character/PCAlphaBlendZWrite" 
{  
    Properties 
    {  
        _MainTex  ("Diff(RGB)", 2D) = "white" {}  
        _Mask	  ("Mask (R-Matcap)", 2D) = "black" {}  
        _MatCap   ("MatCap", 2D) = "white" {}  

        // 光照的影响
        _Illum ("Illum",Range(0,1)) = 0.4

        // Diffuse倍乘
        _DiffuseMultiply ("Diffuse-Mulitplier",Range(0,3)) = 1.0

		// MatCap倍乘
        _MatCapMulti ("MatCap-Multiplier",Range(0,5)) = 1

        // 边缘光强度
        _Rim ("Rim",Range(0,10)) = 0
		_RimColor ("RimColor", Color) = (1,1,1,1) 

		// Dissolve 溶解
		[HideInInspector] _DissolveMap ("DissolveMap (R)",2D) = "white"{}
 		[HideInInspector] _DissolveFactor ("DissolveFactor",Range(0,1.05)) = 0
		[HideInInspector] _EdgeWidth("EdgeWidth",Range(0,0.5)) = 0.3
		[HideInInspector] _EdgeColor("EdgeColor",Color) =  (1,1,1,1)	

		// 受Ambient的影响程度
		_AmbientImpact ("AmbientImpact",Range(0,1)) = 0.35


        // Outliner
        //_OutlineColor ("Outline Color", Color) = (1,1,1,1)
		//_Outline ("Outline width", Range (0.0, 0.03)) = 0

    }  

	// Outliner Vertex Cache
	//CGINCLUDE
	//#include "UnityCG.cginc"
	 
	//struct appdata 
	//{
	//	fixed4 vertex : POSITION;
	//	fixed3 normal : NORMAL;
	//};
	 
	//struct v2f 
	//{
	//	fixed4 pos : POSITION;
	//	fixed4 color : COLOR;
	//};
	 
	//uniform fixed _Outline;
	//uniform fixed4 _OutlineColor;
	 
	//v2f vert(appdata v) 
	//{

	//	v2f o;
	//	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
	 
	//	fixed3 norm   = mul ((fixed3x3)UNITY_MATRIX_IT_MV, v.normal);
	//	fixed2 offset = TransformViewToProjection(norm.xy);
	 
	//	o.pos.xy += offset * o.pos.z * _Outline;
	//	o.color = _OutlineColor;
	//	return o;
	//}
	//ENDCG
	

    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	SubShader 
	{
		Tags { "Queue" = "Transparent" }
		// Extra pass that renders to depth buffer only
		Pass {
			ZWrite On
			ColorMask 0
		}
		// Outline
		//Pass 
		//{
		//	Name "OUTLINE"
		//	Tags { "LightMode" = "Always" }
		//	Cull off
		//	ZWrite Off
		//	ZTest Always
		//	ColorMask RGB // alpha not used
 
		//	// you can choose what kind of blending mode you want for the outline
		//	//Blend SrcAlpha OneMinusSrcAlpha // Normal
		//	//Blend One One // Additive
		//	//Blend One OneMinusDstColor // Soft Additive
		//	//Blend DstColor Zero // Multiplicative
		//	Blend DstColor SrcColor // 2x Multiplicative
 
		//	CGPROGRAM
		//	#pragma vertex vert
		//	#pragma fragment frag
			 
		//	half4 frag(v2f i) :COLOR 
		//	{
		//		return i.color;		
		//	}
		//	ENDCG
		//}
		
		Pass
		{
        //Cull Off
		Tags { "Queue" = "Transparent" }
        CGPROGRAM  
      	#pragma surface surf Lambert vertex:vertMatCap finalcolor:rampFogColor 
        #pragma target 2.0
        
       	#pragma multi_compile Default_FOG USE_RAMP_FOG 
		#pragma multi_compile_fog
		
		#include "s_TGame_Common.cginc"
		//#include "s_TGame_RampFog.cginc" 

        sampler2D _MainTex;
        sampler2D _Mask;
        sampler2D _MatCap; 

        fixed _Illum;
        fixed _DiffuseMultiply;
		fixed _AmbientImpact;
	
        fixed _MatCapMulti;
        fixed _Rim;
        fixed4 _RimColor;
        
		// Dissolve
      	sampler2D	_DissolveMap;
		fixed		_DissolveFactor;
		fixed		_EdgeWidth;
		fixed4		_EdgeColor;
		
		// RampFog
		sampler2D 	_FogTex;
	    fixed		_FogVal;
	    fixed 		_UseRampFog;
		fixed 		_rampFogYSimple;
		

		struct Input 
		{
			fixed2 uv_MainTex : TEXCOORD0;
			fixed2 matcapUV;
            fixed3 viewDir;
 
			half fog; 
		};
          
		void vertMatCap (inout appdata_full v, out Input o)
		{
            UNITY_INITIALIZE_OUTPUT(Input,o);       
            
            
            // MatCap坐标计算
            fixed3 worldNorm = normalize(unity_WorldToObject[0].xyz * v.normal.x + unity_WorldToObject[1].xyz * v.normal.y + unity_WorldToObject[2].xyz * v.normal.z);
            worldNorm = mul((float3x3)UNITY_MATRIX_V, worldNorm);
            o.matcapUV = worldNorm.xy * 0.5 + 0.5;    
            
            
            // RampFog处理
			float pos = length(mul (UNITY_MATRIX_MV, v.vertex).xyz);
		    #if defined(FOG_LINEAR)
				// factor = (end-z)/(end-start) = z * (-1/(end-start)) + (end/(end-start))
					float unityFogFactor = (pos) * unity_FogParams.z + unity_FogParams.w;
				#elif defined(FOG_EXP)
					// factor = exp(-density*z)
					 float unityFogFactor = unity_FogParams.y * (pos); 
					 unityFogFactor = exp2(-unityFogFactor);
				#elif defined(FOG_EXP2)
					// factor = exp(-(density*z)^2)
					float unityFogFactor = unity_FogParams.x * (pos);
				 	unityFogFactor = exp2(-unityFogFactor*unityFogFactor);
				#else
					float unityFogFactor = 1.0;
				#endif
	
			o.fog = saturate(unityFogFactor);
			
            
		}
		
		
		void rampFogColor (Input IN, SurfaceOutput o, inout fixed4 color) 
	    {
	      	#ifdef UNITY_PASS_FORWARDADD
	        	UNITY_APPLY_FOG_COLOR(IN.fog, color, float4(0,0,0,0));

	      	#else
				// 使用RampFog
	      		#ifdef USE_RAMP_FOG
					float2 fogUV = float2(1-IN.fog,_rampFogYSimple);
					fixed4 rampFog = lerp(color,(tex2D(_FogTex,fogUV)),_FogVal);
					UNITY_APPLY_FOG_COLOR(IN.fog, color, rampFog);
				#else
	      			UNITY_APPLY_FOG_COLOR(IN.fog, color, unity_FogColor);
	      		#endif
 		
	      	#endif 
	    }
		

        void surf (Input IN, inout SurfaceOutput o)   
        {  
			fixed4 mc 		= tex2D	(_MatCap, IN.matcapUV); 
			fixed4 mask 	= tex2D	(_Mask,IN.uv_MainTex);
            fixed4 c  		= tex2D (_MainTex, IN.uv_MainTex);  


            fixed mask_mc = mask.r;

			// 颜色计算
            fixed3 final = c.rgb;
            final = (c.rgb * mc.rgb * _MatCapMulti * mask_mc) + (c.rgb * (1.0 - mask_mc) * _DiffuseMultiply);

			// Rim
        	fixed rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));
            final += pow(rim,6.0) * _RimColor * _Rim;
            
     
    		
            // TGame环境光处理 float3 => float4
            fixed4 finalColor = fixed4(final,1.0);   
            
            // AmbientColor
			TGameAmbient(finalColor,_AmbientImpact,_DiffuseMultiply);
			
			// Dissolve
			TGameDissolve(finalColor,_DissolveMap,IN.uv_MainTex,_DissolveFactor,_EdgeWidth,_EdgeColor);	
			
            // 
            final = finalColor.rgb;

            o.Albedo = final * _Illum;
            o.Emission = final * (1.0 - _Illum);




        }  
        ENDCG 
		} 
    }   
FallBack "Diffuse"  
}  