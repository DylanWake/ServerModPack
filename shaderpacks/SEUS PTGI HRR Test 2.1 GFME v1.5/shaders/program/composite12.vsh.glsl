out vec4 texcoord;


void main() {
	gl_Position = ftransform();
	texcoord = gl_MultiTexCoord0;

	gl_Position.xy = gl_Position.xy * 0.5 + 0.5;
	texcoord.x *= 0.51;
	gl_Position.x *= 0.51;
	gl_Position.xy = gl_Position.xy * 2.0 - 1.0;

}
