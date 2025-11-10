#include <common>
#include <lights_pars_begin>

struct Material
{
	vec3 specular;
	float shininess;
};

uniform sampler2D myTexture;
uniform sampler2D normalMap;
uniform vec3 cameraPos;
uniform Material material;

varying vec2 vUV;
varying vec3 fragPos;
varying mat3 TBN;

void main()
{
	vec3 ambient = ambientLightColor, phong = vec3(0.0);
	vec3 lightDir, viewDir, reflectDir;	
	float diff, spec, dist, att;
	vec3 normal = normalize(TBN * (texture2D(normalMap, vUV).rgb * 2.0 - 1.0));

	#if NUM_DIR_LIGHTS > 0

		// diffuse
		lightDir = normalize(-directionalLights[0].direction);
		diff = max(0.0, dot(normal, lightDir));
		phong += directionalLights[0].color * diff;

		// specular
		viewDir = normalize(cameraPos - fragPos);
		reflectDir = reflect(-lightDir, normal);
		spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
		phong += material.specular * spec * directionalLights[0].color;

	#endif

	gl_FragColor = texture2D(myTexture, vUV) * vec4(ambient + phong, 1.0);
}
