in vec4 color;
in vec4 texcoord;
in vec4 preDownscaleProjPos;


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/TAA.inc"


void main() {
	if (PixelOutOfScreenBounds(preDownscaleProjPos)) {
		discard;
		return;
	}
	vec4 tex = texture2D(texture, texcoord.st);

	gl_FragData[0] = tex * color;
	gl_FragData[1] = vec4(0.0f, 0.0f, 0.0f, 1.0f);
}

/* DRAWBUFFERS:01 */
