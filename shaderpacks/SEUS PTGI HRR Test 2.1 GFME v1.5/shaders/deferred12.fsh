#version 330 compatibility

/*
 _______ _________ _______  _______  _
(  ____ \\__   __/(  ___  )(  ____ )( )
| (    \/   ) (   | (   ) || (    )|| |
| (_____    | |   | |   | || (____)|| |
(_____  )   | |   | |   | ||  _____)| |
      ) |   | |   | |   | || (      (_)
/\____) |   | |   | (___) || )       _
\_______)   )_(   (_______)|/       (_)

Do not modify this code until you have read the LICENSE.txt contained in the root directory of this shaderpack!

*/


in vec4 texcoord;

flat in vec3 lightVector;

flat in vec3 colorSkyUp;
flat in vec3 colorTorchlight;

flat in vec4 skySHR;
flat in vec4 skySHG;
flat in vec4 skySHB;


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/Common.inc"
#include "/lib/Materials.inc"
#include "/lib/GBufferData.inc"


const int shadowMapResolution = 4096; // Higher value impacts performance costs, but can get better shadow, and increase path tracing distance. Please increase the shadow distance at the same time. 4096 - 80 blocks path tracing. 8192 - 125 blocks path tracing. 16384 - 200 blocks path tracing, requires at least 6GB VRAM. 34768 - 330 blocks of path tracing, requires at least 20GB VRAM. [4096 8192 16384 32768]
const float shadowDistance 			= 120.0; // Shadow distance. Set lower if you prefer nicer close shadows. Set higher if you prefer nicer distant shadows. [80.0 120.0 160.0 200.0 240.0 280.0 320.0 360.0 400.0 440.0 480.0]
const float shadowIntervalSize 		= 1.0f;
const bool 	shadowHardwareFiltering0 = true;

const bool 	shadowtexMipmap = true;
const bool 	shadowtex1Mipmap = false;
const bool 	shadowtex1Nearest = false;
const bool 	shadowcolor0Mipmap = false;
const bool 	shadowcolor0Nearest = false;
const bool 	shadowcolor1Mipmap = false;
const bool 	shadowcolor1Nearest = false;

const float shadowDistanceRenderMul = 1.0f;

const int RGBA8 		= 0;
const int RGBA16 		= 0;
const int RGBA16F 		= 0;
const int RGBA32F 		= 0;
const int colortex0Format = RGBA8;
const int colortex1Format = RGBA16;
const int colortex2Format = RGBA16;
const int colortex3Format = RGBA16;
const int colortex4Format = RGBA32F;
const int colortex5Format = RGBA32F;
const int colortex6Format = RGBA32F;
const int colortex7Format = RGBA16F;

const bool colortex3Clear = false;
const bool colortex4Clear = false;
const bool colortex5Clear = false;
const bool colortex6Clear = false;

const int 	superSamplingLevel 		= 0;

const float	sunPathRotation 		= -40.0f; // Sun path angles. [-90.0f -80.0f -70.0f -60.0f -50.0f -40.0f -30.0f -20.0f -10.0f 0.0f 10.0f 20.0f 30.0f 40.0f 50.0f 60.0f 70.0f 80.0f 90.0f]

const int 	noiseTextureResolution  = 64;

const float ambientOcclusionLevel 	= 0.06f;

const float wetnessHalflife = 100.0;
const float drynessHalflife = 100.0;
const float eyeBrightnessHalflife = 5.0;

const float RAY_TRACING_RESOLUTION = (shadowMapResolution * MC_SHADOW_QUALITY) / 2.0;
const float RAY_TRACING_DIAMETER_TEMP = floor(pow(RAY_TRACING_RESOLUTION, 2.0 / 3.0));
const float RAY_TRACING_DIAMETER = RAY_TRACING_DIAMETER_TEMP - mod(RAY_TRACING_DIAMETER_TEMP, 2.0) - 1.0;


vec2 Texcoord;


/******************************************************************************/


vec2 worldPosToShadowCoord(vec3 worldPos)
{
    worldPos.x += worldPos.y * RAY_TRACING_DIAMETER;
    worldPos.y = worldPos.z + floor(worldPos.x / RAY_TRACING_RESOLUTION) * RAY_TRACING_DIAMETER;
    worldPos.x = mod(worldPos.x, RAY_TRACING_RESOLUTION);
    return worldPos.xy;
}

