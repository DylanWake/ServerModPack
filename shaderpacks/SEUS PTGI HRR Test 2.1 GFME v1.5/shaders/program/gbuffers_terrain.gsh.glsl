layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"

in vec4 Vcolor[];
in vec4 Vtexcoord[];
in vec4 VviewPos[];
in vec4 VpreDownscaleProjPos[];
in vec4 VglPosition[];
in vec3 VworldPosition[];
in vec3 VworldNormal[];
in vec3 Vscreenspace[];
in vec3 Vnormal[];
in vec2 VblockLight[];
flat in float VmaterialIDs[];

out vec4 color;
out vec4 texcoord;
out vec4 viewPos;
out vec4 preDownscaleProjPos;
out vec3 worldPosition;
out vec3 worldNormal;
out vec3 screenspace;
out vec3 normal;
out vec2 blockLight;
flat out float materialIDs;
flat out float textureResolution;

void main()
{
    int i, j;

    vec3 posDiff[3] = vec3[3](VworldPosition[0] - VworldPosition[1],
                              VworldPosition[1] - VworldPosition[2],
                              VworldPosition[2] - VworldPosition[0]);
    vec3 posDiffLength = vec3(length(posDiff[0]),
                              length(posDiff[1]),
                              length(posDiff[2]));
    vec2 texCoordUnit[3] = vec2[3](abs(Vtexcoord[0].st - Vtexcoord[1].st) / posDiffLength.x,
                                   abs(Vtexcoord[1].st - Vtexcoord[2].st) / posDiffLength.y,
                                   abs(Vtexcoord[2].st - Vtexcoord[0].st) / posDiffLength.z);
    vec2 maxCoordUnit = max(max(texCoordUnit[0], texCoordUnit[1]), texCoordUnit[2]);

    float maxTextureResolution = max(atlasSize.x * maxCoordUnit.x, atlasSize.y * maxCoordUnit.y);

    #ifdef SKYLIGHT_FIX
    const float lightUnit = 1.0 / 15.0;

    vec3 lightDiff = vec3(VblockLight[0].y - VblockLight[1].y,
                          VblockLight[1].y - VblockLight[2].y,
                          VblockLight[2].y - VblockLight[0].y);
    vec3 lightDiffUnit[3] = vec3[3](lightDiff.x * posDiff[0] / (posDiffLength.x * posDiffLength.x),
                                    lightDiff.y * posDiff[1] / (posDiffLength.y * posDiffLength.y),
                                    lightDiff.z * posDiff[2] / (posDiffLength.z * posDiffLength.z));
    int lightIndex = 0;
    int asixIndex = 0;
    int maxLightIndex = 0;
    for(i = 0; i < 3; i++)
    {
        maxLightIndex = int(mix(maxLightIndex, i, step(VblockLight[maxLightIndex].y, VblockLight[i].y)));
        for(j = 0; j < 3; j++)
        {
            float isMax = step(abs(lightDiffUnit[lightIndex][asixIndex]), abs(lightDiffUnit[i][j]));
            lightIndex = int(mix(lightIndex, i, isMax));
            asixIndex = int(mix(asixIndex, j, isMax));
        }
    }
    float maxLightUnit = lightDiffUnit[lightIndex][asixIndex];
    float lightFixUnit = abs(maxLightUnit) - lightUnit;
    float direction = sign(maxLightUnit);
    #endif

    for(i = 0; i < 3; i ++)
    {
        gl_Position = VglPosition[i];

        color = Vcolor[i];
        texcoord = Vtexcoord[i];
        viewPos = VviewPos[i];
        preDownscaleProjPos = VpreDownscaleProjPos[i];
        worldPosition = VworldPosition[i];
        worldNormal = VworldNormal[i];
        screenspace = Vscreenspace[i];
        normal = Vnormal[i];
        blockLight = VblockLight[i];
        materialIDs = VmaterialIDs[i];
        textureResolution = maxTextureResolution;

        #ifdef SKYLIGHT_FIX
        float lightDistance = direction * (0.5 - fract(VworldPosition[i][asixIndex] + 1e-5)) + 0.5;
        lightDistance = mix(step(distance(VworldPosition[i], VworldPosition[maxLightIndex]) * lightUnit + 1e-4,
                        VblockLight[maxLightIndex].y - VblockLight[i].y), lightDistance, step(abs(lightDistance - 0.5), 0.499));
        blockLight.y += (lightFixUnit * lightDistance) * step(0.0, lightFixUnit);
        #endif

		EmitVertex();
    }
	EndPrimitive();
}