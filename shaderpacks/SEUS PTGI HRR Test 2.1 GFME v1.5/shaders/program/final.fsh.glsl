#extension GL_ARB_gpu_shader5 : enable


#include "/lib/Settings.inc"
#include "/lib/Uniforms.inc"
#include "/lib/Common.inc"


in vec4 texcoord;


void main() {

	vec3 color = texture2D(colortex0, texcoord.st).rgb;
	// color = GammaToLinear(color);

	#ifndef SKIP_AA
	// Sharpen
	{
		vec2 texel = 0.5 / vec2(viewWidth, viewHeight);
		vec3 cs = texture2D(colortex0, texcoord.st + vec2(texel.x, texel.y)  ).rgb;
		cs += 	  texture2D(colortex0, texcoord.st + vec2(texel.x, -texel.y) ).rgb;
		cs += 	  texture2D(colortex0, texcoord.st + vec2(-texel.x, texel.y) ).rgb;
		cs += 	  texture2D(colortex0, texcoord.st + vec2(-texel.x, -texel.y)).rgb;
		cs -= color;
		cs /= 3.0;

		float gain = 1.0;
		#if PIXEL_LOOK == 1
		gain = 2.0;
		#endif

		// color += clamp(dot(color - cs, vec3(0.333333)), -0.001, 0.001) * 12.3 * pow(Luminance(color), 0.5);
		const float sClamp = 0.1;
		color += clamp(dot(color - cs, vec3(0.333333)), -sClamp, sClamp)
				* gain * POST_SHARPENING
				* sqrt(Luminance(color)) * normalize(color.rgb + 0.00000001);
	}
	#endif

	gl_FragColor = vec4(color, 1.0);
}