struct RayTrace{vec3 rayPos; vec3 rayDirInv; vec3 rayDirSign; vec3 rayDir; vec3 nextBlock;};

RayTrace startTrace(Ray ray)
{
	RayTrace raytrace;
	raytrace.rayPos = floor(ray.origin);
	raytrace.rayDirInv = abs(vec3(length(ray.direction)) / (ray.direction + 1e-07));
	raytrace.rayDirSign = sign(ray.direction);
	raytrace.rayDir = (raytrace.rayDirSign * (raytrace.rayPos - ray.origin) + raytrace.rayDirSign * 0.5 + 0.5) * raytrace.rayDirInv;
	raytrace.nextBlock = vec3(0.0);
	return raytrace;
}

void Stepping(inout RayTrace v)
{
	v.nextBlock = step(v.rayDir.xyz, v.rayDir.yzx);
	v.nextBlock *= -v.nextBlock.zxy + vec3(1.0);
	v.rayDir += v.nextBlock * v.rayDirInv, v.rayPos += v.nextBlock * v.rayDirSign;
}


#include "/program/template/BlockShapes.glsl"


float RayTracedShadow(vec3 worldPos, vec3 worldNormal, vec3 worldGeoNormal, vec3 worldDir, float parallaxOffset)
{
	vec3 rayOrigin = worldPos + 0.0001 * length(worldPos) * worldNormal + FractedCameraPosition -
		(parallaxOffset * 0.3 / (saturate(dot(worldGeoNormal, -worldDir)) + 1e-06) + 0.0001) * worldDir;
	rayOrigin = clamp(rayOrigin + vec3(RAY_TRACING_DIAMETER / 2.0 - 1.0), vec3(-1.0), vec3(RAY_TRACING_DIAMETER - 1.0));
	if(any(greaterThan(abs(rayOrigin - vec3(RAY_TRACING_DIAMETER / 2.0)), vec3(RAY_TRACING_DIAMETER / 2.0))))
		return 1.0;
	Ray ray = MakeRay(rayOrigin, worldLightVector);
	RayTrace raytrace = startTrace(ray);

	float shadow = 1.0, blockID = 0.0, rayLength = 114514.0;
	vec2 shadowCoord = vec2(0.0);
	vec3 targetNormal = worldLightVector;
	Stepping(raytrace);
	for(int i = 0; i < 5; i++)
	{
		shadowCoord = worldPosToShadowCoord(raytrace.rayPos);
		blockID = texelFetch(shadowcolor, ivec2(shadowCoord), 0).w * 255.0;
		if((blockID < 240.0 || abs(blockID - 248.0) < 7.0) && (blockID != 31.0 && abs(blockID - 38.5) > 1.0) &&
			c(raytrace.rayPos, blockID, ray, rayLength, targetNormal))
		{
			if(abs(blockID - 33.5) < 2.0)
			{
				shadow = 0.0;
				break;
			}
			vec3 rayPos = fract(ray.origin + ray.direction * rayLength) - 0.5;
			vec2 texCoordOffset = vec2(0.0);
			texCoordOffset = vec2(rayPos.z * -targetNormal.x, -rayPos.y) * abs(targetNormal.x);
			texCoordOffset = vec2(rayPos.x, rayPos.z * targetNormal.y) * abs(targetNormal.y);
			texCoordOffset = vec2(rayPos.x * targetNormal.z, -rayPos.y) * abs(targetNormal.z);
			vec4 blockData = texelFetch(shadowcolor1, ivec2(shadowCoord), 0);
			float textureResolusion = TEXTURE_RESOLUTION;
			#ifdef ADAPTIVE_PATH_TRACING_RESOLUTION
			if(blockID < 67.0 || abs(blockID - 111.0) < 29.0)
				textureResolusion = exp2(blockData.w * 255.0);
			#endif
			vec2 terrainSize = textureSize(colortex3, 0) / textureResolusion;
			vec2 texCoordPT = (floor(blockData.xy * terrainSize) + 0.5 + texCoordOffset.xy) / terrainSize;
			float isShadow = texture2DLod(colortex3, texCoordPT, 0).w;
			if((isShadow > 0.1 || abs(blockID - 61.5) > 31.0) && blockID != 37)
			{
				shadow = 0.0;
				break;
			}
			rayLength = 114514.0;
		}
		Stepping(raytrace);
	}


	float depth = length(worldPos);
	shadow = mix(shadow, 1.0, saturate(rayLength * 5.0 - 0.1 * depth - 0.2));

	return shadow;
}


