in vec4 texcoord;
flat in vec3 colorTorchlight;


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/Common.inc"
#include "/lib/Materials.inc"
#include "/lib/GBufferData.inc"


const int shadowMapResolution = 4096; // Higher value impacts performance costs, but can get better shadow, and increase path tracing distance. Please increase the shadow distance at the same time. 4096 - 80 blocks path tracing. 8192 - 125 blocks path tracing. 16384 - 200 blocks path tracing, requires at least 6GB VRAM. 34768 - 330 blocks of path tracing, requires at least 20GB VRAM. [4096 8192 16384 32768]
const float shadowDistance 			= 120.0; // Shadow distance. Set lower if you prefer nicer close shadows. Set higher if you prefer nicer distant shadows. [80.0 120.0 160.0 200.0 240.0 280.0 320.0 360.0]
const float shadowIntervalSize 		= 1.0f;
const bool 	shadowHardwareFiltering0 = true;

const bool 	shadowtexMipmap = true;
const bool 	shadowtex1Mipmap = false;
const bool 	shadowtex1Nearest = false;
const bool 	shadowcolor0Mipmap = false;
const bool 	shadowcolor0Nearest = false;
const bool 	shadowcolor1Mipmap = false;
const bool 	shadowcolor1Nearest = false;

const float shadowDistanceRenderMul = 1.0f;

const int RGBA8 		= 0;
const int RGBA16 		= 0;
const int RGBA16F 		= 0;
const int RGBA32F 		= 0;
const int colortex0Format = RGBA8;
const int colortex1Format = RGBA16;
const int colortex2Format = RGBA16;
const int colortex3Format = RGBA16;
const int colortex4Format = RGBA32F;
const int colortex5Format = RGBA32F;
const int colortex6Format = RGBA32F;
const int colortex7Format = RGBA16F;

const bool colortex3Clear = false;
const bool colortex4Clear = false;
const bool colortex5Clear = false;
const bool colortex6Clear = false;

const int 	superSamplingLevel 		= 0;

const float	sunPathRotation 		= -40.0f; // No sun in nether or end.

const int 	noiseTextureResolution  = 64;

const float ambientOcclusionLevel 	= 0.06f;

const float wetnessHalflife = 100.0;
const float drynessHalflife = 100.0;
const float eyeBrightnessHalflife = 5.0;

const float RAY_TRACING_RESOLUTION = (shadowMapResolution * MC_SHADOW_QUALITY) / 2.0;
const float RAY_TRACING_DIAMETER_TEMP = floor(pow(RAY_TRACING_RESOLUTION, 2.0 / 3.0));
const float RAY_TRACING_DIAMETER = RAY_TRACING_DIAMETER_TEMP - mod(RAY_TRACING_DIAMETER_TEMP, 2.0) - 1.0;


vec2 Texcoord;


