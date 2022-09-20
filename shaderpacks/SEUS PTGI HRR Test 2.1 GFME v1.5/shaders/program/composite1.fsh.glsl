#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/Common.inc"
#include "/lib/GBufferData.inc"


const bool colortex6MipmapEnabled = false;


in vec4 texcoord;


 float e(float v,float y)
 {
   float x=1.;
   #ifdef FULL_RT_REFLECTIONS
   x=clamp(pow(v,.125)+y,0.,1.);
   #else
   x=clamp(v*10.-7.,0.,1.);
   #endif
   return x;
 }
 vec4 G(sampler2D v)
 {
   GBufferData s=GetGBufferData(texcoord.xy);
   GBufferDataTransparent f=GetGBufferDataTransparent(texcoord.xy);
   bool c=f.depth<s.depth;
   if(c)
     s.normal=f.normal,s.smoothness=f.smoothness,s.metalness=0.,s.depth=f.depth;
   vec4 r=GetViewPosition(texcoord.xy,s.depth);
   vec3 h=normalize(r.xyz);
   float p=GetDepthLinear(texcoord.xy),a=dot(-h,s.normal.xyz),l=1.-s.smoothness,w=l*l,b=e(s.smoothness,s.metalness);
   vec4 F=texture2DLod(v,texcoord.xy+HalfScreen,0);
   if(b<.001)
     return F;
   float T=27.;
   T*=min(w*20.,1.1);
   T*=mix(F.w,1.,.2);
   vec4 U=vec4(0.);
   float E=0.;
   float J=F.w*.475+.025;
   const float cos17508=cos(1.5708),sin15708=sin(1.5708);
   vec2 D=normalize(cross(s.normal,h).xy),L=D*mat2(cos17508,-sin15708,sin15708,cos17508);
   float M=saturate(a);
   D*=mix(.1075,.5,M);
   L*=mix(.7,.5,M);
   vec3 A=reflect(-h,s.normal);
   vec2 ScreenTexel4=4.*ScreenTexel;
   vec2 ScreenTexel4Inverse=1.-ScreenTexel4;
   vec2 Temp=T*1.5*ScreenTexel;
   L*=Temp,D*=Temp;
   w=105./w;
   for(int W=-1;W<=1;W++)
     {
       vec2 Temp2=W*D+texcoord.st;
       for(int C=-1;C<=1;C++)
         {
           vec2 X=Temp2+C*L;
           X=clamp(X,ScreenTexel4,ScreenTexel4Inverse);
           vec4 V=texture2DLod(v,X+HalfScreen,0);
           float Z=GetDepthLinear(X),j=pow(saturate(dot(A,reflect(-h,GetNormals(X)))),w),ab=exp(-(abs(Z-p)*1.1)),ac=j*ab;
           U+=vec4(pow(length(V.xyz),J)*normalize(V.xyz+1e-10),V.w)*ac;
           E+=ac;
         }
     }
   if(E<.001)
     return F;
   U/=E+.0001;
   U.xyz=pow(length(U.xyz),1./J)*normalize(U.xyz+1e-06);
   vec4 q=U;
   return q;
 }
 void main()
 {
   vec4 i=G(colortex7);
   i=max(i,vec4(0.));
   gl_FragData[0]=vec4(i);
 };




/* DRAWBUFFERS:7 */
