#include "/program/template/PathTraceDenoiser.glsl"


 void main()
 {
   vec4 y=G(colortex7,texcoord.xy,true,2.,2.,vec2(1.,0.));
   float z=1.;
   if(texcoord.y<.25)
     {
       vec2 i=texcoord.xy*vec2(4.,4.),n=vec2(i.x,(i.y-floor(fract(frameTimeCounter)*60.f))/60.f);
       int index=int(texcoord.x*4.0);
       z=texture2DLod(colortex0,n.xy,0)[index];
     }
   gl_FragData[0]=vec4(y.xyz,z);
 };

/* DRAWBUFFERS:7 */
