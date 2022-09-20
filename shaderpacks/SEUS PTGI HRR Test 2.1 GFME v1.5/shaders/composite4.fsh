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
   if(wetness<.99)
     {
       #ifdef GODRAYS
       if(isEyeInWater<2)
       #else
       if(eyeInWater)
       #endif
         {
           float H=BlueNoiseTemporal(texcoord.xy).x,N=100.;
           vec3 C=vec3(0.),Q=(gbufferModelViewInverse*vec4(0.,0.,0.,1.)).xyz;
           vec3 Temp=c.xyz*N;
           for(int M=0;M<32;M++)
             {
               float A=float(M+H)/32.;
               vec3 W=Temp*A;
               if(lengthM<length(W-Q))
                 break;
               vec3 K=WorldPosToShadowProjPos(W.xyz);
               K.z+=1e-06;
               float shadowStrength=shadow2DLod(shadowtex0,vec3(K.xyz),1).x;
               if(shadowStrength<.1)
                 continue;
               vec3 Z=vec3(shadowStrength);
               #ifdef GODRAYS_STAINED_GLASS_TINT
               float X=shadow2DLod(shadowtex0,vec3(K.xy-vec2(.5,0.),K.z),1).x;
               if(X<.9)
                 {
                   vec3 ad=texture2DLod(shadowcolor,vec2(K.xy-vec2(.5,0.)),2).xyz;
                   ad*=ad;
                   Z=mix(Z*ad,Z,vec3(X));
                   Z*=Z;
                 }
               #endif
               #ifdef CLOUD_SHADOW
               Z*=CloudShadow(W.xyz, worldLightVector);
               #endif
               if(eyeInWater)
                 {
                   float ag=shadow2DLod(shadowtex0,vec3(K.xy-vec2(0.,.5),K.z),1).x,ae=texture2DLod(shadowcolor1,K.xy-vec2(0.,.5),1).x*256.-(W.y+cameraPosition.y),af=GetCausticsComposite(W,worldLightVector,ae);
                   Z=mix(Z*af,Z,vec3(ag));
                   if(ae<0.)
                     continue;
                   C+=Z*exp(-vec3(0.25, 0.04, 0.01)*(N*A))*(400.0/(pow(ae,2.)+200.)/(1.0+length(W)*0.2));
                 }
               else
                 C+=sqrt(Z*colorSunlight)*.1;
             }
           float vlStrength=0.0;
           float Z=dot(worldLightVector,c.xyz),K=1.;
           if(isEyeInWater==0)
             {
               if(worldTime<=12500)
                 vlStrength=pow(abs(worldTime-6000)/6500.,2.0);
               else if(worldTime<=23500)
                 vlStrength=pow(abs(worldTime-18000)/5500.,2.0);
               else
                 vlStrength=pow(abs(worldTime-30000)/6500.,2.0);
               vlStrength=vlStrength*0.4+0.5;
               vlStrength*=Z*0.25+0.75;
               K=.5/(max(0.,pow(worldLightVector.y,2.)*2.)+.4);
             }
           else
             {
               vlStrength=dot(refract(worldLightVector,vec3(0.,-1.,0.),.750019),c.xyz);
               vlStrength=vlStrength*.5+.4;
             }
           float j=PhaseMie(.8,vlStrength,vlStrength*vlStrength+1.);
           vec3 vl=TintUnderwaterDepth(C*colorSunlight*vec3(0.046, 0.05175, 0.0575)*j*K*(1.-wetness));
           U+=vl*VOLUMETRIC_LIGHT_STRENGTH;
         }
     }
   if(d.sky<.5&&isEyeInWater<1)
     LandAtmosphericScattering(U,i.xyz,c.xyz,worldSunVector.xyz);
   U/=120.;
   U*=exp(-r*blindness);
   U=pow(U.xyz,vec3(.454545));
   gl_FragData[0]=vec4(U,Luminance(U));
 };





/* DRAWBUFFERS:1 */
