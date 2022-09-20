out vec4 color;
out vec4 texcoord;
out vec4 preDownscaleProjPos;


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/TAA.inc"


void main() {

	color = gl_Color;

	texcoord = gl_MultiTexCoord0;

	vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;

	gl_Position = gl_ProjectionMatrix * viewPos;

	preDownscaleProjPos = gl_Position;

	FinalVertexTransformTAA(gl_Position);
}
