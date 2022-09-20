in vec4 color;
in vec4 texcoord;
in vec4 viewPos;
in vec4 preDownscaleProjPos;
in vec3 worldNormal;
in vec2 blockLight;


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/Common.inc"
#include "/lib/GBufferData.inc"
#include "/lib/GBuffersCommon.inc"


void main()
{
	if (PixelOutOfScreenBounds(preDownscaleProjPos)) {
		discard;
		return;
	}
	float lodOffset = 0.0;

	vec4 albedo = texture2D(texture, texcoord.st, lodOffset);
	albedo *= color;

	if(albedo.w < 0.01) {
		discard;
		return;
	}

	vec2 mcLightmap = blockLight;


	float wetnessModulator = 1.0;

	wetnessModulator *= saturate(worldNormal.y * 10.5 + 0.7);
	wetnessModulator *= clamp(blockLight.y * 1.05 - 0.7, 0.0, 0.3) / 0.3;
	wetnessModulator *= saturate(wetness * 1.1 - 0.1);



	vec3 N;
	mat3 tbn;
	mat3 tbnRaw;
	CalculateNormalAndTBN(viewPos.xyz, texcoord.st, N, tbn, tbnRaw);




	vec4 specTex = texture2D(specular, texcoord.st, lodOffset);
	#ifdef SPEC_SMOOTHNESS_AS_ROUGHNESS
	specTex[SPEC_CHANNEL_SMOOTHNESS] = 1.0 - specTex[SPEC_CHANNEL_SMOOTHNESS];
	#endif
	specTex[SPEC_CHANNEL_SMOOTHNESS] = specTex[SPEC_CHANNEL_SMOOTHNESS] * 0.992; 								// Fix weird specular issue
	vec4 normalTex = texture2D(normals, texcoord.st, lodOffset) * 2.0 - 1.0;

	float normalMapStrength = 2.0;
	#ifdef FORCE_WET_EFFECT
	normalMapStrength = mix(NORMAL_MAP_STRENGTH, 0.1, wetnessModulator * wetnessModulator * wetnessModulator * wetnessModulator);
	#endif

	vec3 viewNormal = tbn * normalize(normalTex.xyz * vec3(normalMapStrength, normalMapStrength, 1.0));


	// Get specular data from specular texture
	float smoothness = specTex[SPEC_CHANNEL_SMOOTHNESS];
	float metallic = specTex[SPEC_CHANNEL_METALNESS];

	#ifdef FORCE_WET_EFFECT
	smoothness = mix(smoothness, 1.0, saturate(wetnessModulator * saturate(1.0 - metallic)));
	#endif


	// Darker albedo when wet
	albedo.rgb = pow(albedo.rgb, vec3(1.0 + wetnessModulator * (1.0 - metallic) * 0.3));


	// Fix impossible normal angles
	vec3 viewDir = -normalize(viewPos.xyz);
	// make outright impossible
	viewNormal.xyz = normalize(viewNormal.xyz + N / (sqrt(saturate(dot(viewNormal, viewDir)) + 0.001)));


	GBufferDataTransparent gbuffer;


	gbuffer.albedo = albedo;
	gbuffer.normal = viewNormal.xyz;
	gbuffer.geoNormal = N.xyz;
	gbuffer.materialID = 7.1 / 255.0;
	gbuffer.smoothness = 1.0;
	gbuffer.mcLightmap = blockLight;
	gbuffer.depth = 0.0;

	vec4 data0, data1;

	OutputGBufferDataTransparent(gbuffer, data0, data1);

	gl_FragData[0] = data0;
	gl_FragData[1] = data1;

}

/* DRAWBUFFERS:12 */
