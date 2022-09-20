#include "/lib/Uniforms.inc"


out vec4 texcoord;
flat out mat4 gbufferPreviousModelViewInverse;


void main()
{
	gl_Position = ftransform();

	texcoord = gl_MultiTexCoord0;

	gbufferPreviousModelViewInverse = inverse(gbufferPreviousModelView);
}
