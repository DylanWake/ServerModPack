out vec4 color;
out vec4 texcoord;
out vec4 preDownscaleProjPos;


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/TAA.inc"


void main()
{
	gl_Position = ftransform();

	texcoord = gl_MultiTexCoord0;

	preDownscaleProjPos = gl_Position;

	FinalVertexTransformTAA(gl_Position);

	color = gl_Color;

	gl_FogFragCoord = gl_Position.z;
}
