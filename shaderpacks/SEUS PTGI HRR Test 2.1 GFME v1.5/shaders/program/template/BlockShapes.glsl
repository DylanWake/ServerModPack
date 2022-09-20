 vec3 d(const vec3 v,const vec3 z,vec3 y)
 {
   vec3 i=(z-v)*.5,m=y-(z+v)*.5;
   vec3 f=sign(m)*step(abs(abs(m)-i),vec3(1e-05));
   return normalize(f);
 }
 bool d(vec3 v,vec3 i,Ray m,inout float x,inout vec3 y)
 {
   vec3 z=m.inv_direction*(v-1e-05-m.origin),t=m.inv_direction*(i+1e-05-m.origin),n=min(t,z),s=max(t,z);
   float c=max(max(n.x,n.y),n.z);
   float f=min(min(s.x,s.y),s.z);
   bool w=f>max(c,0.)&&max(c,0.)<x;
   if(w)
     y=d(v-1e-05,i+1e-05,m.origin+m.direction*c),x=c;
   return w;
 }
 bool c(vec3 v,float y,Ray f,inout float x,inout vec3 t)
 {
   bool i=false,m=false;
   #if RAYTRACE_GEOMETRY_QUALITY==0
   if(y>=67.)
     return false;
   m=d(v,v+vec3(1.,1.,1.),f,x,t);
   i=m;
   #else
   if(y<40.)
     {
       return m=d(v,v+vec3(1.,1.,1.),f,x,t),m;
     }
   else if(y==40.||y==41.||abs(y-48.5)<6.)
     {
       float r=.5;
       if(y==41.)
         r=.9375;
       m=d(v,v+vec3(1.,r,1.),f,x,t);
       i=i||m;
       if(y<42.)
         return i;
     }
   if(y==42.||abs(y-60.5)<6.)
     {
       m=d(v+vec3(0.,.5,0.),v+vec3(1.,1.,1.),f,x,t),i=i||m;
       if(y<43.)
         return i;
     }
   if(abs(y-54.5)<12.)
     {
       float mody12=mod(y,12.);
       if(mody12!=1.&&mody12!=2.&&mody12!=8.)
         {
           float mody3=mod(y,3),s=.5,e=.5;
           if(mody3!=0.||y==54.||y==66.)
             s=0.;
           if(mody12!=4.&&mody12!=10.&&mody12!=11.)
             e=1.;
           m=d(v+vec3(s,0.,0.),v+vec3(e,1.,.5),f,x,t);
           i=i||m;
         }
       if(mody12!=0.&&mody12!=7.&&mody12!=11.)
         {
           float s=.5,e=.5;
           if(mody12!=1.&&mody12!=6.&&mody12!=9.)
             s=0.;
           if(mody12!=2.&&mody12!=5.&&mody12!=10.)
             e=1.;
           m=d(v+vec3(s,0.,.5),v+vec3(e,1.,1.),f,x,t);
           i=i||m;
         }
       return i;
     }
   if(abs(y-74.5)<8.)
     {
       float mody4=mod(y,4);
       m=d(v+vec3(6.,0.,6.)/16.,v+vec3(10.,16.,10.)/16.,f,x,t),i=i||m;
       if(mody4!=3.)
         {
           float mody2=mod(y,2),r=8.,s=8.;
           if(mody2==0.)
             r=0.;
           if(mody4!=0.)
             s=16.;
           m=d(v+vec3(r,6.,7.)/16.,v+vec3(s,9.,9.)/16.,f,x,t);
           i=i||m;
           m=d(v+vec3(r,12.,7.)/16.,v+vec3(s,15.,9.)/16.,f,x,t);
           i=i||m;
         }
       if(y>=71.)
         {
           float r=8.,w=8.;
           if(abs(y-76.5)>2.)
             w=16.;
           if(y>=75.)
             r=0.;
           m=d(v+vec3(7.,6.,r)/16.,v+vec3(9.,9.,w)/16.,f,x,t);
           i=i||m;
           m=d(v+vec3(7.,12.,r)/16.,v+vec3(9.,15.,w)/16.,f,x,t);
           i=i||m;
         }
       return i;
     }
   else if(abs(y-84.5)<2.)
     {
       vec3 r=vec3(0,0,0),c=vec3(1,1,3./16.);
       if(y==84.)
         r.z=13./16.,c.z=1.;
       if(y==86.)
         c.xz=vec2(3./16.,1);
       if(y==85.)
         r.x=13./16.,c.z=1.;
       m=d(v+r,v+c,f,x,t);
       i=i||m;
       return i;
     }
   else if(abs(y-89.5)<3.)
     {
       vec3 r=vec3(0.),c=vec3(1.);
       if(y<=88.)
         {
           float s=0.;
           if(y==88.)
             s=13.;
           r=vec3(0.,s/16.,0.);
           c=vec3(1.,(s+3.)/16.,1.);
           m=d(v+r,v+c,f,x,t);
           i=i||m;
           return i;
         }
       if(abs(y-89.5)==.5)
         {
           float s=13.;
           if(y==90.)
             s=0.;
           r=vec3(0.,0.,s/16.);
           c=vec3(1.,1.,(s+3.)/16.);
           m=d(v+r,v+c,f,x,t);
           i=i||m;
           return i;
         }
       if(y>=91.)
         {
           float s=13.;
           if(y==91.)
             s=0.;
           r=vec3(s/16.,0.,0.);
           c=vec3((s+3.)/16.,1.,1.);
           m=d(v+r,v+c,f,x,t);
           i=i||m;
           return i;
         }
     }
   else if(abs(y-100.)<8.||y==140.)
     {
       vec3 r=vec3(0.),s=vec3(1.);
       if(y<=100.)
         {
           float n=y-92.;
           s.y=n*2./16.;
         }
       else if(y==101.)
         s.y=.0625;
       else if(y==102.)
         r=vec3(1.,0.,1.)/16.,s=vec3(15.,1.,15.)/16.;
       else if(y==103.)
         r=vec3(1.,0.,1.)/16.,s=vec3(15.,.5,15.)/16.;
       else if(y==105.)
         s.y=9./16.;
       else if(y==106.||y==140.)
         s.y=13./16.;
       else if(y==107.)
         r=vec3(1.,0.,1.)/16.,s=vec3(15.,16.,15.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       if(y==140.)
         {
           vec3 r=vec3(0.),s=vec3(1.);
           r=vec3(4.,13.,4.)/16.,s=vec3(12.,16.,12.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
         }
       return i;
     }
   #if RAYTRACE_GEOMETRY_QUALITY==2
   else if(abs(y-130.5)<9.||y>=229.)
     {
       if(y<=137.||abs(y-239.)<11.)
         {
           m=d(v+vec3(4.,0.,4.)/16.,v+vec3(12.,16.,12.)/16.,f,x,t);
           i=i||m;
         }
       if(y==123.||y==125.||abs(y-129.)<3.||abs(y-135.5)<3.||abs(y-246.5)<1.)
         {
           float r=.5,s=.5;
           if(y==123.||y==127.||abs(y-130.5)<1.||y==133.||abs(y-136.5)<2.||y==247.)
             r=0.;
           if(y==125.||abs(y-128.5)<1.||y==131.||abs(y-134)<2.||abs(y-137.5)<1.||y==246.)
             s=1.;
           m=d(v+vec3(5./16.,0.,r),v+vec3(11./16.,14./16.,s),f,x,t);
           i=i||m;
         }
       if(y==124.||abs(y-128.)<3.||abs(y-134.5)<3.||y==139.||y==248.||y==249.)
         {
           float r=.5,s=.5;
           if(y==126.||abs(y-129.5)<1.||y==132.||abs(y-135)<2.||y==139.||y==248.)
             r=0.;
           if(y==124.||abs(y-127.5)<1.||abs(y-133.)<2.||abs(y-136.5)<1.||y==139.||y==249.)
             s=1.;
           m=d(v+vec3(r,0.,5./16.),v+vec3(s,14./16.,11./16.),f,x,t);
           i=i||m;
         }
       if(y==229.||y==231.||abs(y-235.)<3.||abs(y-243.)<5.||y==250.)
         {
           float r=.5,s=.5;
           if(y==229.||y==233.||abs(y-236.5)<1.||y==239.||abs(y-244.5)<2.||y==250.)
             r=0.;
           if(y==231.||abs(y-234.5)<1.||y==237.||y==239.||abs(y-242.5)<1.||y==245.||y==247.||y==250.)
             s=1.;
           m=d(v+vec3(5./16.,0.,r),v+vec3(11./16.,1.,s),f,x,t);
           i=i||m;
         }
       if(y==230.||abs(y-234.)<3.||abs(y-241.5)<4.||y==248.||y==249.||y==251.)
         {
           float r=.5,s=.5;
           if(y==232.||abs(y-235.5)<1.||y==238.||abs(y-243.5)<2.||y==249.||y==251.)
             r=0.;
           if(y==230.||abs(y-233.5)<1.||abs(y-238.5)<1.||y==242.||abs(y-244.5)<1.||y==248.||y==251.)
             s=1.;
           m=d(v+vec3(r,0.,5./16.),v+vec3(s,1.,11./16.),f,x,t);
           i=i||m;
         }
       return i;
     }
   else if(abs(y-152.)<11.)
     {
       if(y<=157.)
         {
           vec3 r=vec3(4.,0.,4.)/16.,s=vec3(12.,12.,12.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(5.,12.,5.)/16.,s=vec3(11.,14.,11.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
         }
       else if(y==158.)
         {
           vec3 r=vec3(4.,0.,4.)/16.,s=vec3(12.,16.,12.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y>=159.)
         {
           vec3 r=vec3(0.),s=vec3(1.);
           r=vec3(4.,4.,4.)/16.,s=vec3(12.,16.,12.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
         }
       if(y==143.||y==145.||abs(y-149.)<3.||abs(y-155.)<3.||y==159.||y==161.)
         {
           float r=8.,s=8.;
           if(y==143.||y==147.||abs(y-150.5)<1.||y==153.||abs(y-156.)<2.||y==159.)
             r=0.;
           if(y==145.||abs(y-148.5)<1.||y==151.||abs(y-154.)<2.||y==157.||y==161.)
             s=16.;
           m=d(v+vec3(4.,4.,r)/16.,v+vec3(12.,12.,s)/16.,f,x,t);
           i=i||m;
         }
       if(y==144.||abs(y-148.)<3.||abs(y-154.5)<3.||y==160.||y==162.)
         {
           float r=8.,s=8.;
           if(y==146.||abs(y-149.5)<1.||y==152.||abs(y-155.5)<2.||y==162.)
             r=0.;
           if(y==144.||abs(y-147.5)<1.||abs(y-153.)<1.||abs(y-156.5)<1.||y==160.)
             s=16.;
           m=d(v+vec3(r,4.,4.)/16.,v+vec3(s,12.,12.)/16.,f,x,t);
           i=i||m;
         }
       return i;
     }
   else if(abs(y-227.5)<1.)
     {
       if(y==227.)
         {
           m=d(v+vec3(5./16.,0.,0.),v+vec3(11.,1.,16.)/16.,f,x,t);
           i=i||m;
           m=d(v+vec3(1./16.,0.,0.),v+vec3(5.,4.,16.)/16.,f,x,t);
           i=i||m;
           m=d(v+vec3(11./16.,0.,0.),v+vec3(15.,4.,16.)/16.,f,x,t);
           i=i||m;
           m=d(v+vec3(0.,3.,1.)/16.,v+vec3(16.,7.,5.)/16.,f,x,t);
           i=i||m;
           m=d(v+vec3(0.,3.,11.)/16.,v+vec3(16.,7.,15.)/16.,f,x,t);
           i=i||m;
           return i;
         }
       else
         {
           m=d(v+vec3(0.,0.,5./16.),v+vec3(16.,1.,11.)/16.,f,x,t);
           i=i||m;
           m=d(v+vec3(0.,0.,1./16.),v+vec3(16.,4.,5.)/16.,f,x,t);
           i=i||m;
           m=d(v+vec3(0.,0.,11./16.),v+vec3(16.,4.,15.)/16.,f,x,t);
           i=i||m;
           m=d(v+vec3(1.,3.,0.)/16.,v+vec3(5.,7.,16.)/16.,f,x,t);
           i=i||m;
           m=d(v+vec3(11.,3.,0.)/16.,v+vec3(15.,7.,16.)/16.,f,x,t);
           i=i||m;
           return i;
         }
     }
   else if(abs(y-108.5)<1.)
     {
       vec3 r=vec3(0.),s=vec3(1.);
       r=vec3(2.,0.,2.)/16.,s=vec3(14.,4.,14.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       if(y==108.)
         {
           r=vec3(4.,4.,3.)/16.,s=vec3(12.,5.,13.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(6.,5.,4.)/16.,s=vec3(10.,10.,12.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(3.,10.,0.)/16.,s=vec3(13./16.,1.,1.);
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else
         {
           r=vec3(3.,4.,4.)/16.,s=vec3(13.,5.,12.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(4.,5.,6.)/16.,s=vec3(12.,10.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(0.,10.,3.)/16.,s=vec3(1.,1.,13./16.);
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
     }
   else if(abs(y-112.5)<3.)
     {
       vec3 r=vec3(0.),s=vec3(1.);
       if(y==110.)
         {
           s.y=12./16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(6.,12.,6.)/16.,s=vec3(10.,16.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==111.)
         {
           r.y=4./16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(6.,0.,6.)/16.,s=vec3(10.,4.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==112.)
         {
           r.z=4./16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(6.,6.,0.)/16.,s=vec3(10.,10.,4.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==113.)
         {
           s.z=12./16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(6.,6.,12.)/16.,s=vec3(10.,10.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==114.)
         {
           s.x=12./16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(12.,6.,6.)/16.,s=vec3(16.,10.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else
         {
           r.x=4./16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(0.,6.,6.)/16.,s=vec3(4.,10.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
     }
   else if(abs(y-118.5)<3.)
     {
       vec3 r=vec3(0.),s=vec3(1.);
       if(y==116.)
         {
           r.y=12./16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(6.,0.,6.)/16.,s=vec3(10.,12.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==117.)
         {
           s.y=4./16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(6.,4.,6.)/16.,s=vec3(10.,16.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==118.)
         {
           s.z=4./16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(6.,6.,4.)/16.,s=vec3(10.,10.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==119.)
         {
           r.z=12./16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(6.,6.,0.)/16.,s=vec3(10.,10.,12.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==120.)
         {
           r.x=12./16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(0.,6.,6.)/16.,s=vec3(12.,10.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else
         {
           s.x=4./16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(4.,6.,6.)/16.,s=vec3(16.,10.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
     }
   else if(y==141.)
     {
       vec3 r=vec3(0.),s=vec3(1.);
       r=vec3(2.,0.,2.)/16.,s=vec3(14.,16.,14.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(2.,2.,0.)/16.,s=vec3(14.,14.,16.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(0.,2.,2.)/16.,s=vec3(16.,14.,14.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       return i;
     }
   else if(abs(y-166.5)<4.)
     {
       vec3 r=vec3(0.),s=vec3(1.);
       if(y==163.)
         {
           r=vec3(2.,0.,6.)/16.,s=vec3(4.,7.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(12.,0.,6.)/16.,s=vec3(14.,7.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(2.,7.,5.)/16.,s=vec3(14.,13.,11.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(4.,4.,2.)/16.,s=vec3(12.,16.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==164.)
         {
           r=vec3(6.,0.,2.)/16.,s=vec3(10.,7.,4.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(6.,0.,12.)/16.,s=vec3(10.,7.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(5.,7.,2.)/16.,s=vec3(11.,13.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(2.,4.,4.)/16.,s=vec3(14.,16.,12.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==165.)
         {
           r=vec3(12.,6.,9.)/16.,s=vec3(14.,10.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(2.,6.,9.)/16.,s=vec3(4.,10.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(2.,5.,3.)/16.,s=vec3(14.,11.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(4.,2.,0.)/16.,s=vec3(12.,14.,12.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==166.)
         {
           r=vec3(12.,6.,0.)/16.,s=vec3(14.,10.,7.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(2.,6.,0.)/16.,s=vec3(4.,10.,7.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(2.,5.,7.)/16.,s=vec3(14.,11.,13.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(4.,2.,4.)/16.,s=vec3(12.,14.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==167.)
         {
           r=vec3(0.,6.,12.)/16.,s=vec3(7.,10.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(0.,6.,2.)/16.,s=vec3(7.,10.,4.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(7.,5.,2.)/16.,s=vec3(13.,11.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(4.,2.,4.)/16.,s=vec3(16.,14.,12.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==168.)
         {
           r=vec3(9.,6.,12.)/16.,s=vec3(16.,10.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(9.,6.,2.)/16.,s=vec3(16.,10.,4.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(3.,5.,2.)/16.,s=vec3(9.,11.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(0.,2.,4.)/16.,s=vec3(12.,14.,12.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==169.)
         {
           r=vec3(2.,9.,6.)/16.,s=vec3(4.,16.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(12.,9.,6.)/16.,s=vec3(14.,16.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(2.,3.,5.)/16.,s=vec3(14.,9.,11.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(4.,0.,2.)/16.,s=vec3(12.,12.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else
         {
           r=vec3(6.,9.,2.)/16.,s=vec3(10.,16.,4.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(6.,9.,12.)/16.,s=vec3(10.,16.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(5.,3.,2.)/16.,s=vec3(11.,9.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(2.,0.,4.)/16.,s=vec3(14.,12.,12.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
     }
   else if(abs(y-172)<2.)
     {
       vec3 r=vec3(0.),s=vec3(1.);
       if(y==171.)
         {
           r=vec3(5.,0.,5.)/16.,s=vec3(11.,4.,11.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(5.,4.,5.)/16.,s=vec3(6.,6.,11.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           s=vec3(11.,6.,6.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(5.,4.,10.)/16.,s=vec3(11.,6.,11.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(10.,4.,5.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==172.)
         {
           s.y=2./16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r.y=2./16.,s=vec3(1.,1.,2./16.);
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(0.,2./16.,0.),s=vec3(2./16.,1.,1.);
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(0.,2.,14.)/16.,s.x=1.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(14.,2.,0.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else
         {
           r.y=3./16.,s.y=4./16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r.y=4./16.,s=vec3(1.,1.,2./16.);
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           s=vec3(2./16.,1.,1.);
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(0.,4.,14.)/16.,s=vec3(1.,1.,1.);
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(14.,4.,0.)/16.,s=vec3(1.,1.,1.);
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(0.,0.,0.),s=vec3(2.,3.,4.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           s=vec3(4.,3.,2.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(0.,0.,12./16.),s=vec3(2.,3.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(0.,0.,14./16.),s=vec3(4.,3.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(12./16.,0.,0.),s=vec3(16.,3.,2.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(14./16.,0.,0.),s=vec3(16.,3.,4.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(12.,0.,14.)/16.,s=vec3(1.,3./16.,1.);
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(14.,0.,12.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
     }
   else if(abs(y-176)<3.)
     {
       vec3 r=vec3(0.),s=vec3(1.);
       r.y=10./16.,s.y=11./16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(0.,11./16.,0.),s=vec3(1.,1.,2./16.);
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(0.,11./16.,0.),s=vec3(2./16.,1.,1.);
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(0.,11.,14.)/16.,s=vec3(1.,1.,1.);
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(14.,11.,0.)/16.,s=vec3(1.,1.,1.);
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(4.,4.,4.)/16.,s=vec3(12.,10.,12.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(6.,0.,6.)/16.,s=vec3(10.,4.,10.)/16.;
       if(y==175.)
         {
           r.yz=vec2(4.,0.)/16.,s.yz=vec2(8.,4.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==176.)
         {
           r.yz=vec2(4.,12.)/16.,s.yz=vec2(8.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==177.)
         {
           r.xy=vec2(12.,4.)/16.,s.xy=vec2(16.,8.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==178.)
         {
           r.xy=vec2(0.,4.)/16.,s.xy=vec2(4.,8.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else
         {
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
     }
   else if(abs(y-186.5)<8.)
     {
       vec3 r=vec3(0.),s=vec3(1.);
       if(y==179)
         {
           r=vec3(5.,0.,6.)/16.,s=vec3(11.,2.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==180)
         {
           r=vec3(6.,0.,5.)/16.,s=vec3(10.,2.,11.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==181.)
         {
           r=vec3(5.,6.,14.)/16.,s=vec3(11.,10.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==182.)
         {
           r=vec3(5.,6.,0.)/16.,s=vec3(11.,10.,2.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==183.)
         {
           r=vec3(0.,6.,5.)/16.,s=vec3(2.,10.,11.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==184.)
         {
           r=vec3(14.,6.,5.)/16.,s=vec3(16.,10.,11.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==185.)
         {
           r=vec3(5.,14.,6.)/16.,s=vec3(11.,16.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==186.)
         {
           r=vec3(6.,14.,5.)/16.,s=vec3(10.,16.,11.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==187)
         {
           r=vec3(5.,0.,6.)/16.,s=vec3(11.,1.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==188)
         {
           r=vec3(6.,0.,5.)/16.,s=vec3(10.,1.,11.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==189.)
         {
           r=vec3(5.,6.,15.)/16.,s=vec3(11.,10.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==190.)
         {
           r=vec3(5.,6.,0.)/16.,s=vec3(11.,10.,1.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==191.)
         {
           r=vec3(0.,6.,5.)/16.,s=vec3(1.,10.,11.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==192.)
         {
           r=vec3(15.,6.,5.)/16.,s=vec3(16.,10.,11.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==193.)
         {
           r=vec3(5.,15.,6.)/16.,s=vec3(11.,16.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else
         {
           r=vec3(6.,15.,5.)/16.,s=vec3(10.,16.,11.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
   }
   else if(y==195)
     {
       vec3 r=vec3(0.),s=vec3(1.);
       s=vec3(1.,2./16.,1.);
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(4.,2.,4.)/16.,s=vec3(12.,15.,12.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       return i;
     }
   else if(abs(y-201.5)<6.)
     {
       vec3 r=vec3(0.),s=vec3(1.);
       if(y==196)
         {
           r=vec3(0.,5.,7.)/16.,s=vec3(2.,16.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(14.,5.,7.)/16.,s=vec3(16.,16.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(2.,6.,7.)/16.,s=vec3(14.,9.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(2.,12.,7.)/16.,s=vec3(14.,15.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(6.,9.,7.)/16.,s=vec3(10.,12.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==197)
         {
           r=vec3(7.,5.,0.)/16.,s=vec3(9.,16.,2.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(7.,5.,14.)/16.,s=vec3(9.,16.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(7.,6.,2.)/16.,s=vec3(9.,9.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(7.,12.,2.)/16.,s=vec3(9.,15.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(7.,9.,6.)/16.,s=vec3(9.,12.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(abs(y-198.5)<1.)
         {
           r=vec3(0.,5.,7.)/16.,s=vec3(2.,16.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(14.,5.,7.)/16.,s=vec3(16.,16.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           if(y==198.)
             {
               r=vec3(0.,12.,3.)/16.,s=vec3(2.,15.,7.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(14.,12.,3.)/16.,s=vec3(16.,15.,7.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(0.,6.,3.)/16.,s=vec3(2.,9.,7.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(14.,6.,3.)/16.,s=vec3(16.,9.,7.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(0.,6.,1.)/16.,s=vec3(2.,15.,3.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(14.,6.,1.)/16.,s=vec3(16.,15.,3.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               return i;
             }
           else
             {
               r=vec3(0.,12.,9.)/16.,s=vec3(2.,15.,13.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(14.,12.,9.)/16.,s=vec3(16.,15.,13.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(0.,6.,9.)/16.,s=vec3(2.,9.,13.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(14.,6.,9.)/16.,s=vec3(16.,9.,13.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(0.,6.,13.)/16.,s=vec3(2.,15.,15.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(14.,6.,13.)/16.,s=vec3(16.,15.,15.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               return i;
             }
         }
       else if(abs(y-200.5)<1.)
         {
           r=vec3(7.,5.,0.)/16.,s=vec3(9.,16.,2.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(7.,5.,14.)/16.,s=vec3(9.,16.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           if(y==200.)
             {
               r=vec3(9.,12.,0.)/16.,s=vec3(13.,15.,2.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(9.,12.,14.)/16.,s=vec3(13.,15.,16.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(9.,6.,0.)/16.,s=vec3(13.,9.,2.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(9.,6.,14.)/16.,s=vec3(13.,9.,16.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(13.,6.,0.)/16.,s=vec3(15.,15.,2.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(13.,6.,14.)/16.,s=vec3(15.,15.,16.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               return i;
             }
           else
             {
               r=vec3(3.,12.,0.)/16.,s=vec3(7.,15.,2.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(3.,12.,14.)/16.,s=vec3(7.,15.,16.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(3.,6.,0.)/16.,s=vec3(7.,9.,2.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(3.,6.,14.)/16.,s=vec3(7.,9.,16.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(1.,6.,0.)/16.,s=vec3(3.,15.,2.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(1.,6.,14.)/16.,s=vec3(3.,15.,16.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               return i;
             }
         }
       else if(y==202)
         {
           r=vec3(0.,2.,7.)/16.,s=vec3(2.,13.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(14.,2.,7.)/16.,s=vec3(16.,13.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(2.,3.,7.)/16.,s=vec3(14.,6.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(2.,9.,7.)/16.,s=vec3(14.,12.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(6.,6.,7.)/16.,s=vec3(10.,9.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==203)
         {
           r=vec3(7.,2.,0.)/16.,s=vec3(9.,13.,2.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(7.,2.,14.)/16.,s=vec3(9.,13.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(7.,3.,2.)/16.,s=vec3(9.,6.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(7.,9.,2.)/16.,s=vec3(9.,12.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(7.,6.,6.)/16.,s=vec3(9.,9.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(abs(y-204.5)<1.)
         {
           r=vec3(0.,2.,7.)/16.,s=vec3(2.,13.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(14.,2.,7.)/16.,s=vec3(16.,13.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           if(y==204.)
             {
               r=vec3(0.,9.,3.)/16.,s=vec3(2.,12.,7.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(14.,9.,3.)/16.,s=vec3(16.,12.,7.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(0.,3.,3.)/16.,s=vec3(2.,6.,7.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(14.,3.,3.)/16.,s=vec3(16.,6.,7.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(0.,3.,1.)/16.,s=vec3(2.,12.,3.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(14.,3.,1.)/16.,s=vec3(16.,12.,3.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               return i;
             }
           else
             {
               r=vec3(0.,9.,9.)/16.,s=vec3(2.,12.,13.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(14.,9.,9.)/16.,s=vec3(16.,12.,13.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(0.,3.,9.)/16.,s=vec3(2.,6.,13.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(14.,3.,9.)/16.,s=vec3(16.,6.,13.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(0.,3.,13.)/16.,s=vec3(2.,12.,15.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(14.,3.,13.)/16.,s=vec3(16.,12.,15.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               return i;
             }
         }
       else
         {
           r=vec3(7.,2.,0.)/16.,s=vec3(9.,13.,2.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(7.,2.,14.)/16.,s=vec3(9.,13.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           if(y==206.)
             {
               r=vec3(9.,9.,0.)/16.,s=vec3(13.,12.,2.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(9.,9.,14.)/16.,s=vec3(13.,12.,16.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(9.,3.,0.)/16.,s=vec3(13.,6.,2.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(9.,3.,14.)/16.,s=vec3(13.,6.,16.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(13.,3.,0.)/16.,s=vec3(15.,12.,2.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(13.,3.,14.)/16.,s=vec3(15.,12.,16.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               return i;
             }
           else
             {
               r=vec3(3.,9.,0.)/16.,s=vec3(7.,12.,2.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(3.,9.,14.)/16.,s=vec3(7.,12.,16.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(3.,3.,0.)/16.,s=vec3(7.,6.,2.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(3.,3.,14.)/16.,s=vec3(7.,6.,16.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(1.,3.,0.)/16.,s=vec3(3.,12.,2.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               r=vec3(1.,3.,14.)/16.,s=vec3(3.,12.,16.)/16.;
               m=d(v+r,v+s,f,x,t);
               i=i||m;
               return i;
             }
         }
     }
   else if(abs(y-208.5)<1.)
     {
       vec3 r=vec3(0.),s=vec3(1.);
       r.y=1.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r.y=0.,s=vec3(2.,16.,2.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(0.,0.,14./16.),s=vec3(2./16.,1.,1.);
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(14./16.,0.,0.),s=vec3(1.,1.,2./16.);
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(14.,0.,14.)/16.,s=vec3(1.,1.,1.);
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(0.,14.,2.)/16.,s=vec3(2.,16.,14.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(2.,14.,0.)/16.,s=vec3(14.,16.,2.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(14.,14.,2.)/16.,s=vec3(1.,1.,14./16.);
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(2.,14.,14.)/16.,s=vec3(14./16.,1.,1.);
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       if(y==209.)
         {
           r=vec3(2.,2.,2.)/16.,s=vec3(14.,2.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(0.,0.,2./16.),s=vec3(2.,2.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(2./16.,0.,0.),s=vec3(14.,2.,2.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(14.,0.,2.)/16.,s=vec3(16.,2.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(2.,0.,14.)/16.,s=vec3(14.,2.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
         }
       return i;
     }
   else if(abs(y-214.)<5.)
     {
       vec3 r=vec3(0.),s=vec3(1.);
       r=vec3(4.,4.,4.)/16.,s=vec3(12.,6.,12.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(5.,6.,5.)/16.,s=vec3(11.,13.,11.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       if(y==210.)
         {
           r=vec3(0.,0.,6./16.),s=vec3(2.,16.,10.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(14.,0.,6.)/16.,s=vec3(1.,1.,10./16.);
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(2.,13.,7.)/16.,s=vec3(14.,15.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==211.)
         {
           r=vec3(6./16.,0.,0.),s=vec3(10.,16.,2.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(6.,0.,14.)/16.,s=vec3(10./16.,1.,1.);
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           r=vec3(7.,13.,2.)/16.,s=vec3(9.,15.,14.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==212.)
         {
           r=vec3(7.,13.,0.)/16.,s=vec3(9.,15.,13.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==213.)
         {
           r=vec3(7.,13.,3.)/16.,s=vec3(9.,15.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==214.)
         {
           r=vec3(3.,13.,7.)/16.,s=vec3(16.,15.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==215.)
         {
           r=vec3(0.,13.,7.)/16.,s=vec3(13.,15.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==216.)
         {
           r=vec3(7.,13.,0.)/16.,s=vec3(9.,15.,16.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else if(y==217.)
         {
           r=vec3(0.,13.,7.)/16.,s=vec3(16.,15.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
       else
         {
           r=vec3(7.,13.,7.)/16.,s=vec3(9.,16.,9.)/16.;
           m=d(v+r,v+s,f,x,t);
           i=i||m;
           return i;
         }
     }
   else if(abs(y-222.)<4.)
     {
       float r=2.*(y-219)+1.;
       r/=16.;
       m=d(v+vec3(r,0.,1./16.),v+vec3(15.,8.,15.)/16,f,x,t);
       i=i||m;
       return i;
     }
   else if(y==226.)
     {
       vec3 r=vec3(3.,0.,3.)/16.,s=vec3(13.,13.,13.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(2.,1.,2.)/16.,s=vec3(14.,11.,14.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(1.,3.,1.)/16.,s=vec3(15.,8.,15.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(5.,13.,5.)/16.,s=vec3(11.,15.,11.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       r=vec3(6.,15.,6.)/16.,s=vec3(10.,16.,10.)/16.;
       m=d(v+r,v+s,f,x,t);
       i=i||m;
       return i;
     }
   #endif
   #endif
   return i;
 }