float OrenNayar(vec3 normal, vec3 eyeDir, vec3 lightDir)
{
	// calculate intermediary values
	float NdotL = dot(normal, lightDir);
	float NdotV = dot(normal, eyeDir);

	float angleVN = acos(NdotV);
	float angleLN = acos(NdotL);

	float alpha = max(angleVN, angleLN);
	float beta = min(angleVN, angleLN);

	float gamma = dot(eyeDir - normal * NdotV, lightDir - normal * NdotL);

	float C = sin(alpha) * tan(beta);

	// put it all together
	float L1 = max(0.0, NdotL) * (0.82665 + 0.34681 * max(0.0, gamma) * C);

	//return max(0.0f, surface.NdotL * 0.99f + 0.01f);
	return clamp(L1, 0.0f, 1.0f);
}

 float e(float v,float z)
 {
   float x=1.;
   #ifdef FULL_RT_REFLECTIONS
   x=clamp(pow(v,.125)+z,0.,1.);
   #else
   x=clamp(v*10.-7.,0.,1.);
   #endif
   return x;
 }
 void main()
 {
   Texcoord=texcoord.xy;
   GBufferData v=GetGBufferData(Texcoord);
   MaterialMask x=CalculateMasks(v.materialID,Texcoord);
   vec4 s=GetViewPosition(Texcoord.xy,v.depth),a=gbufferModelViewInverse*vec4(s.xyz,1.),i=gbufferModelViewInverse*vec4(s.xyz,0.);
   vec3 f=normalize(s.xyz),m=normalize(i.xyz),y=normalize((gbufferModelViewInverse*vec4(v.normal,0.)).xyz),c=normalize((gbufferModelViewInverse*vec4(v.geoNormal,0.)).xyz);
   float r=length(s.xyz);
   vec3 n=vec3(0.),t=y;
   if(x.grass>.5)
     y=vec3(0.,1.,0.);
   vec3 w=texture2DLod(colortex7,Texcoord.xy+vec2(0.,HalfScreen.y),0).xyz*10.,T=w*v.albedo.xyz;
   const float h=RAY_TRACING_DIAMETER/2.-5.;
   if(r>h)
     {
       vec3 R=v.mcLightmap.x*colorTorchlight*.0925;
       R*=v.albedo.xyz;
       T=mix(T,R,vec3(saturate((r-h)*.2)));
     }
   n.xyz=T+v.albedo.xyz*1e-05;
   #ifdef HELD_LIGHT
   {
     float G=heldBlockLightValue/16.,Y=OrenNayar(t,-m,-m),o=1./(dot(i.xyz,i.xyz)+.3);
     n+=v.albedo.xyz*G*o*Y*colorTorchlight*.3;
   }
   #endif
   #ifdef VISUALIZE_DANGEROUS_LIGHT_LEVEL
   {
     float G=BlockLightTorchLinear(v.mcLightmap.x)*16.;
     n.x+=step(G,7.);
   }
   #endif
   v.metalness*=1.0-x.grass;
   vec3 randomness=rand(Texcoord.xy+sin(frameTimeCounter));
	 n*=1.-e(v.smoothness,v.metalness)*v.metalness;
   vec3 colorTemp=vec3(0.0);
   if(v.emissive>0.)
     {
       colorTemp+=v.emissive*GI_LIGHT_BLOCK_INTENSITY;
     }
   else
     {
   	   if(x.glowstone>.5)
         colorTemp+=GI_LIGHT_BLOCK_INTENSITY;
       if(x.torch>.5)
         colorTemp+=pow(length(v.albedo.xyz),2.)*1.5*GI_LIGHT_TORCH_INTENSITY;
       if(x.lava>.5)
         colorTemp+=.75*GI_LIGHT_BLOCK_INTENSITY;
       if(x.fire>.5)
         colorTemp+=3.*GI_LIGHT_TORCH_INTENSITY;
       if(x.litFurnace>.5)
         {
           float d=saturate(v.albedo.x-(v.albedo.y+v.albedo.z)/2.-.2);
           if(d>0.||v.albedo.xyz==vec3(1.))
               colorTemp+=GI_LIGHT_BLOCK_INTENSITY*vec3(2.,.35,.025);
         }
       if(x.beacon>.5)
         {
           float d=v.albedo.y/v.albedo.z;
           if(d>1.01||(d<1.009&&d>=1.))
               colorTemp+=GI_LIGHT_BLOCK_INTENSITY;
         }
       if(texture2D(depthtex1,Texcoord).x<texture2D(depthtex2,Texcoord).x)
         {
           if(Texcoord.x<.25)
             colorTemp+=heldBlockLightValue2*GI_LIGHT_BLOCK_INTENSITY/16.;	// Left hand
           else if(Texcoord.x<.5&&heldBlockLightValue2!=heldBlockLightValue)
             colorTemp+=heldBlockLightValue*GI_LIGHT_BLOCK_INTENSITY/16.;	// Right hand
         }
     }
   colorTemp+=nightVision*0.05+0.002;
   n+=colorTemp*v.albedo.rgb;
   n*=.001;
   n=LinearToGamma(n);
   n+=randomness*(1./65535.);
   gl_FragData[0]=vec4(n.xyz,1.);
 };




/* DRAWBUFFERS:1 */
