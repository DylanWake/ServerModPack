#version 330 compatibility


/*
 _______ _________ _______  _______  _
(  ____ \\__   __/(  ___  )(  ____ )( )
| (    \/   ) (   | (   ) || (    )|| |
| (_____    | |   | |   | || (____)|| |
(_____  )   | |   | |   | ||  _____)| |
      ) |   | |   | |   | || (      (_)
/\____) |   | |   | (___) || )       _
\_______)   )_(   (_______)|/       (_)

Do not modify this code until you have read the LICENSE.txt contained in the root directory of this shaderpack!

*/


in vec4 texcoord;
flat in vec3 colorSkyUp;


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/Common.inc"
#include "/lib/GBufferData.inc"
#include "/lib/Materials.inc"


 float h(float v,float y)
 {
   float x=1.;
   #ifdef FULL_RT_REFLECTIONS
   x=clamp(pow(v,.125)+y,0.,1.);
   #else
   x=clamp(v*10.-7.,0.,1.);
   #endif
   return x;
 }
 void main()
 {
   GBufferData v=GetGBufferData(texcoord.xy);
   GBufferDataTransparent y=GetGBufferDataTransparent(texcoord.xy);
   MaterialMask d=CalculateMasks(y.materialID,texcoord.xy);
   if(y.depth<v.depth)
     v.normal=y.normal,v.smoothness=y.smoothness,v.metalness=0.,v.depth=y.depth,d.sky=0.;
   vec4 i=GetViewPosition(texcoord.xy,v.depth),m=gbufferModelViewInverse*vec4(i.xyz,0.);
   vec3 c=normalize(m.xyz),V=normalize((gbufferModelViewInverse*vec4(v.normal,0.)).xyz);
   float r=ExpToLinearDepth(v.depth);
   float a=1.-v.smoothness,w=a*a;
   vec3 q=-c,Y=normalize(reflect(-q,V)+V*w),b=normalize(q+Y);
   float g=saturate(dot(V,Y)),F=saturate(dot(V,q)),D=saturate(dot(Y,b)),P=v.metalness*.96+.04,L=pow(1.-D,5.),u=P+(1.-P)*L,I=w/2.,invI=1-I,k=1./((g*invI+I)*((F+.8)*invI+I)),T=g*u*k;
   bool eyeInWater=isEyeInWater==1;
   T=mix(T,1.,v.metalness);
   T*=step(v.depth,.999999);
   if(d.water>.5&&eyeInWater)
     {
       vec3 refractDirection=normalize(refract(q,V,1.3333));
       float angle=dot(refractDirection,-V);
       T=1.;
       if(angle<=1.)
         T-=saturate(UNDERWATER_REFLECTION_STRENGTH*pow(angle,2.));
     }
   T*=h(v.smoothness,v.metalness);
   if(d.water>.5&&isEyeInWater==0)
     T=mix(.1,T,.7);
   vec4 e=texture2DLod(colortex7,texcoord.xy+HalfScreen,0);
   e.xyz*=mix(vec3(1.),v.albedo.xyz,vec3(v.metalness))*12.;
   vec3 U=texture2DLod(colortex1,texcoord.xy+HalfScreen,0).xyz;
   U=pow(U,vec3(2.2));
   U*=120.;
   float lengthM=length(m.xyz);
   if(isEyeInWater==0)
     TheEndFog(U,lengthM,c);
   if(eyeInWater)
     UnderwaterFog(U,lengthM,c,colorSkyUp,colorSunlight);
   if(isEyeInWater==2)
     UnderLavaFog(U,lengthM,c);
   vec3 E=U;
   float diff=(length(U)-length(e))/(length(U)+length(e));
   diff=sign(diff)*sqrt(abs(diff));
   T+=.75*diff*(1-T)*T;
   U=mix(U,e.xyz,saturate(T));
   U+=E*v.metalness;
   U/=120.;
   U*=exp(-r*blindness);
   U=pow(U.xyz,vec3(.454545));
   gl_FragData[0]=vec4(U,Luminance(U));
 };





/* DRAWBUFFERS:1 */
