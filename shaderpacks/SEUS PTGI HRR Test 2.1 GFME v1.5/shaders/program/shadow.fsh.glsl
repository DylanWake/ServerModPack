#extension GL_ARB_shading_language_packing : enable
#extension GL_ARB_shader_bit_encoding : enable


in vec4 texcoord;
in vec4 color;
in vec4 viewPos;
in vec3 worldPos;
in vec2 midTexCoord;
in float textureResolution;
in float materialIDs;
in float mcEntity;
in float isVoxelOutput;


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/Common.inc"


 void main()
 {
   vec4 v=texture2D(texture,texcoord.xy,0);
   vec3 f=v.xyz*color.xyz;
   if(isVoxelOutput<.5)
     {
       float x=1.;
       x=min(v.w*7.,1.);
       vec3 i=(shadowModelViewInverse*vec4(viewPos.xyz,1.)).xyz;
       f.xyz=normalize(f.xyz+1e-4)*sqrt(length(f.xyz));
       f.xyz=mix(vec3(1.),f.xyz,vec3(pow(v.w,.2)));
       i+=cameraPosition.xyz;
       gl_FragData[0]=vec4(f.xyz,x);
       gl_FragData[1]=vec4(i.y/256.,0.,0.,x);
     }
   else
     {
       f.xyz*=sqrt(3.0)/length(color.xyz);
       f=pow(f,vec3(2.2));
       if(abs(mcEntity-50.)<.1)
         {
           vec3 c=worldPos+cameraPosition.xyz+random3(vec3(frameTimeCounter*2e-8));
           vec3 i=hash33(c);
           f.xyz=KelvinToRGB(float(TORCHLIGHT_COLOR_TEMPERATURE*mix(.85,1.,i.x)))*mix(.1,.2,i.y)*GI_LIGHT_TORCH_INTENSITY;
         }
       else if(abs(mcEntity-51.)<.1)
         f.xyz=vec3(1.,.35,.025)*GI_LIGHT_BLOCK_INTENSITY;
       else if(abs(mcEntity-52.5)<1.)
       {
         float intensity=mcEntity-52.;
         f.xyz=vec3(.1,.9,1.)*(.2+intensity*.8)*GI_LIGHT_TORCH_INTENSITY;
       }
       else if(abs(mcEntity-74.)<.1)
         f.xyz=vec3(1.,.02,.01)*.15*GI_LIGHT_BLOCK_INTENSITY;
       else if(abs(mcEntity-76.)<.1)
         f.xyz=vec3(1.,.02,.01)*.1*GI_LIGHT_TORCH_INTENSITY;
       else if(abs(mcEntity-92.)<.1)
         f.xyz=vec3(.4,0.,1.)*.2*GI_LIGHT_BLOCK_INTENSITY;
       else if(abs(mcEntity-117.)<.1)
         f.xyz=vec3(1.,.3,.0)*.05*GI_LIGHT_TORCH_INTENSITY;
       else if(abs(mcEntity-138.)<.1)
         f.xyz=vec3(.4,1.,1.)*.15*GI_LIGHT_BLOCK_INTENSITY;
       else if(abs(mcEntity-182.5)<2.)
         {
           float intensity=(mcEntity-181.)/10.;
           f.xyz=vec3(.4+intensity,intensity,1.)*.15*pow(2.,intensity*10.)*GI_LIGHT_TORCH_INTENSITY;
         }
       else if(abs(mcEntity-186.5)<2.)
         {
           float intensity=(mcEntity-184.5)/3.;
           vec3 c=worldPos+cameraPosition.xyz+random3(vec3(frameTimeCounter*2e-8));
           vec3 i=hash33(c);
           f.xyz=KelvinToRGB(float(TORCHLIGHT_COLOR_TEMPERATURE*mix(.85,1.,i.x)))*mix(.1,.2,i.y)*intensity*GI_LIGHT_TORCH_INTENSITY;
         }
       else if(abs(mcEntity-190.5)<2.)
         {
           float intensity=mcEntity-188.5;
           f.xyz=vec3(.8,1.,.8)*.07*intensity*GI_LIGHT_TORCH_INTENSITY;
         }
       else if(abs(mcEntity-198.)<.1)
         f.xyz=vec3(1.,1.,1.)*.1*GI_LIGHT_BLOCK_INTENSITY;
       else if(abs(mcEntity-213.)<.1)
         f.xyz=vec3(1.,.2,.0)*.1*GI_LIGHT_BLOCK_INTENSITY;
       f.xyz*=step(.1,abs(mcEntity-124.))+1.;
       float y=step(1e-3,abs(color.x-color.y)+abs(color.x-color.z)+abs(color.y-color.z));
       f.xyz=normalize(f.xyz+1e-05)*min(length(f.xyz),.95);
       gl_FragData[0]=vec4(f.xyz,(materialIDs+.1)/255.);
       gl_FragData[1]=vec4(midTexCoord.xy,y,textureResolution/255.);
     }
 }



