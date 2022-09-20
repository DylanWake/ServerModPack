in vec4 color;
in vec4 preDownscaleProjPos;


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/TAA.inc"


void main()
{
	if (PixelOutOfScreenBounds(preDownscaleProjPos)) {
		discard;
		return;
	}
	vec4 albedo = color;
	albedo.a = 0.5;
	gl_FragData[0] = albedo;
}

/* DRAWBUFFERS:0 */