/******************************************************************************/



vec3 WorldPosToShadowProjPosBias(vec3 worldPos, vec3 worldNormal, out float dist, out float distortFactor)
{
	vec3 sn = normalize((shadowModelView * vec4(worldNormal.xyz, 0.0)).xyz) * vec3(1, 1, -1);

	vec4 sp = (shadowModelView * vec4(worldPos, 1.0));
	sp = shadowProjection * sp;
	sp /= sp.w;

	dist = length(sp.xy);
	distortFactor = (1.0f - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;

	sp.xyz += sn * 0.002 * distortFactor;
	sp.xy *= 0.95f / distortFactor;
	sp.z = mix(sp.z, 0.5, 0.8);
	sp = sp * 0.5f + 0.5f;		//Transform from shadow space to shadow map coordinates

	sp.xy *= 0.5;
	sp.xy += 0.5;

	return sp.xyz;
}

vec3 CalculateSunlightVisibility(vec4 screenSpacePosition, MaterialMask frnQIYJjVJ, vec3 worldGeoNormal, float parallaxOffset)
{

	vec3 worldPos = (gbufferModelViewInverse * screenSpacePosition).xyz;
	float worldDsitance = length(worldPos.xyz);


	if (frnQIYJjVJ.grass > 0.5)
		worldGeoNormal.xyz = vec3(0, 1, 0);


	float dist;
	float distortFactor;
	vec3 shadowProjPos = WorldPosToShadowProjPosBias(worldPos.xyz, worldGeoNormal, dist, distortFactor);
	vec2 stainedGlassShadowProjPos = shadowProjPos.st - vec2(0.5, 0.0);


	float shading = 0.0;
	float stainedGlassShadow = 0.0;
	vec3 result = vec3(0.0);
	vec3 stainedGlassColor = vec3(0.0);

	float shadowMapResolutionForBlur = shadowMapResolution * shadowDistance / 120.0;

	float diffthresh = dist + 0.10f;
		  diffthresh *= 2.0f / (shadowMapResolutionForBlur / 2048);


	float vpsSpread = 0.105 / distortFactor;

	float avgDepth = 0.0;

	float shadowMapResolutionInverse = 8.0 * vpsSpread / shadowMapResolutionForBlur;

	for (int i = -1; i <= 1; i++)
	{
		for (int j = -1; j <= 1; j++)
		{
			vec2 lookupCoord = shadowProjPos.xy + vec2(i, j) * shadowMapResolutionInverse;
			float depthSample = texture2DLod(shadowtex1, lookupCoord, 2).x;
			avgDepth += pow(clamp(shadowProjPos.z - depthSample, 0.0, 0.025), 2.0);
		}
	}

	avgDepth /= 9.;
	avgDepth = sqrt(avgDepth);


	float spread = avgDepth * 0.11 * vpsSpread + 1.1 / shadowMapResolutionForBlur;

	vec3 noise = BlueNoiseTemporal(Texcoord.st);

	diffthresh *= 0.5 + avgDepth * 50.0;

	float dfs = 0.0003 * dist + (noise.z * 0.00005) + 0.00002 + avgDepth * 0.012 + 0.0003 * parallaxOffset + 0.00001 * worldDsitance;
	float shadowPosZ = shadowProjPos.z - dfs;

	float fi = noise.x * 0.1 - 0.1;
	float r = fi * 101.1592833;
	for (int i = 0; i < 25; i++)
	{
		fi += 0.1;
		r += 10.11592833;

		vec2 radialPos = vec2(cos(r), sin(r));
		vec2 coordOffset = radialPos * spread * sqrt(fi);
		vec2 stainedGlassShadowProjPosTemp = stainedGlassShadowProjPos + coordOffset;

		shading += shadow2DLod(shadowtex0, vec3(shadowProjPos.st + coordOffset, shadowPosZ), 0).x;
		stainedGlassShadow += shadow2DLod(shadowtex0, vec3(stainedGlassShadowProjPosTemp, shadowPosZ), 0).x;
		stainedGlassColor += texture2DLod(shadowcolor, vec2(stainedGlassShadowProjPosTemp), 2).rgb;
	}
	shading /= 25.;
	shading = saturate(shading * (1.0 + avgDepth * 5.0  / (abs(dot(worldGeoNormal, worldLightVector)) + 0.001)));
	result = vec3(shading);

	if(shading < 0.01)
		return result;

	stainedGlassShadow /= 25.0;
	stainedGlassColor /= 25.0;
	stainedGlassColor *= stainedGlassColor;
	result = mix(result * stainedGlassColor, result, vec3(stainedGlassShadow));


	// CAUSTICS
	// water shadow (caustics)
	float waterShadow = shadow2DLod(shadowtex0, vec3(shadowProjPos.st - vec2(0.0, 0.5), shadowProjPos.z - 0.0012 * diffthresh - noise.z * 0.0001), 3).x;

	if(waterShadow < 1.)
	{
		float waterDepth = abs(texture2DLod(shadowcolor1, shadowProjPos.st - vec2(0.0, 0.5), 3).x * 256.0 - (worldPos.y + cameraPosition.y));

		float caustics = GetCausticsDeferred(worldPos, worldLightVector, waterDepth);

		result = mix(result * caustics, result, vec3(waterShadow));
	}


	return result;
}

float ScreenSpaceShadow(vec3 origin, float depth, vec3 viewDir, vec3 geoNormal, MaterialMask OmcxSfXfkJ, float randomness)
{
	if (OmcxSfXfkJ.sky > 0.5)
		return 1.0;


	float fov = 2.0*atan( 1.0/gbufferProjection[1][1] ) * 180.0 / 3.14159265;

	vec3 rayPos = origin;
	vec3 rayDir = lightVector * -origin.z * 0.000035 * fov;

	float NdotL = saturate(dot(lightVector, geoNormal));

	rayPos += geoNormal * 0.0003 * max(abs(origin.z), 0.1) / (NdotL + 0.01);

	if (OmcxSfXfkJ.grass < 0.5 && OmcxSfXfkJ.leaves < 0.5)
	{
		rayPos += geoNormal * 0.00001 * -origin.z * fov * 0.15;
		rayPos += rayDir * 13000.0 * min(ScreenTexel.x, ScreenTexel.y) * 0.15;
	}

	float zThickness = 0.025 * -origin.z;
	float shadow = 1.0;
	float absorption = 0.0;
	absorption += 0.5 * OmcxSfXfkJ.grass;
	absorption += 0.85 * OmcxSfXfkJ.leaves;
	absorption = pow(absorption, sqrt(length(origin)) * 0.5);

	float ds = 1.0;
	for (int i = 0; i < 12; i++)
	{
		rayPos += rayDir * ds;

		ds += 0.3;

		vec3 thisRayPos = rayPos + rayDir * randomness * ds;

		vec2 rayProjPos = ProjectBack(thisRayPos).xy;

		if(abs(rayProjPos.x - HalfScreen.x) > HalfScreen.x || abs(rayProjPos.y - HalfScreen.y) > HalfScreen.y)
			break;

		TemporalJitterProjPos(rayProjPos);

		vec3 samplePos = GetViewPositionNoJitter(rayProjPos.xy, GetDepth(rayProjPos.xy * 0.5)).xyz; // half res rendering fix

		float depthDiff = samplePos.z - thisRayPos.z;

		if (depthDiff > 0.0 && depthDiff < zThickness)
			shadow *= absorption;

		if(shadow < 0.01)
			break;
	}

	return shadow;
}

float OrenNayar(vec3 normal, vec3 eyeDir, vec3 lightDir)
{
	// calculate intermediary values
	float NdotL = dot(normal, lightDir);
	float NdotV = dot(normal, eyeDir);

	float angleVN = acos(NdotV);
	float angleLN = acos(NdotL);

	float alpha = max(angleVN, angleLN);
	float beta = min(angleVN, angleLN);

	float gamma = dot(eyeDir - normal * NdotV, lightDir - normal * NdotL);

	float C = sin(alpha) * tan(beta);

	// put it all together
	float L1 = max(0.0, NdotL) * (0.82665 + 0.34681 * max(0.0, gamma) * C);

	//return max(0.0f, surface.NdotL * 0.99f + 0.01f);
	return clamp(L1, 0.0f, 1.0f);
}

float G1V(float dotNV, float k)
{
	return 1.0 / (dotNV * (1.0 - k) + k);
}

vec3 SpecularGGX(vec3 N, vec3 V, vec3 L, float roughness, float F0)
{
	const float pi = 3.14159265359;
	float alpha = roughness * roughness;

	vec3 H = normalize(V + L);

	float dotNL = saturate(dot(N, L));
	float dotNV = saturate(dot(N, V));
	float dotNH = saturate(dot(N, H));
	float dotLH = saturate(dot(L, H));

	float F, D, vis;

	float alphaSqr = alpha * alpha;
	float denom = dotNH * dotNH * (alphaSqr - 1.0) + 1.0;
	D = alphaSqr / (pi * denom * denom);

	float dotLH5 = pow(1.0f - dotLH, 5.0);
	F = F0 + (1.0 - F0) * dotLH5;

	float k = alpha / 2.0;
	vis = G1V(dotNL, k) * G1V(dotNV, k);

	vec3 specular = vec3(dotNL * D * F * vis) * colorSunlight * (saturate(worldSunVector.y * 10.0) + 0.001);

	//specular = vec3(0.1);
	#ifndef PHYSICALLY_BASED_MAX_ROUGHNESS
	specular *= saturate(pow(1.0 - roughness, 0.7) * 2.0);
	#endif


	return specular;
}

 float e(float v,float z)
 {
   float x=1.;
   #ifdef FULL_RT_REFLECTIONS
   x=clamp(pow(v,.125)+z,0.,1.);
   #else
   x=clamp(v*10.-7.,0.,1.);
   #endif
   return x;
 }
 void main()
 {
   Texcoord=texcoord.xy;
   GBufferData v=GetGBufferData(Texcoord);
   MaterialMask x=CalculateMasks(v.materialID,Texcoord);
   vec4 s=GetViewPosition(Texcoord.xy,v.depth),a=gbufferModelViewInverse*vec4(s.xyz,1.),i=gbufferModelViewInverse*vec4(s.xyz,0.);
   vec3 f=normalize(s.xyz),m=normalize(i.xyz),y=normalize((gbufferModelViewInverse*vec4(v.normal,0.)).xyz),c=normalize((gbufferModelViewInverse*vec4(v.geoNormal,0.)).xyz);
   float r=length(s.xyz);
   vec3 n=vec3(0.),t=y;
   if(x.grass>.5)
     y=vec3(0.,1.,0.);
   vec3 w=texture2DLod(colortex7,Texcoord.xy+vec2(0.,HalfScreen.y),0).xyz*10.,T=w*v.albedo.xyz;
   const float h=RAY_TRACING_DIAMETER/2.-5.;
   if(r>h)
     {
       vec3 F=FromSH(skySHR,skySHG,skySHB,y);
       F*=v.mcLightmap.y;
       vec3 R=F*4.5;
       R+=v.mcLightmap.x*colorTorchlight*.0925;
       R*=v.albedo.xyz;
       T=mix(T,R,vec3(saturate((r-h)*.2)));
     }
   n.xyz=T+v.albedo.xyz*1e-05;
   #ifdef HELD_LIGHT
   {
     float G=heldBlockLightValue/16.,Y=OrenNayar(t,-m,-m),o=1./(dot(i.xyz,i.xyz)+.3);
     n+=v.albedo.xyz*G*o*Y*colorTorchlight*.3;
   }
   #endif
   #ifdef VISUALIZE_DANGEROUS_LIGHT_LEVEL
   {
     float G=BlockLightTorchLinear(v.mcLightmap.x)*16.;
     n.x+=step(G,7.);
   }
   #endif
   float G=24.*(1.-sqrt(wetness)),l=OrenNayar(y,-m,worldLightVector);
   if(x.leaves>.5)
     l=mix(l,.5,.5);
   v.metalness*=1.0-x.grass;
   vec3 randomness=rand(Texcoord.xy+sin(frameTimeCounter));
   if(wetness<.99)
     {
       vec3 Y=CalculateSunlightVisibility(s,x,c,v.parallaxOffset)*G;
       #ifdef SUNLIGHT_LEAK_FIX
       Y*=mix(1.0,saturate(v.mcLightmap.y*100.),step(float(isEyeInWater),.5));
       #endif
       #ifdef RAY_TRACE_SHADOW
       Y*=RayTracedShadow(a.xyz,y,c,f,v.parallaxOffset);
       #endif
       #ifdef SCREEN_SPACE_SHADOW
       Y*=ScreenSpaceShadow(s.xyz,v.depth,f.xyz,v.geoNormal.xyz,x,randomness.x);
       #endif
	   #ifdef CLOUD_SHADOW
	   Y*=CloudShadow(a.xyz, worldLightVector);
	   #endif
       n+=TintUnderwaterDepth(DoNightEyeAtNight(l*v.albedo.xyz*Y*colorSunlight,timeMidnight));
       if(isEyeInWater<.5)
         {
           vec3 R=SpecularGGX(y,-m,worldLightVector,1.-v.smoothness,v.metalness*.96+.04)*Y;
           R*=mix(vec3(1.),v.albedo.xyz,vec3(v.metalness));
           R*=mix(1.,.5,x.grass);
           n*=1.-e(v.smoothness,v.metalness)*v.metalness,n+=DoNightEyeAtNight(R,timeMidnight);
         }
     }
   else
     {
	   n*=1.-e(v.smoothness,v.metalness)*v.metalness;
	 }
   if(x.sky>.5)
     {
       vec3 p=m.xyz;
       if(isEyeInWater>0)
         p.xyz=refract(p.xyz,vec3(0.,-1.,0.),1.3);
       vec3 q=SkyShading(p.xyz,worldSunVector.xyz);
       n=q;
       vec3 J=AtmosphereAbsorption(p.xyz,AtmosphereExtent);
       n+=v.albedo.xyz*J*.5;
       n+=RenderSunDisc(p,worldSunVector,colorSunlight)*J*2000.;
       CloudPlane(n,vec3(0.),-p,worldLightVector,worldSunVector,colorSunlight,colorSkyUp,q,timeMidnight,true);
     }
   vec3 colorTemp=vec3(0.0);
   if(v.emissive>0.)
     {
       colorTemp+=v.emissive*GI_LIGHT_BLOCK_INTENSITY;
     }
   else
     {
   	   if(x.glowstone>.5)
         colorTemp+=GI_LIGHT_BLOCK_INTENSITY;
       if(x.torch>.5)
         colorTemp+=pow(length(v.albedo.xyz),2.)*1.5*GI_LIGHT_TORCH_INTENSITY;
       if(x.lava>.5)
         colorTemp+=.75*GI_LIGHT_BLOCK_INTENSITY;
       if(x.fire>.5)
         colorTemp+=3.*GI_LIGHT_TORCH_INTENSITY;
       if(x.litFurnace>.5)
         {
           float d=saturate(v.albedo.x-(v.albedo.y+v.albedo.z)/2.-.2);
           if(d>0.||v.albedo.xyz==vec3(1.))
               colorTemp+=GI_LIGHT_BLOCK_INTENSITY*vec3(2.,.35,.025);
         }
       if(x.beacon>.5)
         {
           float d=v.albedo.y/v.albedo.z;
           if(d>1.01||(d<1.009&&d>=1.))
               colorTemp+=GI_LIGHT_BLOCK_INTENSITY;
         }
       if(texture2D(depthtex1,Texcoord).x<texture2D(depthtex2,Texcoord).x)
         {
           if(Texcoord.x<.25)
             colorTemp+=heldBlockLightValue2*GI_LIGHT_BLOCK_INTENSITY/16.;	// Left hand
           else if(Texcoord.x<.5&&heldBlockLightValue2!=heldBlockLightValue)
             colorTemp+=heldBlockLightValue*GI_LIGHT_BLOCK_INTENSITY/16.;	// Right hand
         }
     }
   colorTemp+=nightVision*0.05+1e-4;
   n+=colorTemp*v.albedo.rgb;
   n*=.001;
   n=LinearToGamma(n);
   n+=randomness*(1./65535.);
   gl_FragData[0]=vec4(n.xyz,1.);
 };




/* DRAWBUFFERS:1 */
