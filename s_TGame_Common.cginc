

// 全局环境颜色
void TGameAmbient(inout fixed4 color,fixed ambientImpact,fixed diffMultiplier)
{
	//if(ambientImpact > 0.1)
	//{
		// 白色
		fixed4 white = fixed4(1,1,1,1);
			
		// 环境光的影响值
		fixed4 amb = lerp(white, unity_AmbientSky , ambientImpact);
			
		// 最终颜色
		color = color * amb * diffMultiplier;	

	//}
}

// 溶解效果
void TGameDissolve(inout fixed4 color,sampler2D dissolveMap,fixed2 dissolveUV,fixed dissolveFactor,fixed edgeWidth,fixed4 edgeColor)
{
	//if(dissolveFactor > 0.1)
	//{
		// UV坐标用的是 第1张贴图的 uv
		fixed noiseValue = tex2D(dissolveMap,dissolveUV).r;
		fixed edgeFactor = saturate((noiseValue - dissolveFactor)/(edgeWidth*dissolveFactor));
		fixed4 blendColor = color * edgeColor;

		// 剔除
		clip (noiseValue - dissolveFactor);

		// 最终颜色混合
		color = lerp(color ,blendColor,1 - edgeFactor); 
	//}
}


fixed3 Overlay (fixed3 a, fixed3 b)
{
    fixed3 r = a < .5 ? 2.0 * a * b : 1.0 - 2.0 * (1.0 - a) * (1.0 - b);
    //r.a = b.a;
    return r;
}


/*
	使用Sine来改变Color曲线


*/
fixed3 SoftColor (fixed3 color)
{
   //fixed offset = 0.05;
   //fixed scale 	= 0.75;

    //fixed r = sin(color.r) * scale + offset;
	//fixed g = sin(color.g) * scale + offset;
	//fixed b = sin(color.b) * scale + offset;

    //fixed r = sin(color.r+offset) * scale;
	//fixed g = sin(color.g+offset) * scale;
	//fixed b = sin(color.b+offset) * scale;


	fixed offset = 0.5;

	fixed r = (sin(( color.r - offset ) * 2) + 1) *0.5;
	fixed g = (sin(( color.g - offset ) * 2) + 1) *0.5;
	fixed b = (sin(( color.b - offset ) * 2) + 1) *0.5;








   return fixed3(r,g,b);// * 1.1; 

}
