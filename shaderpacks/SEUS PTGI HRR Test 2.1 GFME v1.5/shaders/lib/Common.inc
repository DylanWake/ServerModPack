#include "DataPacking.inc"
#include "TAA.inc"


vec3 TransformInputColor(vec3 c)
{
	return c * inverse(mat3(vec3(1.2, -0.2, 0.0),
				    vec3(0.0, 1.0, 0.0),
					vec3(0.0, 0.0, 1.0)));
}

vec3 TransformOutputColor(vec3 c)
{
	return c * mat3(vec3(1.2, -0.2, 0.0),
				    vec3(0.0, 1.0, 0.0),
					vec3(0.0, 0.0, 1.0));
}

float saturate(float x)
{
	return clamp(x, 0.0, 1.0);
}

vec3 saturate(vec3 x)
{
	return clamp(x, vec3(0.0), vec3(1.0));
}

vec2 saturate(vec2 x)
{
	return clamp(x, vec2(0.0), vec2(1.0));
}

// polynomial smooth min (k = 0.1); https://www.iquilezles.org/www/articles/smin/smin.htm
float SmoothMin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float SmoothMax(float a, float b, float k)
{
    return -SmoothMin(-a, -b, k);
}

vec2 EncodeNormal(vec3 normal)
{
	float p = sqrt(normal.z * 8.0 + 8.0);
	return vec2(normal.xy / p + 0.5);
}

vec3 DecodeNormal(vec2 enc)
{
	vec2 fenc = enc * 4.0 - 2.0;
	float f = dot(fenc, fenc);
	vec3 normal;
	normal.xy = fenc * sqrt(1.0 - f / 4.0);
	normal.z = 1.0 - f / 2.0;
	return normal;
}

