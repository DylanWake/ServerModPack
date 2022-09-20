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


const int shadowMapResolution = 4096; // Higher value impacts performance costs, but can get better shadow, and increase path tracing distance. Please increase the shadow distance at the same time. 4096 - 80 blocks path tracing. 8192 - 125 blocks path tracing. 16384 - 200 blocks path tracing, requires at least 6GB VRAM. 34768 - 330 blocks of path tracing, requires at least 20GB VRAM. [4096 8192 16384 32768]
const float RAY_TRACING_RESOLUTION = (shadowMapResolution * MC_SHADOW_QUALITY) / 2.0;
const float RAY_TRACING_DIAMETER_TEMP = floor(pow(RAY_TRACING_RESOLUTION, 2.0 / 3.0));
const float RAY_TRACING_DIAMETER = RAY_TRACING_DIAMETER_TEMP - mod(RAY_TRACING_DIAMETER_TEMP, 2.0) - 1.0;
const float RAY_TRACING_RADIUS = RAY_TRACING_DIAMETER / 2.0;


in vec4 texcoord;
flat in vec3 colorSkyUp;


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/Common.inc"
#include "/lib/Materials.inc"
#include "/lib/GBufferData.inc"


vec2 Texcoord;


 vec2 s(vec3 v)
 {
   ivec2 m=ivec2(viewWidth,viewHeight);
   vec3 i=floor(v.xzy+1e-05);
   i.x+=i.z*altRTDiameter;
   vec2 r;
   r.x=mod(i.x,m.x);
   r.y=i.y+floor(i.x/m.x)*altRTDiameter;
   r+=.5;
   r/=m;
   return r;
 }
 vec2 d(vec3 v)
 {
   v=clamp(v,vec3(0.),vec3(RAY_TRACING_DIAMETER));
   v.x+=v.y*RAY_TRACING_DIAMETER;
   v.y=v.z+floor(v.x/RAY_TRACING_RESOLUTION)*RAY_TRACING_DIAMETER;
   v.x=mod(v.x,RAY_TRACING_RESOLUTION);
   return v.xy;
 }
 struct rXuEJcsNQI{vec3 QbpObHBdUl;vec3 ZRrfSsHfvT;vec3 fgCeZiNBHZ;vec3 ZKdJsVHIyK;vec3 frnQIYJjVJ;};
 rXuEJcsNQI r(Ray v)
 {
   rXuEJcsNQI i;
   i.QbpObHBdUl=floor(v.origin);
   i.ZRrfSsHfvT=abs(vec3(length(v.direction))/(v.direction+1e-07));
   i.fgCeZiNBHZ=sign(v.direction);
   i.ZKdJsVHIyK=(i.fgCeZiNBHZ*(i.QbpObHBdUl-v.origin)+i.fgCeZiNBHZ*.5+.5)*i.ZRrfSsHfvT;
   i.frnQIYJjVJ=vec3(0.);
   return i;
 }
 void i(inout rXuEJcsNQI v)
 {
   v.frnQIYJjVJ=step(v.ZKdJsVHIyK.xyz,vec3(min(min(v.ZKdJsVHIyK.x,v.ZKdJsVHIyK.y),v.ZKdJsVHIyK.z)));
   v.ZKdJsVHIyK+=v.frnQIYJjVJ*v.ZRrfSsHfvT,v.QbpObHBdUl+=v.frnQIYJjVJ*v.fgCeZiNBHZ;
 }
 vec3 p(vec2 v)
 {
   v=(floor(v*ScreenSize)+.5)*ScreenTexel;
   vec4 texLod=texture2DLod(colortex5,v,0);
   vec2 unpackedY=UnpackTwo16BitFrom32Bit(texLod.y);
   vec2 unpackedZ=UnpackTwo16BitFrom32Bit(texLod.z);
   vec2 unpackedW=UnpackTwo16BitFrom32Bit(texLod.w);
   return pow(vec3(unpackedY.x,unpackedZ.x,unpackedW.x),vec3(8.0));
 }
 float e(float v,float y)
 {
   float z=1.;
   #ifdef FULL_RT_REFLECTIONS
   z=clamp(pow(v,.125)+y,0.,1.);
   #else
   z=clamp(v*10.-7.,0.,1.);
   #endif
   return z;
 }


