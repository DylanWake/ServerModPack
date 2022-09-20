
////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////// Bloom Pass 1 /////////////////////////////////////////////////////////////////////////////////////

const float weights[5] = float[5](0.27343750, 0.21875000, 0.10937500, 0.03125000, 0.00390625);
const float offsets[5] = float[5](0.00000000, 1.00000000, 2.00000000, 3.00000000, 4.00000000);


vec3 GrabBlurH(vec2 coord, const float octave, const vec2 offset)
{
	coord += offset;
	coord *= octave;

	vec2 texel = octave * ScreenTexel;

	if (abs(coord.x - 0.5) > 0.5 + 10.0 * texel.x || abs(coord.y - 0.5) > 0.5 + 10.0 * texel.y)
		return vec3(0.0);

	vec3 color = GammaToLinear(texture2D(colortex7, saturate(coord)).rgb) * weights[0];

	for (int i = 1; i < 5; i++)
	{
		vec2 coordOffset = vec2(offsets[i] * texel.x, 0.0);
		color += (GammaToLinear(texture2D(colortex7, saturate(coord + coordOffset)).rgb) + GammaToLinear(texture2D(colortex7, saturate(coord - coordOffset)).rgb)) * weights[i];
	}

	return color;
}

vec2 bloomPadding = ScreenTexel * 30.0;

vec2 GetBloomLevelOffset(float octave)
{
    octave += 0.0001;	// AMD FIX

    vec2 offset = vec2(0.0);
    float floorOctave = min(1.0, floor(octave / 3.0));
    offset.x = -floorOctave * (0.25 + bloomPadding.x);
    offset.y = -1.0 + exp2(-octave) - bloomPadding.y * octave;
	offset.y += floorOctave * 0.35;

 	return offset;
}


vec3 CalculateBloomPass1(vec2 coord)
{
	vec3 bloomColor = vec3(0.0);
	bloomColor += GrabBlurH(coord, 2.0, vec2(0.0, 0.0));
	bloomColor += GrabBlurH(coord, 4.0, GetBloomLevelOffset(1.0));
	bloomColor += GrabBlurH(coord, 8.0, GetBloomLevelOffset(2.0));
	bloomColor += GrabBlurH(coord, 16.0, GetBloomLevelOffset(3.0));
	bloomColor += GrabBlurH(coord, 32.0, GetBloomLevelOffset(4.0));
	bloomColor += GrabBlurH(coord, 64.0, GetBloomLevelOffset(5.0));
	bloomColor += GrabBlurH(coord, 128.0, GetBloomLevelOffset(6.0));
	bloomColor += GrabBlurH(coord, 256.0, GetBloomLevelOffset(7.0));
	bloomColor += GrabBlurH(coord, 512.0, GetBloomLevelOffset(8.0));

	bloomColor = LinearToGamma(bloomColor);

	return bloomColor;
}







////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////// Bloom Pass 2 /////////////////////////////////////////////////////////////////////////////////////
vec3 BlurV(vec2 coord)
{
	vec3 color = vec3(0.0);

	color += GammaToLinear(texture2DLod(colortex7, coord, 0).rgb) * weights[0];

	for (int i = 1; i < 5; i++)
	{
		vec2 coordOffset = vec2(0.0, offsets[i] * ScreenTexel.y);
		color += (GammaToLinear(texture2DLod(colortex7, coord + coordOffset, 0).rgb) + GammaToLinear(texture2DLod(colortex7, coord - coordOffset, 0).rgb)) * weights[i];
	}

	return color;
}

vec3 CalculateBloomPass2(vec2 coord)
{
	return BlurV(coord);
}







////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////// Final retrieval of bloom /////////////////////////////////////////////////////////////////////////
vec3 GetBloomTap(vec2 coord, const float octave, const vec2 offset)
{
	coord /= octave;
	coord -= offset;

	// return GammaToLinear(BicubicTexture(BLOOM_TEX, coord).rgb);
	return texture2DLod(colortex7, coord, 0).rgb;
}

vec3 GetBloom(vec2 coord)
{
	vec3 bloom = vec3(0.0);

	bloom += GetBloomTap(coord, 2.0  , vec2(0.0))				 * 0.76923;
	bloom += GetBloomTap(coord, 4.0  , GetBloomLevelOffset(1.0)) * 0.59171;
	bloom += GetBloomTap(coord, 8.0  , GetBloomLevelOffset(2.0)) * 0.45517;
	bloom += GetBloomTap(coord, 16.0 , GetBloomLevelOffset(3.0)) * 0.35013;
	bloom += GetBloomTap(coord, 32.0 , GetBloomLevelOffset(4.0)) * 0.26933;
	bloom += GetBloomTap(coord, 64.0 , GetBloomLevelOffset(5.0)) * 0.20718;
	bloom += GetBloomTap(coord, 128.0, GetBloomLevelOffset(6.0)) * 0.15936;
	bloom += GetBloomTap(coord, 256.0, GetBloomLevelOffset(7.0)) * 0.12259;
	bloom += GetBloomTap(coord, 512.0, GetBloomLevelOffset(8.0)) * 0.09430;

	bloom /= 2.9247;

	return bloom;
}