vec4 GetViewPosition(in vec2 coord, in float depth)
{
	vec2 tcoord = coord;
	TemporalJitterProjPosInv01(tcoord);

	vec4 fragposition = gbufferProjectionInverse * vec4(tcoord.st * 4.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

	return fragposition;
}

vec4 GetViewPositionNoJitter(in vec2 coord, in float depth)
{
	vec4 fragposition = gbufferProjectionInverse * vec4(coord.st * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

	return fragposition;
}

vec3 ProjectBack(vec3 cameraSpace)
{
    vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
    vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
    vec3 screenSpace = 0.5 * NDCSpace + 0.5;
    return screenSpace;
}

vec3 WorldPosToShadowProjPos(vec3 worldPos)
{
	vec4 sp = (shadowModelView * vec4(worldPos, 1.0));
	sp = shadowProjection * sp;
	sp /= sp.w;

	float dist = length(sp.xy);
	float distortFactor = (1.0f - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;
	sp.xy *= 0.95f / distortFactor;
	sp.z = mix(sp.z, 0.5, 0.8);
	sp = sp * 0.5f + 0.5f;		//Transform from shadow space to shadow map coordinates

	//move to quadrant
	sp.xy *= 0.5;
	sp.xy += 0.5;

	return sp.xyz;
}

float 	ExpToLinearDepth(in float depth)
{
	vec2 a = vec2(depth * 2.0 - 1.0, 1.0);

	vec2 d = a * mat2(gbufferProjectionInverse[2].zw,
					  gbufferProjectionInverse[3].zw);

	d.x /= d.y;

	return -d.x;
}

float GetDepthLinear(in vec2 coord)
{
	return ExpToLinearDepth(texture2D(depthtex1, coord).x);
}

float GetDepth(vec2 coord)
{
	return texture2D(depthtex1, coord).x;
}

float GetDepth2(vec2 coord)
{
	return texture2D(depthtex0, coord).x;
}

vec3 GetNormals(vec2 coord)
{
	return DecodeNormal(texture2D(colortex2, coord).xy);
}

void GetBothNormals(vec2 coord, out vec3 normal, out vec3 geoNormal)
{
	vec4 texData = texture2DLod(colortex2, coord, 0);

	normal = DecodeNormal(texData.xy);
	geoNormal = DecodeNormal(texData.zw);
}

vec2 LockRenderPixelCoord(vec2 coord)
{
	coord = (floor(coord * ScreenSize) + 0.5) * ScreenTexel;

	return coord;
}

vec3 LinearToGamma(vec3 c)
{
	return pow(c, vec3(1.0 / 2.2));
}

vec3 GammaToLinear(vec3 c)
{
	return pow(c, vec3(2.2));
}

float curve(float x)
{
	return x * x * (3.0 - 2.0 * x);
}

float Luminance(in vec3 color)
{
	return dot(color.rgb, vec3(0.2125f, 0.7154f, 0.0721f));
}

vec3 rand(vec2 coord)
{
	float dotCoord = dot(coord, vec2(12.9898, 78.223));
	float noiseX = fract(sin(dotCoord	   ) * 43758.5453);
	float noiseY = fract(sin(dotCoord * 2.0) * 43758.5453);
	float noiseZ = fract(sin(dotCoord * 3.0) * 43758.5453);

	return vec3(noiseX, noiseY, noiseZ);
}

vec3 hash33(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

vec3 BlueNoiseTemporal(vec2 coord)
{
	const vec3 irrationals = vec3(0.447213595, 1.41421356, 1.61803398);

	vec2 noiseCoord = vec2(coord.st * ScreenSize) / 64.0;

	vec3 n = texture2D(noisetex, noiseCoord).rgb;

	n = fract(n + irrationals * (frameCounter % 64));

	return n;
}

float Get2DNoise(in vec2 pos)
{
	pos.xy += 0.5f;

	vec2 p = floor(pos);
	vec2 f = fract(pos);

	#ifdef CLOUDS_BLOCKY
	for (int i = 0; i < 3; i++)
	#endif
	{
		f *= f * (3.0f - 2.0f * f);
	}

	vec2 coord = (p.xy + f.xy  + 0.5f) / 64.0;
	float xy1 = texture2D(noisetex, coord).a;
	return xy1;
}

float Get3DNoise(in vec3 pos)
{
	pos.xyz += 0.5f;

	vec3 p = floor(pos);
	vec3 f = fract(pos);

	vec2 uv =  p.xy + p.z * vec2(17.0f) + f.xy + 0.5f;
	vec2 uv2 = uv + vec2(17.0f);

	vec2 coord =  uv  / 64.0;
	vec2 coord2 = uv2 / 64.0;
	float xy1 = texture2D(noisetex, coord).x;
	float xy2 = texture2D(noisetex, coord2).x;
	return mix(xy1, xy2, f.z);
}


/* https://www.shadertoy.com/view/XsX3zB
 *
 * The MIT License
 * Copyright © 2013 Nikita Miropolskiy
 *
 * ( license has been changed from CCA-NC-SA 3.0 to MIT
 *
 *   but thanks for attributing your source code when deriving from this sample
 *   with a following link: https://www.shadertoy.com/view/XsX3zB )
 *
 * ~
 * ~ if you're looking for procedural noise implementation examples you might
 * ~ also want to look at the following shaders:
 * ~
 * ~ Noise Lab shader by candycat: https://www.shadertoy.com/view/4sc3z2
 * ~
 * ~ Noise shaders by iq:
 * ~     Value    Noise 2D, Derivatives: https://www.shadertoy.com/view/4dXBRH
 * ~     Gradient Noise 2D, Derivatives: https://www.shadertoy.com/view/XdXBRH
 * ~     Value    Noise 3D, Derivatives: https://www.shadertoy.com/view/XsXfRH
 * ~     Gradient Noise 3D, Derivatives: https://www.shadertoy.com/view/4dffRH
 * ~     Value    Noise 2D             : https://www.shadertoy.com/view/lsf3WH
 * ~     Value    Noise 3D             : https://www.shadertoy.com/view/4sfGzS
 * ~     Gradient Noise 2D             : https://www.shadertoy.com/view/XdXGW8
 * ~     Gradient Noise 3D             : https://www.shadertoy.com/view/Xsl3Dl
 * ~     Simplex  Noise 2D             : https://www.shadertoy.com/view/Msf3WH
 * ~     Voronoise: https://www.shadertoy.com/view/Xd23Dh
 * ~
 *
 */

/* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
vec3 random3(vec3 c) {
  float j = 4096 * sin(dot(c,vec3(17.0, 59.4, 15.0)));
  vec3 r;
  r.z = fract(512.0*j);
  r.x = fract(64.0*j);
  r.y = fract(8.0*j);
  return r-0.5;
}

/* skew constants for 3d simplex functions */
const float F3 =  0.3333333;
const float G3 =  0.1666667;

/* 3d simplex noise */
float simplex3d(vec3 p) {
   /* 1. find current tetrahedron T and it's four vertices */
   /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
   /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/

   /* calculate s and x */
   vec3 s = floor(p + dot(p, vec3(F3)));
   vec3 x = p - s + dot(s, vec3(G3));

   /* calculate i1 and i2 */
   vec3 e = step(vec3(0.0), x - x.yzx);
   vec3 i1 = e*(1.0 - e.zxy);
   vec3 i2 = 1.0 - e.zxy*(1.0 - e);

   /* x1, x2, x3 */
   vec3 x1 = x - i1 + G3;
   vec3 x2 = x - i2 + 2.0*G3;
   vec3 x3 = x - 1.0 + 3.0*G3;

   /* 2. find four surflets and store them in d */
   vec4 w, d;

   /* calculate surflet weights */
   w.x = dot(x, x);
   w.y = dot(x1, x1);
   w.z = dot(x2, x2);
   w.w = dot(x3, x3);

   /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
   w = max(0.6 - w, 0.0);

   /* calculate surflet components */
   d.x = dot(random3(s), x);
   d.y = dot(random3(s + i1), x1);
   d.z = dot(random3(s + i2), x2);
   d.w = dot(random3(s + 1.0), x3);

   /* multiply d by w^4 */
   d *= pow(w, vec4(4.0));

   /* 3. return the sum of the four surflets */
   return dot(d, vec4(52.0));
}

vec4 ToSH(float value, vec3 dir)
{
	const float sqrtPI = sqrt(3.14159265359);
	value *= sqrtPI;

	vec4 coeffs;
	float value1 = value / 3.0;

	coeffs.x =  value * 0.5;
	coeffs.yzw = dir.yzx * vec3(-1.0, 1.0, -1.0) * value1;

	return coeffs;
}


vec3 FromSH(vec4 cR, vec4 cG, vec4 cB, vec3 lightDir)
{
	const float PI = 3.14159265 * 4.0;

	const float sqrt1OverPI = sqrt(1.0 / PI);
	const float sqrt3OverPI = sqrt(3.0 / PI);

	vec4 sh;

	sh.x = sqrt1OverPI;
	sh.yzw = sqrt3OverPI * lightDir.yzx * vec3(-1.0, 1.0, -1.0);

	vec3 result;
	result.r  = dot(sh,cR);
	result.g  = dot(sh,cG);
	result.b  = dot(sh,cB);

	return result.rgb;
}

struct Ray
{
    vec3 origin;
    vec3 direction;
    vec3 inv_direction;
};

Ray MakeRay(vec3 origin, vec3 direction)
{
    vec3 inv_direction = vec3(1.0) / direction;
    return Ray(
        origin,
        direction,
        inv_direction
    );
}

vec3 DoNightEyeAtNight(in vec3 color, float timeFactor)
{
	float luminance = Luminance(color);

	float rodFactor = 0.6f / (luminance * 1000.0 + 1.0);

	color = mix(color, luminance * vec3(0.3, 0.6, 1.35), vec3(rodFactor * timeFactor));

	return color;
}

vec3 GetWaterAbsorption()
{
	return vec3(0.25, 0.04, 0.01);
}

vec3 GetLavaAbsorption()
{
	return vec3(0.0, 0.05, 0.2);
}

const float WaterM = 0.03 * WATER_FOG_DENSITY;

vec3 TintUnderwaterDepth(vec3 color)
{
	if (isEyeInWater > 0)
	{
		float underwaterDepth = 1.0 - (eyeBrightnessSmooth.y / 240.);
		color *= exp(-(GetWaterAbsorption() + WaterM) * underwaterDepth * 8.0);
	}

	return color;
}

void UnderwaterFog(inout vec3 color, float eyeLength, vec3 eyeDir, vec3 skyColor, vec3 sunColor)
{
	float underwaterDepth = 1.0 - (eyeBrightnessSmooth.y / 240.0);
	underwaterDepth *= 16.0;

	float x = eyeLength * 0.2;
	float weight = eyeLength / far;
	x = (eyeLength - x) * weight + x ;

	const float fD = WaterM * 5.0;
	vec3 wAK = saturate(GetWaterAbsorption() * 4.0) + fD;
	vec3 wFA = vec3(0.1 * fD);
	float v = eyeDir.y - 1.0;

	color *= exp(-wAK * x);

	vec3 w = wFA / (v * wAK) * (exp(-wAK * (underwaterDepth - v * x)) - exp(-underwaterDepth * wAK));

	color += max(vec3(0.0), w * (sunColor * 0.0005 * (1.0 - wetness * 0.75) + skyColor * 0.00025 * (1.0 - wetness * 0.5))) * (eyeBrightnessSmooth.y + 1.0);
}

void UnderLavaFog(inout vec3 color, float eyeLength, vec3 eyeDir)
{
	float underwaterDepth = 1.0 - (eyeBrightnessSmooth.y  / 240.0);

	float x = eyeLength * 5.0;
	vec3 wAK = GetLavaAbsorption() + WaterM;
	vec3 wFA = vec3(0.15 * WaterM);
	float v = eyeDir.y - 1.0;

	color *= exp(-wAK * x);

	vec3 w = wFA / (v * wAK) * (exp(-wAK * (underwaterDepth - v * x)) - exp(-underwaterDepth * wAK));

	color += max(vec3(0.0), w * vec3(1.,.08,0.));
}

void NetherFog(inout vec3 color, float eyeLength, vec3 eyeDir)
{

	float x = pow(eyeLength, 2.0) / 24.;
	vec3 wAK = -saturate(vec3(0.00001) / fogColor);
	float fD = WaterM;
	vec3 wFA = vec3(0.15);

	wAK -= fD;
	wFA *= fD / wAK;

	color *= exp(wAK * x);

	vec3 w = wFA * (-exp(wAK) + exp(wAK * (1.0 + x)));

	color += max(vec3(0.0), w * fogColor * 0.00025);
}

void TheEndFog(inout vec3 color, float eyeLength, vec3 eyeDir)
{

	float x = pow(eyeLength, 2.0) / 64;
	vec3 wAK = -vec3(0.1);
	float fD = WaterM * 0.1;
	vec3 wFA = vec3(0.15);

	wAK -= fD;
	wFA *= fD / wAK;

	color *= exp(wAK * x);

	vec3 w = wFA * (-exp(wAK) + exp(wAK * (1.0 + x)));

	color += max(vec3(0.0), w * vec3(0.1) * 0.00025);
}

vec4 GetCausticsTexComposite(vec2 coord)
{
	vec2 lookupCoord = vec2(coord.x, (coord.y - floor(fract(frameTimeCounter) * 60.0f)) / 60.0f);
	return texture2DLod(colortex4, lookupCoord.st, 0);
}

float GetCausticsComposite(vec3 worldPos, vec3 worldLightVector, float waterDepth)
{
	vec3 causticPos = worldPos.xyz + cameraPosition.xyz;
	vec3 refractLightVector = refract(worldLightVector, vec3(0.0, 1.0, 0.0), 0.75);
	causticPos += refractLightVector * (causticPos.y / refractLightVector.y);

	vec4 causticsTex = GetCausticsTexComposite(fract(causticPos.xz / 2.0));

	float depthBlend = sqrt(waterDepth / 3.0);

	float caustics = pow(causticsTex.r, saturate(depthBlend * 0.5 + 0.5));
	caustics = mix(caustics, causticsTex.g, saturate(depthBlend - 1.0));
	caustics = mix(caustics, causticsTex.b, saturate(depthBlend - 2.0));
	caustics = mix(caustics, causticsTex.a, saturate(depthBlend - 3.0));

	return caustics * 10.0 / (depthBlend + 1.);
}

float GetCausticsDeferred(vec3 worldPos, vec3 worldLightVector, float waterDepth)
{
	vec3 causticPos = worldPos.xyz + cameraPosition.xyz;
	vec3 refractLightVector = refract(worldLightVector, vec3(0.0, 1.0, 0.0), 0.75);
	causticPos += refractLightVector * (causticPos.y / refractLightVector.y);
	// causticPos.x += 0.3;

	vec2 causticCoord = mod(causticPos.xz * 0.125, vec2(0.242)) + vec2(0.008, 0.508);

	float caustic0 = texture2D(colortex7, causticCoord					).a;
	float caustic1 = texture2D(colortex7, causticCoord + vec2(0.25, 0.0)).a;
	float caustic2 = texture2D(colortex7, causticCoord + vec2(0.5 , 0.0)).a;
	float caustic3 = texture2D(colortex7, causticCoord + vec2(0.75, 0.0)).a;

	float depthBlend = sqrt(waterDepth / 3.0);

	float caustics = pow(caustic0, saturate(depthBlend * 0.5 + 0.5));
	caustics = mix(caustics, caustic1, saturate(depthBlend - 1.0));
	caustics = mix(caustics, caustic2, saturate(depthBlend - 2.0));
	caustics = mix(caustics, caustic3, saturate(depthBlend - 3.0));

	return caustics * 10.0 / (depthBlend + 1.);
}

// https://pubs.rsc.org/en/content/articlehtml/2019/nr/c9nr01707k
//
// Mie
// g : ( -0.75, -0.999 )
//      3 * ( 1 - g^2 )               1 + c^2
// F = ----------------- * -------------------------------
//      2 * ( 2 + g^2 )     ( 1 + g^2 - 2 * g * c )^(3/2)
float PhaseMie( float g, float LdotV, float LdotV2 ) {
	float gg = g * g;

	float a = (1.0 - gg) * LdotV2;

	float b = 1.0 + gg - 2.0 * g * LdotV;
	b *= sqrt(b);
	b *= 2.0 + gg;

	return 1.5 * a / b;
}

const vec3 Rayleigh = vec3(0.17, 0.40, 0.99);
const vec3 exp2Rayleigh = exp2(-Rayleigh * 0.2);

const float AtmosphereMie = 0.005;
const float AtmosphereDensity = 0.14;
const float AtmosphereDensityFalloff = 0.5;
const float AtmosphereExtent = 80.0;

const vec3 MplusR = AtmosphereMie + Rayleigh;

vec3 AtmosphereAbsorption(vec3 dir, float depth)
{
	if (dir.y < 0.0 && depth > 10.0)
		return vec3(0.0);

	float rDFv = AtmosphereDensityFalloff * dir.y;

	vec3 absorption;

	absorption = exp((-MplusR - wetness * 0.5) * (AtmosphereDensity / rDFv) * (1.0- exp(-rDFv * depth)));

	return absorption;
}

vec3 SunAbsorptionAtAltitude(float sunlightDir, float altitude)
{
	float rDFs = AtmosphereDensityFalloff * sunlightDir;
	float rDFa = AtmosphereDensityFalloff * altitude;

	return exp(AtmosphereDensity/rDFs * (-MplusR * exp(-rDFa) - exp(-rDFa - 1000*rDFs)));
}

vec3 SunlightColorFromSunVector(vec3 worldSunVector)
{
	vec3 color = AtmosphereAbsorption(worldSunVector, AtmosphereExtent);
	color *= saturate(worldSunVector.y * 40.0);
	return color * exp2Rayleigh;
}

vec3 Atmosphere(vec3 worldViewVector, vec3 worldSunVector, float mieAmount, float depthFactor, const float LdotV, const float LdotV2)
{
	float LdotV_2 = -LdotV * 0.5 + 0.5;
	vec3 color = vec3(0.0);

	float x = depthFactor;
	float s = SmoothMax(0.01, worldSunVector.y, 0.07);
	float v = pow(abs(worldViewVector.y), 1.0 + LdotV_2 * 0.0005 / (s + 0.0005)) * sign(worldViewVector.y);

	float M = AtmosphereMie;
	float rDF = AtmosphereDensityFalloff - LdotV_2 * max(0.0, -worldSunVector.y + 0.01) * 4.0;
	float halfWetness = wetness * 0.5;
	float energyFade = exp(min(0.0, worldSunVector.y) * 100.0);

	M += halfWetness;

	float floorDist = min(x, 0.4 / (-worldViewVector.y + 0.0118));
	if (worldViewVector.y < 0.0)
		x = floorDist;
	M += 0.007 / (max(worldViewVector.y, 0.0) + 0.05);

	float t1 = 1.0 + (-1.0 + exp(-1000.0 * rDF * s)) * v / s;
	vec3 MpR = M + Rayleigh;
	float t3 = rDF * v;
	vec3 t5 = MpR * (AtmosphereDensity / t3);
	x = exp(x * t3);
	vec3 t5x = t5 / x;

	vec3 atmos = (exp(t5 * (t1 - 1.0)) - exp(-t5 + t5x * t1))/ (MpR * t1);

	atmos *= energyFade;
	atmos *= pow(Rayleigh, vec3(0.005 / (max(worldSunVector.y, 0.0) + 0.009))); 	// Blue tint at twilight

	float rainEnergyLoss = 1.0 - 0.75 * wetness * wetness;

	atmos *= rainEnergyLoss;
	vec3 atmos2 = atmos * M * mieAmount;

	color = max(vec3(0.0), atmos * Rayleigh * 0.75 * LdotV2 + atmos2 * (PhaseMie(0.9 - halfWetness, LdotV, LdotV2) + 3.0 * PhaseMie(0.6 - halfWetness, LdotV, LdotV2)));


	{
		vec3 ms = (1.0 - exp(t5x - t5)) * rainEnergyLoss;
		color += max(vec3(0.0), ms) * (exp(SmoothMin(0.0, worldSunVector.y, 0.03) * 200.0) * 0.05);
	}

	color *= 6.6 / SUNLIGHT_BRIGHTNESS;

	color *= 1.0 - wetness * halfWetness;

	if (worldViewVector.y < 0.0 && depthFactor > 5.0) {
		color += vec3(0.1, 0.325, 0.5) * exp(-MpR * (floorDist * 0.1 + 0.2 / (max(worldSunVector.y, 0.0) + 0.001))) * (1.0 - wetness * wetness * 0.85);
	}

	return color;
}


vec3 Atmosphere(vec3 worldViewVector, vec3 worldSunVector, float mieAmount, float LdotV, float LdotV2)
{
	return Atmosphere(worldViewVector, worldSunVector, mieAmount, AtmosphereExtent, LdotV, LdotV2);
}

// Main sky shading function
vec3 SkyShading(vec3 worldViewVector, vec3 worldSunVector)
{
	float LdotV = dot(worldViewVector, worldSunVector);
	float LdotV2 = LdotV * LdotV + 1.0;
	vec3 atmosphere = Atmosphere(worldViewVector, worldSunVector, 0.25, LdotV, LdotV2);
	atmosphere += Atmosphere(worldViewVector, -worldSunVector, 0.25, -LdotV, LdotV2) * nightBrightness;

	return atmosphere;
}

vec3 RenderSunDisc(vec3 worldDir, vec3 sunDir, vec3 colorSunlight)
{
	float d = dot(worldDir, sunDir);

	float hardness = 2000.0;

	float disc = pow(curve(saturate((d - (0.99965)) * hardness)), 2.0);

	float visibility = curve(saturate(worldDir.y * 30.0));

	disc *= visibility;

	vec3 result = vec3(disc);
	result += pow(max(0.0, visibility / (-d * 250 + 250.01) - 0.1), 2.0) * 0.0002 * colorSunlight.r;

	return result;
}

vec3 RenderSunDiscRefelction(vec3 worldDir, vec3 sunDir, vec3 colorSunlight)
{
	float d = dot(worldDir, sunDir);

	float hardness = 2000.0;

	float disc = pow(curve(saturate((d - 0.99960) * hardness)), 2.0);

	float visibility = curve(saturate(worldDir.y * 30.0));

	disc *= visibility;

	vec3 result = vec3(disc);
	result += pow(max(0.0, visibility / (-d * 250 + 250.01) - 0.1), 2.0) * 0.0002 * colorSunlight.r;

	return result;
}

void LandAtmosphericScattering(inout vec3 color, in vec3 viewPos, vec3 worldDir, vec3 worldSunVector)
{
	float dist = length(viewPos);

	dist *= pow(saturate(eyeBrightnessSmooth.y / 240.), 6.0);

	color *= AtmosphereAbsorption(worldDir, dist * 0.005);

	worldDir = normalize(worldDir);
	float LdotV = dot(worldDir, worldSunVector);

	color += Atmosphere(worldDir, worldSunVector, wetness * 0.25, dist * mix(0.005, 0.015, wetness), LdotV, LdotV * LdotV + 1.0) * 0.1
		* pow(1.0 - exp2(-dist * 0.02), 2.0);
}

struct Intersection {
	vec3 pos;
	float dist;
	float angle;
};

float plane = cameraPosition.y - 940.;

Intersection 	RayPlaneIntersectionWorld(in Ray ray)
{
	float rayPlaneAngle = ray.direction.y;

	float planeRayDist = 100000000.0f;
	vec3 intersectionPos = ray.direction * planeRayDist;

	if (abs(rayPlaneAngle) > 0.0001f)
	{
		planeRayDist = plane / rayPlaneAngle;
		intersectionPos = -ray.direction * planeRayDist;

		intersectionPos += cameraPosition.xyz + ray.origin;
	}

	Intersection i;

	i.pos = intersectionPos;
	i.dist = planeRayDist;
	i.angle = rayPlaneAngle;

	return i;
}

float CloudDensity(vec3 pos)
{
	float cloudDist =length(pos.xz - cameraPosition.xz);
	pos /= cloudDist * 0.00015 + 1.0;
	pos *= 0.002;

	float n = 0.0;
	float g = 1.0;
	float speed = frameTimeCounter * 0.03;
	pos.xy += vec2(1.0, 0.1) * speed;
	for (int i = 0; i < 3; i++)
	{
		n += Get2DNoise(pos.xz) * g;

		pos.x += speed;
		pos *= 3.0;
		g *= 0.23;
	}

	n = n * 1.169226 - 0.35;
	n *= 1.0 - wetness * 0.4;
	n += wetness * 0.6;

	#ifndef CLOUDS_BLOCKY
	n = n * 1.5;
	#endif
	n = saturate(n);

	return n;
}

float TraceCloudDensity(vec3 pos, vec3 lightDir, float cloudDist)
{
	float shadowFactor = 0.0;
	for (int i = 1; i <= 2; i++)
	{
		vec3 sp = pos + i * lightDir;
		float d = max(0.0, CloudDensity(sp) - cloudDist);

		shadowFactor += d;
	}
	return shadowFactor;
}

vec3 CirrusSunlightColor(float worldLightVector)
{
	vec3 color = SunAbsorptionAtAltitude(worldLightVector, 1.5);
	color *= saturate(worldLightVector * 40.0);
	return color;
}

vec3 CumulusSunlightColor(float worldLightVector)
{
	vec3 color = SunAbsorptionAtAltitude(worldLightVector, 1.0);
	color *= saturate(worldLightVector * 40.0);
	return color;
}

vec4 CloudColor(vec3 pos, vec3 worldDir, vec3 worldLightVector, vec3 colorSkyUp,
	vec3 atmosphere, const bool detail, const float LdotV, const float LdotV2, float cloudDist)
{
	#ifndef CUMULUS_CLOUDS
	return vec4(0.0);
	#endif



	float perturbNoise = 2.0;
	if (detail) {
		vec3 ppos = worldDir + Get3DNoise(worldDir * 20.0) * 0.02 - vec3(frameTimeCounter * 0.0075, 0, 0);
		perturbNoise =  (1.0 - Get3DNoise(ppos * 50.0)) * 2.0 	/ (1.0 + cloudDist * 0.0002);
		perturbNoise += (1.0 - Get3DNoise(ppos * 100.0)) 		/ (1.0 + cloudDist * 0.00001);
		perturbNoise += (1.0 - Get3DNoise(ppos * 200.0)) * 0.5 	/ (1.0 + cloudDist * 0.00005);
		perturbNoise += (1.0 - Get3DNoise(ppos * 400.0)) * 0.25 / (1.0 + cloudDist * 0.000025);
	}
	perturbNoise *= cloudDist * 0.0018 + 1.2;


	float cloudDensity = CloudDensity(pos);
	cloudDensity = max(0.0, cloudDensity - perturbNoise * 0.005 + 0.01);

	float cloudDensityTrace = saturate(cloudDensity * 0.9 + 0.1) * (200.0 + perturbNoise * 10.0);
	float cloudDistTrace = cloudDist * 0.00002;
	float LdotV01 = pow(-LdotV * 0.5 + 0.5, 0.25) * cloudDensityTrace;

	// For sunlight
	float sunFlux = 0.0;
	float shadowFactor = 0.0;
	{
		vec3 lightDir = normalize(worldLightVector + worldDir);
		lightDir += worldDir * cloudDist * 0.0003;
		lightDir *= LdotV01;

		shadowFactor = TraceCloudDensity(pos + worldDir * cloudDensity * 0.1 * cloudDist, lightDir, cloudDistTrace);
		shadowFactor -= perturbNoise * 0.0021;
		shadowFactor /= abs(worldLightVector.y) * 2.0 + 1.0;
		shadowFactor = max(0.0, shadowFactor);
		shadowFactor *= 1.0 + 3.0 * pow(LdotV * 0.5 + 0.5, 20.0);

		sunFlux = exp2(-shadowFactor * 8.5) * 3.0 + exp2(-shadowFactor * 0.7) * 0.035;
	}


	// For skylight
	float skyFlux = 0.0;
	{
		vec3 lightDir = worldDir * LdotV01;

		float skyFactor = TraceCloudDensity(pos, lightDir, cloudDistTrace);

		skyFlux = exp2(-skyFactor * 2.5) + exp2(-skyFactor * 0.7) * 0.175;
	}


	vec3 color = vec3(0.0);
	vec3 sunColor = CumulusSunlightColor(worldLightVector.y);
	vec3 cirrusLightColor = CirrusSunlightColor(worldLightVector.y);
	if (sunAngle > 0.5) {
		sunColor *= nightBrightness;
		cirrusLightColor *= nightBrightness;
	}

	color += sunFlux * PhaseMie(exp(-cloudDensity * 18.0), LdotV, LdotV2) * 2.16;
	if (detail) {
		color += exp2(-shadowFactor * 15.7) * 0.4926 * LdotV2 / pow(1.64 - 1.6 * LdotV, 1.5); 								// single scattering boost
	}
	color *= sunColor;
	color += mix((cirrusLightColor * 0.24 + colorSkyUp) * skyFlux, cirrusLightColor * 0.84 + atmosphere * 0.5, vec3(exp2(-cloudDensity * 12.0))) * 0.12;
	color += vec3(sunColor * max(0.0, 2.5 - skyFlux) * 0.2) * (1.0 - wetness);


	cloudDensity /= cloudDist * 0.0001 + 0.25;
	cloudDensity = 1.0 - exp(-cloudDensity * cloudDensity * 45.0);
	vec4 result = vec4(color, cloudDensity);


	return result;

}

float CloudDensityCirrus(vec3 pos)
{
	float cloudDist =length(pos.xz - cameraPosition.xz);
	pos /= cloudDist * 0.05 + 1000.0;

	float n = 0.0;
	float g = 0.15;
	vec2 speed = vec2(1.0, 0.1) * (frameTimeCounter * 0.06);
	for (int i = 0; i < 3; i++)
	{
		n += Get2DNoise(pos.xz + speed) * g;

		pos.xz += pos.zx * n;
		pos *= 2.52;
		g *= 0.43;
	}

	n /= 0.16149;

	n += cloudDist * 0.00006;

	n = saturate(n - 0.25);

	return n;
}

vec4 CloudColorCirrus(vec3 pos, vec3 worldDir, vec3 worldLightVector, vec3 colorSkyUp,
	vec3 atmosphere, const bool detail, const float LdotV, const float LdotV2, float cloudDist)
{
	#ifndef CIRRUS_CLOUDS
	return vec4(0.0);
	#endif

	float LdotV01 = step(1.0, LdotV);

	pos.z *= 0.5;
	float cloudDensity = CloudDensityCirrus(pos);

	cloudDensity = saturate(cloudDensity - LdotV01 * 0.35);

	float perturbNoise = 3.5;

	if (detail)
	{
		vec3 ppos = worldDir;
		ppos.y -= Get3DNoise(worldDir * 50.0) * 0.02;
		ppos -= cloudDensity * 0.027;
		ppos *= 0.2 / (sqrt(abs(worldDir.y)) + 0.01);
		ppos.x *= 0.25;
		ppos.z += ppos.x * 0.4;
		ppos.x -= frameTimeCounter * 0.003;

		perturbNoise =  (1.0 - Get3DNoise(ppos * 50.0)) * 2.0;
		ppos += worldDir * perturbNoise * 0.015;
		perturbNoise += (1.0 - Get3DNoise(ppos * 100.0)) * 2.0;
		perturbNoise += (1.0 - Get3DNoise(ppos * 200.0));
		perturbNoise += (1.0 - Get3DNoise(ppos * 400.0)) * 0.5;

		// perturbNoise = map(ppos * 150.0) * 0.3;
	}
	perturbNoise *= sqrt(cloudDist) * 0.08 + 1.0;


	cloudDensity = max(0.0, cloudDensity - perturbNoise * 0.02);


	vec3 color = CirrusSunlightColor(worldLightVector.y) * 6.0 * (PhaseMie(exp(-cloudDensity), LdotV, LdotV2) + 0.5);
	if (sunAngle > 0.5) {
		color *= nightBrightness;
	}
	color += mix(colorSkyUp, atmosphere, vec3(exp2(-cloudDensity * 12.0)));

	vec4 result = vec4(0.0);
	result.rgb = color;

	result.a = 1.0 - exp(-cloudDensity * cloudDensity * 4.0);


	return result;

}

void CloudPlane(inout vec3 color, vec3 positionOffset, vec3 worldVector, vec3 worldLightVector, vec3 worldSunVector, vec3 colorSunlight,
	vec3 colorSkyUp, vec3 atmosphere, float timeMidnight, const bool detail)
{
	vec3 worldVectorNormalized = normalize(worldVector);

	Ray viewRay = MakeRay(positionOffset, worldVectorNormalized);

	Intersection i = RayPlaneIntersectionWorld(viewRay);

	if (i.angle < 0.0f)
	{
		float LdotV = dot(worldVector, -worldLightVector);
		float LdotV2 = LdotV * LdotV + 1.0;
		float dist = length(i.pos.xz - cameraPosition.xz);
		vec4 cirrusCloud = CloudColorCirrus(i.pos.xyz, worldVector, worldLightVector, colorSkyUp, atmosphere, detail, LdotV, LdotV2, dist);

		vec4 cloudSample = CloudColor(i.pos.xyz, worldVector, worldLightVector, colorSkyUp, atmosphere, detail, LdotV, LdotV2, dist);

		float atmosphereDist = i.dist * 0.0015;
		worldVector = -worldVector;
		worldVectorNormalized = -worldVectorNormalized;
		vec3 absorb = AtmosphereAbsorption(worldVector, atmosphereDist);

		cloudSample.rgb *= absorb;
		cirrusCloud.rgb *= absorb;

		vec3 atmos = vec3(0.0);

		if (detail) {
			float atmosphereLdotV = dot(worldVectorNormalized, worldSunVector);
			float atmosphereLdotV2 = atmosphereLdotV * atmosphereLdotV + 1.0;
			atmos = Atmosphere(worldVectorNormalized, worldSunVector, 0.25, atmosphereDist, atmosphereLdotV, atmosphereLdotV2);
			atmos += Atmosphere(worldVectorNormalized, -worldSunVector, 0.25, atmosphereDist, -atmosphereLdotV, atmosphereLdotV2) * nightBrightness; // 2 fps
		} else {
			atmos = atmosphere * (1.0 - pow(saturate(worldVector.y) + 0.001, 0.4)) + Rayleigh * 0.5 * colorSunlight * (1.0 - wetness);
		}

		cirrusCloud.rgb += atmos;
		cloudSample.rgb += atmos;

		cloudSample.rgb = DoNightEyeAtNight(cloudSample.rgb, timeMidnight);
		cirrusCloud.rgb = DoNightEyeAtNight(cirrusCloud.rgb, timeMidnight);

		color.rgb = mix(color.rgb, cirrusCloud.rgb, cirrusCloud.a);
		color.rgb = mix(color.rgb, cloudSample.rgb, cloudSample.a);

		// color = atmos;
	}
}

float CloudShadow(vec3 worldPos, vec3 lightDir)
{
	vec3 pos = -lightDir * (cameraPosition.y - 940.0) / lightDir.y + worldPos + cameraPosition;
	float cloudDist = length(pos.xz - cameraPosition.xz);
	float perturbNoise = cloudDist * 0.000018 + 0.012;
	float cloudDensity = CloudDensity(pos);
	cloudDensity = max(0.0, cloudDensity - perturbNoise * 0.005 + 0.01);
	cloudDensity /= cloudDist * 0.0001 + 0.25;
	cloudDensity = exp(-cloudDensity * cloudDensity * 45.0);
	return cloudDensity;
}

vec3 KelvinToRGB(float k)
{
	const vec3 c = vec3(0.04, 0.4, 0.99);

	float x = k - 6500.0;
	float xc = pow(abs(x), 1.1) * sign(x);

	return exp(xc * (0.00045 * c - 0.00017)) * 0.5;
}







// Lighting colors and data
vec3 GetColorSunlight(vec3 worldSunVector)
{
	vec3 color = SunlightColorFromSunVector(worldSunVector);

	color += SunlightColorFromSunVector(-worldSunVector) * nightBrightness;

	return color;
}


vec3 GetColorTorchlight()
{
	return KelvinToRGB(float(TORCHLIGHT_COLOR_TEMPERATURE));
}

void GetSkylightData(vec3 worldSunVector, vec3 worldLightVector, vec3 colorSunlight, float timeMidnight,
	out vec4 skySHR, out vec4 skySHG, out vec4 skySHB, out vec3 colorSkyUp)
{
	skySHR = vec4(0.0);
	skySHG = vec4(0.0);
	skySHB = vec4(0.0);
	colorSkyUp = SkyShading(vec3(0.0, 1.0, 0.0), worldSunVector);

	for (int i = 0; i < 5; i++)
	{
		float latitude = float(i) * 0.62831853;
		float cosLatitude = cos(latitude), sinLatitude = sin(latitude);
		for (int j = 0; j < 5; j++)
		{
			float longitude = float(j) * 1.25663706;

			vec3 rayDir;
			rayDir.x = cosLatitude * cos(longitude);
			rayDir.z = cosLatitude * sin(longitude);
			rayDir.y = sinLatitude;

			vec3 skyCol = SkyShading(rayDir, worldSunVector);
			#ifdef CLOUDS_IN_AMBIENT
            skyCol = DoNightEyeAtNight(skyCol * 12., timeMidnight) * .083333;
			vec3 skyColTemp = skyCol;
            CloudPlane(skyCol, vec3(0.0), -rayDir, worldLightVector, worldSunVector, colorSunlight, colorSkyUp, skyColTemp, timeMidnight, false);
			#endif

			skySHR += ToSH(skyCol.r, rayDir);
			skySHG += ToSH(skyCol.g, rayDir);
			skySHB += ToSH(skyCol.b, rayDir);
		}
	}

	skySHR /= 25.;
	skySHG /= 25.;
	skySHB /= 25.;
}





// Time data
float GetTimeMidnight(vec3 worldSunVector)
{
	return saturate(-worldSunVector.y * 10.0);
}
