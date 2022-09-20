#if MC_VERSION >= 11500
layout(location = 11) in vec4 mc_Entity;
#else
layout(location = 10) in vec4 mc_Entity;
#endif


out mat3 tbnMatrix;
out vec4 texcoord;
out vec4 viewPosition;
out vec4 preDownscaleProjPos;
out vec3 worldPosition;
out vec3 viewVector;
out vec3 worldNormal;
out vec3 normal;
out vec2 blockLight;
flat out float isWater;
flat out float isStainedGlass;
flat out float isSlime;


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/TAA.inc"


void main() {

	isWater = 0.0;
	isStainedGlass = 0.0;
	isSlime = 0.0;

	if(mc_Entity.x == 8)
	{
		isWater = 1.0;
	}

	if (mc_Entity.x == 79 || mc_Entity.x == 95 || mc_Entity.x == 160 || mc_Entity.x == 90)
	{
		isStainedGlass = 1.0;
	}

	if (mc_Entity.x == 165)
	{
		isSlime = 1.0;
	}


	viewPosition = gl_ModelViewMatrix * gl_Vertex;

	vec4 position = gbufferModelViewInverse * viewPosition;

	worldPosition.xyz = position.xyz + cameraPosition.xyz;

	gl_Position = gl_ProjectionMatrix * viewPosition;

	preDownscaleProjPos = gl_Position;

	FinalVertexTransformTAA(gl_Position);

	gl_Position.z -= 0.0001;

	texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;

	vec4 lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;

	blockLight = clamp((lmcoord.st * 33.05f / 32.0f) - 1.05f / 32.0f, 0.0f, 1.0f);

	gl_FogFragCoord = gl_Position.z;




	vec3 temp = sign(gl_NormalMatrix * vec3(1.0));
	normal = normalize(gl_NormalMatrix * gl_Normal);
	vec3 tangent = vec3(0.0), binormal = vec3(0.0);

	if (abs(gl_Normal.x) > 0.5) {
		tangent.z  = -sign(gl_Normal.x) * temp.z;
		binormal.y = -temp.y;
	} else if (abs(gl_Normal.y) > 0.5) {
		tangent.x  = temp.x;
		binormal.z = temp.z;
	} else if (abs(gl_Normal.z) > 0.5) {
		tangent.x  = sign(gl_Normal.z) * temp.x;
		binormal.y = -temp.y;
	}

	tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
                     tangent.y, binormal.y, normal.y,
                     tangent.z, binormal.z, normal.z);

	viewVector = normalize(tbnMatrix * viewPosition.xyz);


	worldNormal = gl_Normal.xyz;


}
