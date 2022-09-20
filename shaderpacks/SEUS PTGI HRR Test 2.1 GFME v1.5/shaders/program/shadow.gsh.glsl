layout(triangles) in;
layout(triangle_strip, max_vertices = 7) out;


const int shadowMapResolution = 4096; // Higher value impacts performance costs, but can get better shadow, and increase path tracing distance. Please increase the shadow distance at the same time. 4096 - 80 blocks path tracing. 8192 - 125 blocks path tracing. 16384 - 200 blocks path tracing, requires at least 6GB VRAM. 34768 - 330 blocks of path tracing, requires at least 20GB VRAM. [4096 8192 16384 32768]


in vec4 vTexcoord[];
in vec4 vColor[];
in vec4 vViewPos[];
in vec4 voxelPos[];
in vec4 shadowPos[];
in vec4 vWorldPos[];
in vec4 vVoxelOrigin[];
in vec3 vVoxelPos[];
in vec2 vMidTexCoord[];
in float vMaterialIDs[];
in float vMCEntity[];
in float ignore[];


out vec4 color;
out vec4 texcoord;
out vec4 viewPos;
out vec3 worldPos;
out vec2 midTexCoord;
out float textureResolution;
out float materialIDs;
out float mcEntity;
out float isVoxelOutput;


#include "/lib/Uniforms.inc"


void main()
{
	int i;


	//Standard shadow pos
	for (i = 0; i < 3; i++)
	{
		gl_Position = shadowPos[i];

		color = vColor[i];
		texcoord = vTexcoord[i];
		viewPos = vViewPos[i];
		worldPos = vVoxelPos[i];
		midTexCoord = vMidTexCoord[i];
		textureResolution = 0.0;
		materialIDs = vMaterialIDs[i];
		mcEntity = vMCEntity[i];
		isVoxelOutput = 0.0;

		EmitVertex();
	}
	EndPrimitive();


	//Voxel pos
	if (ignore[0] + ignore[1] + ignore[2] < 0.5 &&
		distance(voxelPos[0].xy, voxelPos[1].xy) < 4.0 / (shadowMapResolution * MC_SHADOW_QUALITY) &&
		distance(voxelPos[0].xy, voxelPos[2].xy) < 4.0 / (shadowMapResolution * MC_SHADOW_QUALITY) &&
		distance(voxelPos[1].xy, voxelPos[2].xy) < 4.0 / (shadowMapResolution * MC_SHADOW_QUALITY))
	{
		vec3 worldPosDiff = vec3(length(vWorldPos[0].xyz - vWorldPos[1].xyz),
								 length(vWorldPos[1].xyz - vWorldPos[2].xyz),
								 length(vWorldPos[2].xyz - vWorldPos[0].xyz));
		vec2 texCoordUnit[3] = vec2[3](abs(vTexcoord[0].st - vTexcoord[1].st) / worldPosDiff.x,
									abs(vTexcoord[1].st - vTexcoord[2].st) / worldPosDiff.y,
									abs(vTexcoord[2].st - vTexcoord[0].st) / worldPosDiff.z);
		vec2 maxCoordUnit = max(max(texCoordUnit[0], texCoordUnit[1]), texCoordUnit[2]);
		float maxTextureResolution = max(atlasSize.x * maxCoordUnit.x, atlasSize.y * maxCoordUnit.y);
		maxTextureResolution = log2(maxTextureResolution);

        const vec2[4] offset = vec2[4](vec2(-1,1),vec2(1,1),vec2(1,-1),vec2(-1,-1));

		for (i = 0; i < 4; i++)
		{
			// gl_Position = voxelPos[i];
			gl_Position = vVoxelOrigin[0];
			gl_Position.xy += offset[i] / (shadowMapResolution * MC_SHADOW_QUALITY);

			color = vColor[0];
			texcoord = vTexcoord[0];
			viewPos = vViewPos[0];
			worldPos = vVoxelPos[0];
			midTexCoord = vMidTexCoord[0];
			textureResolution = maxTextureResolution;
			materialIDs = vMaterialIDs[0];
			mcEntity = vMCEntity[0];
			isVoxelOutput = 1.0;

			EmitVertex();
		}
		EndPrimitive();
	}
}
