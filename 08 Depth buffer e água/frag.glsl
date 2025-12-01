#include <common>
#include <packing>
#include <fog_pars_fragment>

struct Material
{
	vec3 diffuseColor;
	vec3 specularColor;
	float shininess;
};

uniform vec3 waterColor;
uniform vec3 foamColor;
uniform vec2 resolution;
uniform float cameraNear;
uniform float cameraFar;
uniform float threshold;
uniform float time;
uniform sampler2D tDepth;
uniform sampler2D tDudv;
uniform Material material;

varying vec2 vUV;
varying vec3 vNormal;
varying vec3 viewDir;
varying vec3 fragPos;

float getDepth(vec2 screenPosition)
{
	return unpackRGBAToDepth(texture2D(tDepth, screenPosition));
}

float getViewZ(float depth)
{
	if (isOrthographic)
		return orthographicDepthToViewZ(depth, cameraNear, cameraFar);
	else
		return perspectiveDepthToViewZ(depth, cameraNear, cameraFar);
}

void main()
{
	vec2 screenUV = gl_FragCoord.xy / resolution;
	float fragmentLinearEyeDepth = getViewZ(gl_FragCoord.z);
	float linearEyeDepth = getViewZ(getDepth(screenUV));
	float diff = saturate(fragmentLinearEyeDepth - linearEyeDepth);

	gl_FragColor = vec4(mix(foamColor, waterColor, diff), 1.0);
}
