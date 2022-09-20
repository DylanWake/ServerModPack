#if MC_VERSION >= 11500
layout(location = 11) in vec4 mc_Entity;
layout(location = 12) in vec4 mc_midTexCoord;
layout(location = 13) in vec4 at_tangent;
#else
layout(location = 10) in vec4 mc_Entity;
layout(location = 11) in vec4 mc_midTexCoord;
layout(location = 12) in vec4 at_tangent;
#endif


out vec4 vTexcoord;
out vec4 vColor;
out vec4 vViewPos;
out vec4 voxelPos;
out vec4 shadowPos;
out vec4 vWorldPos;
out vec4 vVoxelOrigin;
out vec3 vVoxelPos;
out vec2 vMidTexCoord;
out float vMaterialIDs;
out float vMCEntity;
out float ignore;


const int shadowMapResolution = 4096; // Higher value impacts performance costs, but can get better shadow, and increase path tracing distance. Please increase the shadow distance at the same time. 4096 - 80 blocks path tracing. 8192 - 125 blocks path tracing. 16384 - 200 blocks path tracing, requires at least 6GB VRAM. 34768 - 330 blocks of path tracing, requires at least 20GB VRAM. [4096 8192 16384 32768]
const float RAY_TRACING_RESOLUTION = (shadowMapResolution * MC_SHADOW_QUALITY) / 2.0;
const float RAY_TRACING_DIAMETER_TEMP = floor(pow(RAY_TRACING_RESOLUTION, 2.0 / 3.0));
const float RAY_TRACING_DIAMETER = RAY_TRACING_DIAMETER_TEMP - mod(RAY_TRACING_DIAMETER_TEMP, 2.0) - 1.0;


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"


 vec2 d(vec3 v)
 {
   v=clamp(v,vec3(0.),vec3(RAY_TRACING_DIAMETER));
   vec3 i=floor(v.xzy+1e-05);
   i.x+=RAY_TRACING_DIAMETER*i.z;
   vec2 f;
   f.x=mod(i.x,RAY_TRACING_RESOLUTION);
   f.y=i.y+floor(i.x/RAY_TRACING_RESOLUTION)*RAY_TRACING_DIAMETER;
   f+=.5;
   f/=(shadowMapResolution * MC_SHADOW_QUALITY);
   return f;
 }
 vec3 d(vec3 v,vec3 m,vec2 x,vec2 y,vec4 n,vec4 f,inout float i,out vec2 s)
 {
   bool r=abs(fract(v.x*2.)-0.5)<.49||abs(fract(v.y*2.)-0.5)<.49||abs(fract(v.z*2.)-0.5)<.49;
   if(abs(f.x-8.5)<1.||f.x<1.||r||min(abs(m.x),abs(m.z))>.2)
     i=1.;
   if(abs(f.x-188.5)<4.)
     i=0.;
   if(f.x==50.||f.x==52.||f.x==76.)
     i=step(m.y,.5);
   if(f.x==51||f.x==53||f.x==198.||f.x>255.)
     i=float(f.x==320.);
   float G=.025,e=.025;
   if(f.x==18.||f.x==138.)
     G=.5,e=0.0001;
   if(f.x==80.||abs(f.x-424.5)<1.)
     e=0.0001;
   if(f.x==10.||f.x==11.)
     {
       e=0.,i=0.;
       if(abs(m.x)<.5&&abs(m.z)<.5)
         {
           e=.025;
           if(m.x<0.&&m.z<0.)
             G=-.025,e=.025;
           if(m.x<0.&&m.z>0.)
             e=.05;
         }
     }
   if(f.x==51.||f.x==53.)
     G=.5,e=0.;
   vec3 z=normalize(n.xyz);
   vec3 a=normalize(cross(z,m.xyz)*sign(n.w));
   s=step(y.xy,x.xy-1e-7);
   vec3 l=v.xyz+((1.-s.x*2.)*z+(1.-s.y*2.)*a)*G-m.xyz*e;
   return l;
 }
 vec4 G(vec3 x,vec2 v,inout float z,out vec4 voxelOrigin)
 {
   vec3 y=x;
   x=clamp(x,vec3(1.),vec3(RAY_TRACING_DIAMETER-1.));
   z=max(z,step(.005,distance(x,y)));
   float s=dot(abs(x-y),vec3(1.))/RAY_TRACING_DIAMETER;
   vec2 m=d(x);
   m=m*2.-1.;
   voxelOrigin=vec4(m,s,1.);
   m+=v.xy*vec2(2./shadowMapResolution);
   return vec4(m,s,1.);
 }
 void main()
 {
   gl_Position=ftransform();
   vTexcoord=gl_MultiTexCoord0;
   vMCEntity=mc_Entity.x;
   vViewPos=gl_ModelViewMatrix*gl_Vertex;
   vWorldPos=shadowModelViewInverse*vViewPos;
   vWorldPos.xyz+=cameraPosition.xyz;
   vMaterialIDs=30.;
   float z=0.,i=0.;
   z=step(1.,abs(mc_Entity.x-8.5));
   if(mc_Entity.x==74)
     vMaterialIDs=36.;
   if(mc_Entity.x==79||mc_Entity.x==90||mc_Entity.x==95||mc_Entity.x==160||mc_Entity.x==165)
     i=1.f,vMaterialIDs=37.;
   if(mc_Entity.x==18||mc_Entity.x==161)
     vMaterialIDs=38.;
   if(mc_Entity.x==20)
     vMaterialIDs=39.;
   if(abs(mc_Entity.x-51.5)<2||mc_Entity.x==76||mc_Entity.x==117||mc_Entity.x==138||abs(mc_Entity.x-188.5)<4||mc_Entity.x==198)
     vMaterialIDs=241.;
   if(abs(mc_Entity.x-10.5)<1||mc_Entity.x==89||abs(mc_Entity.x-91.5)<1||mc_Entity.x==124||mc_Entity.x==169||abs(mc_Entity.x-182.5)<2||mc_Entity.x==213)
     vMaterialIDs=31.;
   #ifdef GLOWING_LAPIS_LAZULI_BLOCK
   if(mc_Entity.x==22)
     vMaterialIDs=31.;
   #endif
   #ifdef GLOWING_REDSTONE_BLOCK
   if(mc_Entity.x==152)
     vMaterialIDs=31.;
   #endif
   #ifdef GLOWING_EMERALD_BLOCK
   if(mc_Entity.x==133)
     vMaterialIDs=31.;
   #endif
   if(abs(mc_Entity.x-194.5)<2)
     vMaterialIDs=mc_Entity.x-161.;
   if(mc_Entity.x>255)
     vMaterialIDs=mc_Entity.x-216.;
   vMidTexCoord=mc_midTexCoord.xy;
   vColor=gl_Color;
   ignore=0.;
   {
     vec2 r;
     vec3 m=d(vWorldPos.xyz,gl_Normal.xyz,vTexcoord.xy,mc_midTexCoord.xy,at_tangent,mc_Entity,ignore,r);
     m=floor(m);
     vVoxelPos=m;
     m-=cameraPosition.xyz;
     m+=vec3(RAY_TRACING_DIAMETER/2.);
     voxelPos=G(m,r,ignore,vVoxelOrigin);
   }
   {
     float r=length(gl_Position.xy),a=1.f-SHADOW_MAP_BIAS+r*SHADOW_MAP_BIAS;
     gl_Position.xy*=.95f/a;
     gl_Position.xy*=.5;
     gl_Position.xy+=.5;
     gl_Position.y-=step(z,.5);
     gl_Position.x-=step(.5,i);
     gl_Position.z=mix(gl_Position.z,.5,.8);
     shadowPos=gl_Position;
   }
 };
