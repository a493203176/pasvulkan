#version 450 core

layout (location = 0) in vec3 inUV;
layout (location = 1) in vec4 inBackgroundColor;
layout (location = 2) in vec4 inForegroundColor;

layout (binding = 0) uniform UBO {
	float uThreshold;
} ubo;

layout (binding = 1) uniform sampler2DArray uSamplerFont;

layout (location = 0) out vec4 outFragColor;

void main(void){
  outFragColor = mix(inBackgroundColor, inForegroundColor, smoothstep(ubo.uThreshold, -ubo.uThreshold, (texture(uSamplerFont, inUV).r - 0.5) * 2.0));
}
