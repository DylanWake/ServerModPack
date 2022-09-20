#extension GL_ARB_gpu_shader5 : enable


in vec4 color;
in vec4 texcoord;
in vec4 viewPos;
in vec4 preDownscaleProjPos;
in vec3 worldPosition;
in vec3 worldNormal;
in vec3 screenspace;
in vec3 normal;
in vec2 blockLight;
flat in float materialIDs;
flat in float textureResolution;


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/Common.inc"
#include "/lib/GBufferData.inc"
#include "/lib/GBuffersCommon.inc"


vec2 AtlasTiles;
float TextureTexel;


vec2 OffsetCoord(in vec2 coord, in vec2 offset)
{
	vec2 interTileCoord = fract(coord + offset);
	return (floor(coord) + interTileCoord) / AtlasTiles;
}

float BilinearHeightSample(vec2 coord)
{
	vec2 fpc = fract(coord * atlasSize + 0.5);
	coord *= AtlasTiles;

	vec4 sh;
	sh = vec4(
		texture2DLod(normals, OffsetCoord(coord, vec2(-TextureTexel,  TextureTexel)), 0).a,
		texture2DLod(normals, OffsetCoord(coord, vec2( TextureTexel,  TextureTexel)), 0).a,
		texture2DLod(normals, OffsetCoord(coord, vec2( TextureTexel, -TextureTexel)), 0).a,
		texture2DLod(normals, OffsetCoord(coord, vec2(-TextureTexel, -TextureTexel)), 0).a
	);

	return mix(
		mix(sh.w, sh.z, fpc.x),
		mix(sh.x, sh.y, fpc.x),
		fpc.y
	);
}

vec2 CalculateParallaxCoord(vec2 coord, vec3 viewVector, vec2 texGradX, vec2 texGradY, out vec3 offsetCoord)
{
	vec2 parallaxCoord = coord.st;
	vec3 stepScale = vec3(0.001, 0.001, 0.15);

	float parallaxDepth = PARALLAX_DEPTH;




	const float gradThreshold = 0.004;
	float absoluteTexGrad = dot(abs(texGradX) + abs(texGradY), vec2(1.0));

	parallaxDepth *= 1.0 - saturate(absoluteTexGrad / gradThreshold);
	if (absoluteTexGrad > gradThreshold)
	{
		offsetCoord = vec3(0.0, 0.0, 1.0);
		return texcoord.st;
	}

	float parallaxStepSize = 0.5;

	stepScale.xy *= parallaxDepth;
	stepScale *= parallaxStepSize;

	#ifdef SMOOTH_PARALLAX
	float heightmap = BilinearHeightSample(coord.xy);
	#else
	float heightmap = textureGrad(normals, coord.st, texGradX, texGradY).a;
	#endif

	vec3 pCoord = vec3(0.0f, 0.0f, 1.0f);
	vec2 basicCoord = coord.xy * AtlasTiles;


	if (heightmap < 1.0)
	{
		const int maxRefinements = 4;
		int numRefinements = 0;

		vec3 stepSize = viewVector * stepScale * 0.25 * (absoluteTexGrad * 15500.0 + 1.0);
		stepSize.xy *= AtlasTiles;
		float sampleHeight = heightmap;


		for (int i = 0; i < 80; i++)
		{
			pCoord += stepSize;

			parallaxCoord = OffsetCoord(basicCoord, pCoord.xy);

			#ifdef SMOOTH_PARALLAX
			sampleHeight = BilinearHeightSample(parallaxCoord);
			#else
			sampleHeight = textureGrad(normals, parallaxCoord, texGradX, texGradY).a;
			#endif


			if (sampleHeight > pCoord.z)
			{
				if (numRefinements < maxRefinements)
				{
					pCoord -= stepSize;
					stepSize *= 0.5;
					numRefinements++;
				}
				else
				{
					break;
				}
			}
		}
	}
	pCoord.xy /= AtlasTiles;
	offsetCoord = pCoord;

	return parallaxCoord;
}



