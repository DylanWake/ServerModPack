#version 330 compatibility


out vec4 texcoord;
flat out vec3 colorSkyUp;

flat out mat4 gbufferPreviousModelViewInverse;
flat out mat4 gbufferPreviousProjectionInverse;


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/Common.inc"


void main()
{
	gl_Position = ftransform();
	texcoord = gl_MultiTexCoord0;

	// Get diffuse light colors and data
	colorSkyUp = SkyShading(vec3(0.0, 1.0, 0.0), worldSunVector);

	// Inverse previous matrices for reprojection
	gbufferPreviousModelViewInverse = inverse(gbufferPreviousModelView);
	gbufferPreviousProjectionInverse = inverse(gbufferPreviousProjection);
}
