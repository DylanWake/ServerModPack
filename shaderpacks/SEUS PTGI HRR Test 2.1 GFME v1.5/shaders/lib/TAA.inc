
void TemporalJitterProjPos(inout vec2 pos)
{
	#ifndef SKIP_AA
	pos.xy += JitterSampleOffset;
	#endif
}

void TemporalJitterProjPos01(inout vec2 pos)
{
	#ifndef SKIP_AA
	pos.xy += JitterSampleOffset * 0.5;
	#endif
}

void TemporalJitterProjPosInv01(inout vec2 pos)
{
	#ifndef SKIP_AA
	pos.xy -= JitterSampleOffset * 0.5;
	#endif
}

void CropQuadForDownscale(inout vec4 pos, inout vec4 coord)
{
	pos.xy *= 0.5;
	pos.xy -= 0.5;
	coord.xy *= 0.5;
}

void FinalVertexTransformTAA(inout vec4 pos)
{
	pos.xyz /= pos.w;
	pos.xy = pos.xy * 0.5 - 0.5;
	TemporalJitterProjPos(pos.xy);
	pos.xyz *= pos.w;
}

bool PixelOutOfScreenBounds(vec4 preDownscaleProjPos)
{
	return  (preDownscaleProjPos.x / preDownscaleProjPos.w > (1.0 + ScreenTexel.x) || preDownscaleProjPos.y / preDownscaleProjPos.w > (1.0 + ScreenTexel.y));
}
