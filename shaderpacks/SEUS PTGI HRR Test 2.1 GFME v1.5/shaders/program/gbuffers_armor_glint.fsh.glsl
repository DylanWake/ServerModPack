in vec4 color;
in vec4 texcoord;
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
	albedo.a = 1.0;

	albedo *= texture2D(colortex0, texcoord.xy + frameTimeCounter * 0.05);

	albedo.rgb = pow(albedo.rgb, vec3(2.2));

	gl_FragData[0] = albedo;
}

/* DRAWBUFFERS:0 */
