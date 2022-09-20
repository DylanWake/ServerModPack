#extension GL_ARB_gpu_shader5 : enable


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/Common.inc"
#include "/lib/MedianFilter.inc"
#include "/lib/FXAA.inc"


const bool colortex3MipmapEnabled = false;


in vec4 texcoord;
flat in mat4 gbufferPreviousModelViewInverse;


vec3 MixDepth(vec3 color, float depth, vec2 coord, const bool isPrev)
{

	vec3 wp = vec3(0.0);
	if (isPrev)
	{
		vec4 prevViewPos = gbufferProjectionInverse * vec4(coord.xy * 4.0 - 1.0, depth * 2.0 - 1.0, 1.0);
		prevViewPos /= prevViewPos.w;
		vec3 prevDepthWorldPos = (gbufferPreviousModelViewInverse * vec4(prevViewPos.xyz, 1.0)).xyz;
		prevDepthWorldPos -= cameraPositionDiff;

		wp = prevDepthWorldPos;
	}
	else
	{
		vec4 vp = GetViewPosition(coord.xy, depth);
		wp = (gbufferModelViewInverse * vec4(vp.xyz, 1.0)).xyz;
	}

	return mix(color, vec3(saturate(length(wp) / 30.)), vec3(0.5));
}

float GetColorVariance(sampler2D tex, vec2 coord, vec2 width)
{
	vec3 sum = vec3(0.0);
	vec3 sum2 = vec3(0.0);

	for (int i = -1; i <= 1; i++)
	{
		for (int j = -1; j <= 1; j++)
		{
			vec2 coordOffset = coord + vec2(i, j) * width;
			vec3 colorSample = texture2DLod(tex, coordOffset, 0).rgb;
			coordOffset -= HalfScreen;
			colorSample = MixDepth(colorSample, GetDepth2(coordOffset), coordOffset, false);

			sum += colorSample;
			sum2 += colorSample * colorSample;
		}
	}

	sum /= 9.00000001;
	sum2 /= 9.00000001;

	float sumLum = dot(sum.rgb, vec3(1.0));
	vec3 spatialVariance = sqrt(max(vec3(0.00000001), sum2 - sum * sum));
	float spatialVarianceLum = dot(spatialVariance.rgb, vec3(1.0));

	return spatialVarianceLum;
}



/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main()
{
	vec4 auxOut = vec4(0.0, 0.0, 0.0, 1.0);

	if (texcoord.y > 0.5) {
		if (texcoord.x < 0.5) {
			vec2 coord = LockRenderPixelCoord(texcoord.st + vec2(HalfScreen.x, 0.0));
			auxOut.rgb = MedianFilter(colortex1, coord, ScreenTexel);
			vec2 coordOffset = coord - HalfScreen;
			auxOut.rgb = MixDepth(auxOut.rgb, GetDepth2(coordOffset), coordOffset, false);
			auxOut.a = GetColorVariance(colortex1, coord, ScreenTexel);
		} else {
			vec2 Texcoord = texcoord.st - HalfScreen;
			vec2 coord = LockRenderPixelCoord(Texcoord * 2.0);
			auxOut.rgb = MedianFilter(colortex3, coord, ScreenTexel * 2.0);
			auxOut.rgb = MixDepth(auxOut.rgb, texture2DLod(colortex6, Texcoord, 0).a, Texcoord, true);
		}
	}


	// Fix missing pixels on lower and left edge
	vec4 col = vec4(0.0);

	if (texcoord.x >= HalfScreen.x && texcoord.y >= HalfScreen.y)
	{
		vec2 coord = clamp(texcoord.xy, HalfScreen + ScreenTexel, vec2(1.0));
		col = texture2DLod(colortex1, coord, 0);

		vec4 tex1 = texture2DLod(colortex1, coord - HalfScreen, 0);
		vec2 unpacked1z = UnpackTwo8BitFrom16Bit(tex1.z);
		col.a = unpacked1z.x;
	}
	if (texcoord.x < HalfScreen.x && texcoord.y < HalfScreen.y)
	{
		vec2 coord = clamp(texcoord.xy + HalfScreen, HalfScreen + ScreenTexel, vec2(1.0));
		col.rgb = DoFXAA(colortex1, coord, ScreenTexel);
		col.a = 1.0;
	}
	gl_FragData[0] = col;
	gl_FragData[1] = auxOut;

}


/* DRAWBUFFERS:12 */