void main()
{
	GBufferData gbuffer;
	if (PixelOutOfScreenBounds(preDownscaleProjPos)) {
		discard;
		return;
	}
	float lodOffset = 0.0;

	vec2 texGradX = dFdx(texcoord.st) * 0.25;
	vec2 texGradY = dFdy(texcoord.st) * 0.25;
	vec2 textureCoordinate = texcoord.st;


	vec3 N;
	mat3 tbn;
	mat3 tbnRaw;
	CalculateNormalAndTBN(viewPos.xyz, texcoord.st, N, tbn, tbnRaw);

	vec3 offsetCoord = vec3(0.0, 0.0, 1.0);
	#ifdef PARALLAX
		float fTextureResolusion = TEXTURE_RESOLUTION;
		#ifdef ADAPTIVE_PARALLAX_RESOLUTION
		fTextureResolusion = floor(textureResolution + 0.5);
		#endif
		AtlasTiles = atlasSize / fTextureResolusion;
		TextureTexel = 0.5 / fTextureResolusion;

		vec3 texViewVector = tbnRaw * viewPos.xyz;
		float atlasAspectRatio = atlasSize.x / atlasSize.y;
		texViewVector.y *= atlasSize.x / atlasSize.y;
		texViewVector = normalize(texViewVector);


		textureCoordinate = CalculateParallaxCoord(texcoord.st, texViewVector, texGradX, texGradY, offsetCoord);
	#endif


	vec4 albedo = textureGrad(texture, textureCoordinate, texGradX, texGradY);
	albedo *= color;

	vec2 mcLightmap = blockLight;

	gbuffer.parallaxOffset = 0.0;
	#ifdef PARALLAX
		vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos.xyz, 0.0)).xyz;
		vec3 worldDir = normalize(worldPos);
		float NdotV = dot(worldDir, -worldNormal);

		vec3 parallaxWorldPos = worldPos.xyz;

		parallaxWorldPos += worldDir * (1.0 - offsetCoord.z) * 0.3 / (saturate(NdotV) + 0.00001);

		parallaxWorldPos = (gbufferModelView * vec4(parallaxWorldPos.xyz, 0.0)).xyz;

		vec4 projPos = gbufferProjection * vec4(parallaxWorldPos.xyz, 1.0);
		projPos /= projPos.w;
		projPos = projPos * 0.5 + 0.5;

		gl_FragDepth = projPos.z;

		gbuffer.parallaxOffset = (1.0 - offsetCoord.z);

	#endif

	float wetnessModulator = 1.0;

	vec3 rainNormal = vec3(0.0, 0.0, 0.0);
	#ifdef RAIN_SPLASH_EFFECT
	vec4 rainPosition = viewPos + vec4(0.0, 0.0, (1.0 - gbuffer.parallaxOffset) * 0.5, 0.0);
	rainPosition = gbufferModelViewInverse * rainPosition;
	rainNormal = GetRainSplashNormal(rainPosition.xyz, worldNormal, wetnessModulator);
	#endif

	wetnessModulator *= saturate(worldNormal.y * 10.5 + 0.7);
	wetnessModulator *= saturate(abs(2.0 - materialIDs));
	wetnessModulator *= clamp(mcLightmap.y * 1.05 - 0.7, 0.0, 0.3) / 0.3;
	wetnessModulator *= saturate(wetness * 1.1 - 0.1);


	vec4 specTex = textureGrad(specular, textureCoordinate, texGradX, texGradY);
	#ifdef SPEC_SMOOTHNESS_AS_ROUGHNESS
	specTex[SPEC_CHANNEL_SMOOTHNESS] = 1.0 - specTex[SPEC_CHANNEL_SMOOTHNESS];
	#endif
	specTex[SPEC_CHANNEL_SMOOTHNESS] = specTex[SPEC_CHANNEL_SMOOTHNESS] * 0.992; 								// Fix weird specular issue


	vec4 normalTex = textureGrad(normals, textureCoordinate, texGradX, texGradY) * 2.0 - 1.0;
	normalTex.xy = sign(normalTex.xy) * max(vec2(0.0), abs(normalTex.xy) - 0.003);

	float normalMapStrength = 3.0;
	#ifdef FORCE_WET_EFFECT
	normalMapStrength = mix(NORMAL_MAP_STRENGTH, 0.1, wetnessModulator * wetnessModulator * wetnessModulator * wetnessModulator);


	vec3 viewNormal = tbn * normalize(normalTex.xyz * vec3(normalMapStrength, normalMapStrength, 1.0) + rainNormal * wetnessModulator * vec3(1.0, 1.0, 0.0));
	#else
	vec3 viewNormal;
	{
		vec3 heightNormal = normalize(normalTex.xyz);
		#ifdef PARALLAX
		const float eps = 0.00001;
		#ifdef SMOOTH_PARALLAX
		float cD = BilinearHeightSample(textureCoordinate);
		float rD = BilinearHeightSample(textureCoordinate + vec2(eps, 0.0));
		float uD = BilinearHeightSample(textureCoordinate + vec2(0.0, eps));
		#else
		float cD = textureGrad(normals, textureCoordinate, texGradX, texGradY).a;
		float rD = textureGrad(normals, textureCoordinate + vec2(eps, 0.0), texGradX, texGradY).a;
		float uD = textureGrad(normals, textureCoordinate + vec2(0.0, eps), texGradX, texGradY).a;
		#endif

		float xDiff = (cD - rD) / eps;
		float yDiff = (cD - uD) / eps;

		heightNormal = normalize(vec3(2.0 * xDiff * PARALLAX_DEPTH, 2.0 * yDiff * PARALLAX_DEPTH, -4.0));
		#endif

		viewNormal = tbn * heightNormal;
	}
	#endif

	// Get specular data from specular texture
	float smoothness = specTex[SPEC_CHANNEL_SMOOTHNESS];
	float metallic = specTex[SPEC_CHANNEL_METALNESS];
	float emissive = specTex[SPEC_CHANNEL_EMISSIVE];

	#if SPEC_CHANNEL_EMISSIVE == 3
	emissive -= step(1.0, emissive);
	#endif

	#ifdef FORCE_WET_EFFECT
	smoothness = mix(smoothness, 1.0, saturate(wetnessModulator * saturate(1.0 - metallic) * max(1.0 - isEyeInWater, 0.0)));
	#endif

	// Darker albedo when wet
	albedo.rgb = pow(albedo.rgb, vec3(1.0 + wetnessModulator * (1.0 - metallic) * 0.3));


	// Fix impossible normal angles
	vec3 viewDir = -normalize(viewPos.xyz);
	// make outright impossible
	viewNormal.xyz = normalize(viewNormal.xyz + N / (sqrt(saturate(dot(viewNormal, viewDir)) + 0.001)));

	float isTransparent = step(abs(materialIDs - 7.), 0.5);
	metallic *= 1.0 - isTransparent;
	smoothness = mix(smoothness, 0.992, isTransparent);

	gbuffer.albedo = albedo;
	gbuffer.normal = viewNormal.xyz;
	gbuffer.mcLightmap = mcLightmap;
	gbuffer.smoothness = smoothness;
	gbuffer.metalness = metallic;
	gbuffer.materialID = (materialIDs + 0.1) / 255.0;
	gbuffer.emissive = emissive;
	gbuffer.geoNormal = N.xyz;
	gbuffer.depth = 0.0;

	#ifndef SPEC_EMISSIVE
	gbuffer.emissive = 0.0;
	#endif




	vec4 frag0, frag1, frag2;

	OutputGBufferDataSolid(gbuffer, frag0, frag1, frag2);

	gl_FragData[0] = frag0;
	gl_FragData[1] = frag1;
	gl_FragData[2] = frag2;

}

/* DRAWBUFFERS:012 */
