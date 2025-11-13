#include <common>
#include <lights_pars_begin>

uniform sampler2D normalMap;
uniform vec3 cameraPos;

varying vec3 fragPos;
varying vec3 fragColor;
varying vec2 vUV;
varying vec3 vNormal;

void main()
{
	vNormal = normalize(normal);
	fragPos = vec3(modelMatrix * vec4(position, 1.0));

	vec3 norm = normalize(texture2D(normalMap, uv).rgb * 2.0 - 1.0);
	vec3 diffuse, specular, ambient = ambientLightColor;

	#if NUM_DIR_LIGHTS > 0

		vec3 lightDir = normalize(directionalLights[0].direction);
		float diff = max(0.0, dot(norm, lightDir));
		diffuse = directionalLights[0].color * diff;

	#endif

	fragColor = ambient + diffuse + specular;

	vUV = uv;
	gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
