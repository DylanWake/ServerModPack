out vec4 color;
out vec4 texcoord;
out vec4 preDownscaleProjPos;
out vec3 worldNormal;
out vec2 blockLight;
flat out float materialIDs;


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/TAA.inc"


void main()
{
	color = gl_Color;

	texcoord = gl_MultiTexCoord0;

	vec4 lmcoord = gl_TextureMatrix[1]*gl_MultiTexCoord1;

	blockLight = clamp((lmcoord.st * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);

	worldNormal = gl_Normal;

	materialIDs = 1.0f;

	gl_Position = ftransform();

	preDownscaleProjPos = gl_Position;

	FinalVertexTransformTAA(gl_Position);
}
