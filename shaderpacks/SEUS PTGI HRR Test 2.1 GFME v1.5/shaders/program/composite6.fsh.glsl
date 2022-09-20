#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/Common.inc"
#include "/lib/Materials.inc"


const bool colortex2MipmapEnabled = true;
const bool colortex4MipmapEnabled = true;


in vec4 texcoord;
flat in mat4 gbufferPreviousModelViewInverse;


 vec4 c(vec2 v)
 {
   v=(floor(v*ScreenSize)+.5)*ScreenTexel;
   return texture2DLod(colortex5,v,0);
 }
 vec2 c(vec2 v,float m,out float y)
 {
   vec2 s=v;
   y=m;
   for(int i=-1;i<=1;i+=2)
     {
       for(int z=-1;z<=1;z+=2)
         {
           vec2 f=v+vec2(i,z)*ScreenTexel;
           float c=texture2DLod(depthtex0,f,0).x;
           if(c<y)
             y=c,s=f;
         }
     }
   return s;
 }
 vec3 D(vec3 y)
 {
   mat3 v=mat3(.2126,.7152,.0722,-.09991,-.33609,.436,.615,-.55861,-.05639);
   return y*v;
 }
 vec3 g(vec3 y)
 {
   mat3 v=mat3(1.,0.,1.28033,1.,-.21482,-.38059,1.,2.12798,0.);
   return y*v;
 }
 vec3 D(vec3 v,vec3 y,vec3 x,vec3 m)
 {
   vec3 c=m-v,i=c/y,f=abs(i);
   float r=max(f.x,max(f.y,f.z));
   if(r>1.)
     return v+c/r;
   else
     return m;
 }
 vec4 a(vec2 v)
 {
   return pow(texture2DLod(colortex3,v,0),vec4(vec3(1./2.2),1.));
 }
 vec4 G(vec2 v)
 {
   vec2 f=v*ScreenSize,x=floor(f-.5)+.5,s=f-x,z=s*s,i=s*z;
   vec2 c=.25*(-i+2.*z-s),
        n=1.75*i-2.75*z+1.,
        h=-1.75*i+2.5*z+.25*s,
        D=.25*(i-z),
        t=n+h,
        d=ScreenTexel*(x+h/t);
   vec4 e=a(d);
   vec2 o=ScreenTexel*(x-1.),H=ScreenTexel*(x+2.);
   vec4 G=(vec4(a(vec2(d.x,o.y)).xyz,1.)*c.y+
           vec4(a(vec2(d.x,H.y)).xyz,1.)*D.y)*t.x+
          (vec4(a(vec2(o.x,d.y)).xyz,1.)*c.x+
           vec4(e.xyz,1.)*t.x+
           vec4(a(vec2(H.x,d.y)).xyz,1.)*D.x)*t.y;
   return pow(vec4(max(vec3(0.),G.xyz/G.w),e.w),vec4(vec3(2.2),1.));
 }
 void D(vec2 v,float x,out vec3 y,out vec3 i,out vec4 m)
 {
   vec4 f=vec4(v.xy*2.-1.,x*2.-1.,1.),c=gbufferProjectionInverse*f;
   c.xyz/=c.w;
   m=gbufferModelViewInverse*vec4(c.xyz,1.);
   vec4 r=m;
   r.xyz+=cameraPositionDiff;
   vec4 s=gbufferPreviousModelView*vec4(r.xyz,1.),z=gbufferPreviousProjection*vec4(s.xyz,1.);
   z.xyz/=z.w;
   y=f.xyz-z.xyz;
   vec4 n=gbufferModelView*vec4(r.xyz,1.),e=gbufferProjection*vec4(n.xyz,1.);
   e.xyz/=e.w;
   i=f.xyz-e.xyz;
 }
 float F(vec3 v,vec3 y)
 {
   return max(max(abs(v.x-y.x),abs(v.y-y.y)),abs(v.z-y.z));
 }
 void main()
 {
   vec2 v=texcoord.xy*.5,x=JitterSampleOffset;
   #ifdef SKIP_AA
   x=vec2(0.);
   #endif
   ivec2 m=ivec2(floor(texcoord.xy*ScreenSize+floor(x*ScreenSize)));
   float f=m%2==ivec2(0)?1.:0.;
   vec4 n=texture2DLod(colortex1,LockRenderPixelCoord(v)+HalfScreen,0);
   vec3 z=n.xyz;
   int t=int(floor(n.w*255.+.1));
   float a,e=texture2DLod(depthtex0,v,0).x,o=texture2DLod(depthtex1,v,0).x;
   vec2 d=c(v,e,a);
   vec3 H,l;
   vec4 w;
   D(d*2.,a,H,l,w);
   float p=length(H.xy);
   H*=step(.7,e);
   vec2 R=texcoord.xy-H.xy*.5;
   vec4 S=G(R.xy);
   float J=texture2D(colortex3,R.xy).w;
   vec3 b=vec3(0.),Y=vec3(0.);
   vec2 coordOffset=.7*ScreenTexel;
   vec2 coordTemp=v.xy+HalfScreen;
   for(int P=-1;P<=1;P+=2)
     {
       for(int B=-1;B<=1;B+=2)
         {
           vec3 L=texture2DLod(colortex1,coordTemp+vec2(P,B)*coordOffset,0).xyz;
           L=D(L);
           b+=L;
           Y+=L*L;
         }
     }
   b*=.25;
   Y*=.25;
   vec4 L=c(texcoord.xy);
   vec2 Lw=UnpackTwo16BitFrom32Bit(L.w);
   Lw.y=Lw.y*255.+1.;
   float P=mix(10.,2.5,saturate(p*22.));
   float A=0.,j=0.;
   vec3 E=vec3(0.);
   {
     {
       vec2 U=texcoord.xy+x;
       U=U.xy*.5+vec2(0.,HalfScreen.y);
       vec2 DTR=R.xy*.5+HalfScreen;
       float M=0.;
       for(int V=1;V<=2;V++)
         {
           vec2 I=ScreenTexel*V*.5,I2=I*vec2(-1.,1.);
           vec4 q=(texture2DLod(colortex2,U.xy+I.xy,V)+
                   texture2DLod(colortex2,U.xy-I2.xy,V)+
                   texture2DLod(colortex2,U.xy+I2.xy,V)+
                   texture2DLod(colortex2,U.xy-I.xy,V))*.25;
           vec3 N=(texture2DLod(colortex2,DTR+I.xy,V).xyz+
                   texture2DLod(colortex2,DTR-I2.xy,V).xyz+
                   texture2DLod(colortex2,DTR+I2.xy,V).xyz+
                   texture2DLod(colortex2,DTR-I.xy,V).xyz)*.25;
           float Q=F(q.xyz,N)/(q.w+1e-09);
           E=vec3(q.w);
           Q*=400.;
           Q*=float(V);
           M+=Q;
         }
       A=M*mix(.01,.02,saturate(p*10.))*.066;
       if(t==MAT_ID_DYNAMIC_ENTITY||t==MAT_ID_HAND)
         A*=6.;
       else if(e<o)
         A*=4.;
     }
     {
       vec4 U=gbufferProjectionInverse*vec4(R.xy*2.-1.,J*2.-1.,1.);
       U/=U.w;
       vec3 V=(gbufferPreviousModelViewInverse*vec4(U.xyz,1.)).xyz;
       V-=cameraPositionDiff;
       float Q=length(w.xyz-V)/(length(w.xyz)+.001);
       Q=max(0.,Q-.05);
       A*=mix(1.,mix(3.,110.,saturate(p*360.)),saturate(Q*2.));
       j=saturate(Q*15.);
     }
     float V=exp(-A);
     f=mix(1.,f,V);
     if(V<.95)
       z=mix(texture2DLod(colortex1,v+x*.5,0).xyz,z,vec3(V));
     Lw.y*=exp(-A*.1);
   }
   Lw.y=min(Lw.y,128.);
   if(abs(R.x-.5)>.5||abs(R.y-.5)>.5)
     f=1.,Lw.y=0.;
   if(ExpToLinearDepth(e)-ExpToLinearDepth(a)>.9)
     P*=exp(-(length(l.xy)*length(z.xyz-S.xyz)/(length(z)+1e-07))*400.);
   vec3 V=sqrt(max(vec3(0.),Y-b*b))*P;
   S.xyz=g(D(b,V,z.xyz,D(S.xyz)));
   #ifdef SKIP_AA
   f=1.;
   #endif
   vec3 W=mix(S.xyz,z,vec3(f));
   W=max(vec3(0.),W);
   L.w=PackTwo16BitTo32Bit(Lw.x,Lw.y/255.);
   gl_FragData[0]=vec4(E,j);
   gl_FragData[1]=vec4(W,a);
   gl_FragData[2]=L;
   gl_FragData[3]=vec4(R.xy,0.,1.);
 };




/* DRAWBUFFERS:2357 */
