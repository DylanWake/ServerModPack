in vec4 texcoord;


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/Common.inc"


 float i(vec2 v)
 {
   v=(floor(v*ScreenSize)+.5)*ScreenTexel;
   float texLod=texture2DLod(colortex5,v,0).z;
   return UnpackTwo16BitFrom32Bit(texLod).y;
 }
 void G(inout float v,inout float x,float i,float y,float z)
 {
   v*=mix(3.,4.25,y);
   if(z<.12)
     x=0.;
   else
     {
       x*=1.-pow(y,.4);
       x/=i*.4+8e-06;
     }
 }
 float G(vec3 v,vec3 y,float m)
 {
   float x=dot(abs(v-y),vec3(.3333));
   x*=m;
   return x;
 }
 vec4 G(sampler2D v,vec2 f,bool x,float y,float m,vec2 s)
 {
   float r=i(f.xy);
   vec2 c=vec2(0.,HalfScreen.y);
   vec4 e=texture2DLod(v,f.xy+c,0);
   vec3 h=e.xyz;
   vec3 a,t;
   GetBothNormals(f.xy,a,t);
   float R=GetDepth(f.xy),o=ExpToLinearDepth(R);
   vec3 d=GetViewPosition(f.xy,R).xyz,H=normalize(d);
   vec2 j=BlueNoiseTemporal(f.xy).xy-.5;
   float p=y,Y=m;
   G(p,Y,e.w,r,o);
   float S=3./o;
   vec4 X=vec4(0.);
   float F=0.;
   vec2 P=normalize(cross(t,vec3(0.,0.,1.)).xy),l=P.yx*vec2(1.,-1.);
   l*=saturate(dot(t,-H))*.8+.2;
   vec2 coordTemp=(s.x*P+s.y*l)*p*ScreenTexel;
   float luminaceH=Luminance(h.xyz);
   for(int C=-1;C<=1;C++)
     {
       vec2 B=f.xy+vec2(C+j.x)*coordTemp;
       B=clamp(B,ScreenTexel*2.,HalfScreen-ScreenTexel*2.);
       vec4 T=texture2DLod(v,B+c,0);
       vec3 A,L;
       GetBothNormals(B,A,L);
       vec3 E=GetViewPosition(B,GetDepth(B)).xyz,g=E.xyz-d.xyz;
       float D=length(g);
       float M=dot(g,t);
       bool k=M>.05&&Luminance(T.xyz)<luminaceH;
       float I=0.,q=exp(-(abs(g.z)*S));
       if(k&&D<1.&&dot(-g,L)>0.)
         I=8./y;
       else
         I=saturate(exp(-abs(M)*100.))*pow(saturate(dot(a,A)),24.);
       float K=exp(-G(T.xyz,h,Y)),W=I*K*q;
       X+=T*W;
       F+=W;
     }
   if(F<.0001)
     return e;
   X/=F+.0001;
   return X;
 }
