#extension GL_ARB_gpu_shader5 : enable


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/Common.inc"
#include "/lib/Bloom.inc"


in vec4 texcoord;


const float overlap = 0.2;

const float rgOverlap = 0.1 * overlap;
const float rbOverlap = 0.01 * overlap;
const float gbOverlap = 0.04 * overlap;

const mat3 coneOverlap = mat3(1.0, 			rgOverlap, 	rbOverlap,
							  rgOverlap, 	1.0, 		gbOverlap,
							  rbOverlap, 	rgOverlap, 	1.0);

const mat3 coneOverlapInverse = mat3(	1.0 + (rgOverlap + rbOverlap), 			-rgOverlap, 	-rbOverlap,
									  	-rgOverlap, 		1.0 + (rgOverlap + gbOverlap), 		-gbOverlap,
									  	-rbOverlap, 		-rgOverlap, 	1.0 + (rbOverlap + rgOverlap));

// ACES
const mat3 ACESInputMat = mat3(
    0.59719, 0.35458, 0.04823,
    0.07600, 0.90834, 0.01566,
    0.02840, 0.13383, 0.83777
);

const mat3 ACESOutputMat = mat3(
     1.60475, -0.53108, -0.07367,
    -0.10208,  1.10813, -0.00605,
    -0.00327, -0.07276,  1.07602
);

vec3 Uncharted2Tonemap(vec3 x)
{
	x *= 3.0;

	float A = 0.9;
	float B = 0.8;
	float C = 0.1;
	float D = 1.0;
	float E = 0.02;
	float F = 0.30;

	x = x * coneOverlap;

	x = ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;

	x = x * coneOverlapInverse;

    return x;
}

float almostIdentity( float x, float m, float n )
{
    if(x > m) return x;

    float a = 2.0 * n - m;
    float b = 2.0 * m - 3.0 * n;
    float t = x / m;

    return (a * t + b) * t * t + n;
}

vec3 almostIdentity(vec3 x, vec3 m, vec3 n)
{
	return vec3(
		almostIdentity(x.x, m.x, n.x),
		almostIdentity(x.y, m.y, n.y),
		almostIdentity(x.z, m.z, n.z)
		);
}

vec3 BlackDepth(vec3 color, vec3 blackDepth)
{
	vec3 m = blackDepth;
	vec3 n = blackDepth * 0.5;
	return (almostIdentity(color, m, n) - n);
}

vec3 BurgessTonemap(vec3 col)
{
	col *= 0.9;
	col = col * coneOverlap;

	vec3 maxCol = col;

    const float p = 1.0;
    maxCol = pow(maxCol, vec3(p));

    vec3 retCol = (maxCol * (6.2 * maxCol + 0.05)) / (maxCol * (6.2 * maxCol + 2.3) + 0.06);
	retCol = pow(retCol, vec3(1.0 / p));

	retCol = retCol * coneOverlapInverse;

    return retCol;
}

vec3 SEUSTonemap(vec3 color)
{
	const float p = TONEMAP_CURVE;

	color *= coneOverlap;

	color = pow(color, vec3(p));

	color = color / (1.0 + color);

	color = pow(color, vec3((1.0 / GAMMA) / p));

	color = color * coneOverlapInverse;

	color = TransformOutputColor(color);

	return color;
}

vec3 ReinhardJodie(vec3 v)
{
	v = pow(v, vec3(TONEMAP_CURVE));
    float l = Luminance(v);
    vec3 tv = v / (1.0f + v);

    vec3 tonemapped = mix(v / (1.0f + l), tv, tv);
	tonemapped = pow(tonemapped, vec3(1.0 / TONEMAP_CURVE));

	return tonemapped;
}

/////////////////////////////////////////////////////////////////////////////////
//	ACES Fitting by Stephen Hill
vec3 RRTAndODTFit(vec3 v)
{
    vec3 a = v * (v + 0.0245786f) - 0.000090537f;
    vec3 b = v * (1.0f * v + 0.4329510f) + 0.238081f;
    return a / b;
}

vec3 ACESTonemap2(vec3 color)
{
	color *= 1.5;
	color = color * ACESInputMat;

    // Apply RRT and ODT
    color = RRTAndODTFit(color);


    // Clamp to [0, 1]
	color = color * ACESOutputMat;
    color = saturate(color);

    return color;
}
/////////////////////////////////////////////////////////////////////////////////

vec3 ACESTonemap(vec3 color)
{
	color *= 0.7;

	color = color * coneOverlap;

	vec3 crosstalk = vec3(0.05, 0.2, 0.05) * 2.9;

	float avgColor = Luminance(color.rgb);

	const float p = 1.0;

	color = pow(color, vec3(p));

	color = (color * (2.51 * color + 0.03)) / (color * (2.43 * color + 0.59) + 0.14);

	color = pow(color, vec3(1.0 / p));

	color = color * coneOverlapInverse;

	float avgColorTonemapped = Luminance(color.rgb);

	color = saturate(color);

	color = pow(color, vec3(0.9));

	return color;
}



void Vignette(inout vec3 color)
{
	float dist = distance(texcoord.st, vec2(0.5f)) * 2.0f;
		  dist /= 1.5142f;

	color.rgb *= 1.0f - dist * 0.5;

}

void AverageExposure(inout vec3 color)
{
	float avgLum = texture2DLod(colortex6, vec2(0.0, 0.0), 0).a * 0.01;

	color /= avgLum * 23.9 + 0.0008;
}



void main()
{
	vec3 color = 	(texture2D(colortex1, texcoord.st).rgb);

	color = GammaToLinear(color);

	#ifndef SKIP_AA
	#if PIXEL_LOOK == 1
	{
		const float s = 0.33;
		vec3 mb = GammaToLinear(texture2D(colortex1, texcoord.st + ScreenTexel * vec2( s, s)).rgb)
				+ GammaToLinear(texture2D(colortex1, texcoord.st + ScreenTexel * vec2( s,-s)).rgb)
				+ GammaToLinear(texture2D(colortex1, texcoord.st + ScreenTexel * vec2(-s, s)).rgb)
				+ GammaToLinear(texture2D(colortex1, texcoord.st + ScreenTexel * vec2(-s,-s)).rgb);

		color = mix(color, mb * 0.25, vec3(0.999));
	}
	#endif
	#endif

	color = mix(color, GetBloom(texcoord.st), vec3(0.055 * BLOOM_AMOUNT + isEyeInWater * 0.6));

	Vignette(color);

	color = BlackDepth(color, vec3(0.000015 * BLACK_DEPTH * BLACK_DEPTH));

	AverageExposure(color);

	color *= 9.6 * EXPOSURE;

	color = saturate(TONEMAP_OPERATOR(color) * (1.0 + WHITE_CLIP));

	color = pow(color, vec3(1.0 / 2.2 + (1.0 - GAMMA)));

	color = (mix(color, vec3(Luminance(color)), vec3(1.0 - SATURATION)));

	color += rand(texcoord.st) * (1.0 / 255.0);


	gl_FragData[0] = vec4(color.rgb, Luminance(color.rgb));
}


/* DRAWBUFFERS:0 */