#include "/program/template/BlockShapes.glsl"


 vec3 c(vec2 v)
 {
   vec2 y=vec2(v.xy*ScreenSize)/64.;
   const vec2 m[16]=vec2[16](vec2(-1,-1),vec2(0,-.333333),vec2(-.5,.333333),vec2(.5,-.777778),vec2(-.75,-.111111),vec2(.25,.555556),vec2(-.25,-.555556),vec2(.75,.111111),vec2(-.875,.777778),vec2(.125,-.925926),vec2(-.375,-.259259),vec2(.625,.407407),vec2(-.625,-.703704),vec2(.375,-.037037),vec2(-.125,.62963),vec2(.875,-.481482));
   y+=m[frameCounter%16]*.5;
   y=(floor(y*64.)+.5)/64.;
   vec3 c=texture2D(noisetex,y).xyz;
   return c;
 }
 vec3 H(vec3 v,vec3 y)
 {
   vec2 x=s(clamp(v-vec3(RAY_TRACING_DIAMETER/2.-1)+y+vec3(.5*altRTDiameter),vec3(0.),vec3(altRTDiameter)));
   return p(x);
 }
 vec3 H(float v,float m,float y,vec3 i)
 {
   vec3 x=normalize(vec3(i.y-i.z,-i.x,i.x)),z=cross(x,i);
   return (x*cos(v)+z*sin(v))*y+i*m;
 }
 vec3 c(vec2 v,float y,vec3 x)
 {
   float s=2*3.14159*v.x,z=sqrt((1-v.y)/(1+(y*y-1)*v.y)),i=sqrt(1-z*z);
   return H(s,z,i,x);
 }
 void G(inout vec3 v,in vec3 y,in vec3 i,vec3 z,float x)
 {
   float c=length(y);
   c*=pow(eyeBrightnessSmooth.y/240.,6.f)*rainStrength;
   float f=exp(-c*4e-05);
   f=max(f,.5);
   vec3 s=vec3(dot(colorSkyUp,vec3(1.)))*.05;
   v=mix(s,v,vec3(f));
 }
 vec4 G(float v,vec3 s,vec3 m,vec3 x,vec3 z,vec3 n,float h,float a,float T,bool w)
 {
   float l=1.;
   #ifdef SUNLIGHT_LEAK_FIX
   if(isEyeInWater<1)
     l=saturate(a*100.);
   #endif
   v=max(v-.05,0.);
   float R=v*v;
   vec3 cTexcoord=c(Texcoord.xy).xyz;
   vec3 g=reflect(n,c(cTexcoord.xy*vec2(1.,.8),R,x)),q=normalize((gbufferModelView*vec4(g.xyz,0.)).xyz);
   if(dot(g,x)<0.)
     g=reflect(g,x);
   #ifdef REFLECTION_SCREEN_SPACE_TRACING
   {
     bool b=false;
     vec2 F=Texcoord.xy;
     vec3 D=m.xyz;
     float S=0.;
     vec3 K=m.xyz;
     float P=.1/saturate(dot(-n,x)+.001),J=P*2.,X=1.,Y=0.;
     vec3 temp=q.xyz*P;
     float lengthK=length(K)*.1;
     for(int N=0;N<16;N++)
       {
         vec3 C=temp*(.1+lengthK)*X;
         float j=J*(lengthK);
         K+=C;
         if(K.z>0.)
           break;
         lengthK=length(K)*.1;
         vec2 M=ProjectBack(K).xy;
         TemporalJitterProjPos(M);
         vec3 u=GetViewPositionNoJitter(M.xy,GetDepth(M.xy*.5)).xyz;
         float I=lengthK*10.-length(u)-.02;
         if(abs(2.*I-j)<j&&abs(M.x-.5)<.5&&abs(M.y-.5)<.5)
           {
             K-=C;
             X*=.5;
             Y+=1.;
             if(Y>2.)
               {
                 b=true;
                 F=M.xy;
                 D=u.xyz;
                 S=distance(K,m.xyz)*.4;
                 break;
               }
           }
       }
     vec3 N=(gbufferModelViewInverse*vec4(D,0.)).xyz;
     if(length(N)>far)
       b=false;
     if(b)
       {
         F.xy=floor(F.xy*ScreenSize+.5)*ScreenTexel;
         TemporalJitterProjPos01(F);
         vec2 M=F.xy*.5;
         M=clamp(M,ScreenTexel,HalfScreen)+HalfScreen;
         vec3 E=pow(texture2DLod(colortex1,M,0).xyz,vec3(2.2))*100.;
         LandAtmosphericScattering(E,D-m,g,worldSunVector);
         G(E,D,normalize(m.xyz),normalize(s.xyz),1.);
         if(isEyeInWater==0)
           E*=1.2,TheEndFog(E,length(D),n),E/=1.2;
         if(isEyeInWater==1)
           E*=1.2,UnderwaterFog(E,length(D),n,colorSkyUp,colorSunlight),E/=1.2;
         if(isEyeInWater==2)
           E*=1.2,UnderLavaFog(E,length(D),n),E/=1.2;
         return vec4(E,saturate(S/4.));
       }
   }
   #endif
   vec3 M=s+x*(.004+h*.1);
   if(!w)
     M-=n*(T*.3/(saturate(dot(z,-n))+1e-06)+.01);
   M+=FractedCameraPosition;
   vec3 rayPos=clamp(M+vec3(RAY_TRACING_DIAMETER/2.-1.),vec3(-1.),vec3(RAY_TRACING_DIAMETER-1.));
   Ray F=MakeRay(rayPos,g);
   vec3 k=vec3(1.),N=vec3(0.);
   float S=0.;
   rXuEJcsNQI P=r(F);
   float J=far;
   vec3 u=vec3(1.),fOrigin=.5-F.origin;
   vec3 stainedColor=vec3(1.);
   for(int Q=0;Q<1;Q++)
     {
       vec4 Y=vec4(1.);
       vec4 specularData;
       vec2 shadowCoord=vec2(0.);
       float prevID=0.;
       vec3 rayHitPos=vec3(0.);
       for(int j=0;j<REFLECTION_TRACE_LENGTH;j++)
         {
           shadowCoord=d(P.QbpObHBdUl);
           Y=texelFetch(shadowcolor,ivec2(shadowCoord),0);
           S=Y.w*255.;
           if(S<255.)
             {
               if(S==241.)
                 {
                   vec3 temp=P.QbpObHBdUl+fOrigin;
                   float A=saturate(pow(saturate(dot(F.direction,normalize(temp))),56.*dot(temp,temp))*5.-1.)*50.;
                   N+=Y.xyz*A*stainedColor;
                   i(P);
                   prevID=241.;
                   continue;
                 }
               if((prevID==39.&&S==39.)||(prevID==37.&&S==37.)||!c(P.QbpObHBdUl,S,F,J,u))
                 {
                   i(P);
                   continue;
                 }
               rayHitPos=fract(F.origin+F.direction*J)-.5;
               vec2 O=vec2(0.);
               O+=vec2(rayHitPos.z*-u.x,-rayHitPos.y)*abs(u.x);
               O+=vec2(rayHitPos.x,rayHitPos.z*u.y)*abs(u.y);
               O+=vec2(rayHitPos.x*u.z,-rayHitPos.y)*abs(u.z);
               vec4 A=texelFetch(shadowcolor1,ivec2(shadowCoord),0);
               float textureResolusion=TEXTURE_RESOLUTION;
               #ifdef ADAPTIVE_PATH_TRACING_RESOLUTION
               textureResolusion=exp2(A.w*255.);
               #endif
               vec2 V=textureSize(colortex0,0)/textureResolusion;
               vec2 ab=(floor(A.xy*V)+.5+O.xy)/V;
               vec4 ac=texture2DLod(colortex0,ab,0);
               ac.xyz=pow(ac.xyz,vec3(2.2));
               if(S==37.)
                 {
                   ac.xyz=normalize(ac.xyz+1e-4)*sqrt(length(ac.xyz));
                   ac.xyz=mix(vec3(1.),ac.xyz,vec3(pow(ac.w,.2)));
                   ac.xyz*=ac.xyz;
                   stainedColor*=ac.xyz;
                   prevID=S;
                   J=far;
                   i(P);
                   continue;
                 }
               if(ac.w<0.01&&abs(S-61.5)<31.)
                 {
                   J=far;
                   prevID=S;
                   i(P);
                   continue;
                 }
               ac.xyz*=mix(vec3(1.),Y.xyz,vec3(A.z));
               k=ac.xyz*stainedColor;
               specularData=texture2DLod(depthtex2,ab,0);
               #if SPEC_CHANNEL_EMISSIVE==3
               specularData[SPEC_CHANNEL_EMISSIVE]-=step(1.0,specularData[SPEC_CHANNEL_EMISSIVE]);
               #endif
               break;
             }
           prevID=S;
           i(P);
         }
       #ifdef SPEC_EMISSIVE
       if(specularData[SPEC_CHANNEL_EMISSIVE]>0.)
         {
           N+=.1*k*GI_LIGHT_BLOCK_INTENSITY*specularData[SPEC_CHANNEL_EMISSIVE];
         }
       else
       #endif
         {
           if(S==31.)
             N+=.1*k*GI_LIGHT_BLOCK_INTENSITY;
           if(S==36.)
             {
               float d=saturate(k.x-(k.y+k.z)/2.-.3);
               N+=.1*k*GI_LIGHT_BLOCK_INTENSITY*vec3(2.,.35,.025)*step(1e-5,d);
             }
         }
       vec3 ae=vec3(1.0-abs(u.x),abs(u.x),0.),af=vec3(0.,abs(u.z),1.0-abs(u.z)),offset=rayHitPos*(ae+af);
       vec3 irradiance=vec3(0.);
       float weight=0.;
       for(int j=-1;j<2;j++)
         {
           for(int o=-1;o<2;o++)
             {
               vec3 sampleOffset=j*ae+o*af;
               vec3 sampleIrradiance=H(P.QbpObHBdUl+sampleOffset,u);
               float sampleWeight=max(1.5-length(-offset+sampleOffset),0.0)/1.5*step(1e-7,dot(sampleIrradiance,vec3(1.0)));
               irradiance+=sampleIrradiance*sampleWeight;
               weight+=sampleWeight;
             }
         }
       irradiance/=weight;
       N+=irradiance*2.4*k;
       N+=k*nightVision*0.0047;
     }
   vec3 j=m.xyz+q*J,L=(gbufferModelViewInverse*vec4(j.xyz,0.)).xyz;
   #ifdef SCREEN_SPACE_CONNECTION_REFLECTION
   {
     vec3 Y=ProjectBack(j);
     if(abs(Y.x-.5)<.5-ScreenTexel.x&&abs(Y.y-.5)<.5-ScreenTexel.y&&j.z<0.)
       {
         TemporalJitterProjPos(Y.xy);
         vec2 DTY=Y.xy*.5;
         vec3 Q=GetViewPositionNoJitter(Y.xy,GetDepth(DTY)).xyz;
         vec3 posNormal=DecodeNormal(texture2DLod(colortex2,DTY,0).xy);
         float NdotV=saturate(dot(normalize(-L),posNormal));
         float weight=.002*pow(length(Q)+.5,1.3)/((NdotV+.1)*(length(Q-j)+1e-8));
         if(weight>1.)
           {
             vec2 I=Y.xy*2.-1.;
             float V=smoothstep(.5,1.,max(abs(I.x),abs(I.y)));
             vec3 colorTemp=mix(pow(texture2DLod(colortex1,DTY+HalfScreen.xy,0).xyz,vec3(2.2))*stainedColor*100.,N.xyz,vec3(V));
             N=mix(N.xyz,colorTemp,saturate(weight-1.));
           }
       }
   }
   #endif
   if(J<1000.)
     LandAtmosphericScattering(N,j-m,g,worldSunVector);
   if(isEyeInWater==0)
     N*=1.2,TheEndFog(N,length(L),n),N/=1.2;
   if(isEyeInWater==1)
     N*=1.2,UnderwaterFog(N,length(L),n,colorSkyUp,colorSunlight),N/=1.2;
   if(isEyeInWater==2)
     N*=1.2,UnderLavaFog(N,length(L),n),N/=1.2;
   J*=saturate(dot(-n,x))*2.;
   return vec4(N,saturate(J/4.));
 }
 void main()
 {
   Texcoord=texcoord.xy;
   if(texcoord.x<HalfScreen.x||texcoord.y<HalfScreen.y)
     gl_FragData[0]=texture2DLod(colortex0,Texcoord.xy,0),gl_FragData[1]=texture2DLod(colortex1,Texcoord.xy,0),gl_FragData[2]=texture2DLod(colortex7,Texcoord.xy,0);
   else
     {
       Texcoord=texcoord.xy-HalfScreen;
       GBufferData v=GetGBufferData(Texcoord.xy);
       GBufferDataTransparent y=GetGBufferDataTransparent(Texcoord.xy);
       MaterialMask i=CalculateMasks(v.materialID,Texcoord.xy),s=CalculateMasks(y.materialID,Texcoord.xy);
       bool x=y.depth<v.depth;
       float solidDepth=v.depth;
       if(x)
         v.depth=y.depth,v.normal=y.normal,v.smoothness=y.smoothness,v.metalness=0.,v.mcLightmap=y.mcLightmap,s.sky=0.;
       bool c=abs(111.-y.materialID*255.)<.4&&x;
       vec4 f=GetViewPosition(Texcoord.xy,v.depth),m=gbufferModelViewInverse*vec4(f.xyz,1.),d=gbufferModelViewInverse*vec4(f.xyz,0.);
       vec3 r=normalize(d.xyz),n=normalize((gbufferModelViewInverse*vec4(v.normal,0.)).xyz),h=normalize((gbufferModelViewInverse*vec4(v.geoNormal,0.)).xyz);
       float a=length(f.xyz);
       vec4 T=vec4(0.);
       float t=e(v.smoothness,v.metalness);
       if(t>.0001&&s.sky<.5)
         T=G(1.-v.smoothness,m.xyz,f.xyz,n.xyz,h,r.xyz,i.leaves,v.mcLightmap.y,v.parallaxOffset,x);
       vec3 j=texture2DLod(colortex1,Texcoord.xy+HalfScreen,0).xyz;
       j.xyz=pow(j.xyz,vec3(2.2));
       vec3 Y=GetViewPosition(Texcoord.xy,solidDepth).xyz;
       float p=length(Y.xyz),g=p-a;
       if(c)
         {
           if(isEyeInWater==0)
             TheEndFog(j.xyz,g,r);
           if(isEyeInWater==1)
             UnderwaterFog(j.xyz,g,r,colorSkyUp,colorSunlight);
           if(isEyeInWater==2)
             UnderLavaFog(j.xyz,g,r);
           j.xyz=mix(j.xyz,sqrt(j.xyz*length(y.albedo.xyz+.1))*y.albedo.xyz*.1,y.albedo.w);
         }
       if(x&&!c)
         {
           vec3 u=y.normal-y.geoNormal*1.05;
           float k=saturate(g*.5)*.5;
           vec2 K=Texcoord.xy+u.xy/(a+1.5)*k;
           K=clamp(K,vec2(ScreenTexel),HalfScreen-ScreenTexel*2.);
           float l=ExpToLinearDepth(texture2DLod(depthtex1,K,0).x),I=ExpToLinearDepth(texture2DLod(depthtex0,K,0).x);
           if(I<l)
             {
               vec2 refractionCoord=K.xy;
               #ifndef SKIP_AA
               refractionCoord+=JitterSampleOffset*0.25;
               #endif
               j.xyz=pow(texture2DLod(colortex1,refractionCoord+HalfScreen,0).xyz,vec3(2.2));
               Y=GetViewPosition(K.xy,texture2DLod(depthtex1,K.xy,0).x).xyz;
               f=GetViewPosition(K.xy,texture2DLod(depthtex0,K.xy,0).x);
               p=length(Y.xyz);
               a=length(f.xyz);
               g=p-a;
             }
           if(s.water>.5&&isEyeInWater<1)
             j.xyz*=100.,UnderwaterFog(j.xyz,g,r,colorSkyUp,colorSunlight),j.xyz*=.01;
           if(s.stainedGlass>.5)
             {
               vec3 L=normalize(y.albedo.xyz+.0001)*sqrt(length(y.albedo.xyz));
               vec3 glassColor=mix(vec3(1.),L,vec3(pow(y.albedo.w,.2)));
               if(isEyeInWater==0)
                 TheEndFog(j.xyz,g,r);
               if(isEyeInWater==1)
                 UnderwaterFog(j.xyz,g,r,colorSkyUp,colorSunlight);
               if(isEyeInWater==2)
                 UnderLavaFog(j.xyz,g,r);
               j.xyz*=glassColor*glassColor;
             }
         }
       j.xyz=pow(j.xyz,vec3(1./2.2));
       gl_FragData[0]=texture2DLod(colortex0,Texcoord.xy,0);
       gl_FragData[1]=vec4(j.xyz,v.smoothness);
       gl_FragData[2]=max(vec4(0.),T*vec4(vec3(.1),1.));
     }
 };




/* DRAWBUFFERS:017 */
