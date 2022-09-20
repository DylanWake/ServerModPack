#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/Common.inc"
#include "/lib/Bloom.inc"


in vec4 texcoord;


void main()
{
	gl_FragData[0] = vec4(CalculateBloomPass2(texcoord.xy), 1.0);
}

/* DRAWBUFFERS:7 */
