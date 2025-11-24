#include <common>
#include <packing>
#include <uv_pars_fragment>
#include <fog_pars_fragment>
#include <lights_pars_begin>
#include <shadowmap_pars_fragment>

struct Material
{
	vec3 diffuseColor;
	vec3 specularColor;
	float shininess;
};

uniform sampler2D map;
uniform sampler2D myTexture;
uniform sampler2D normalMap;
uniform vec3 cameraPos;
uniform bool useTexture;
uniform bool useNormalMap;
uniform vec3 noTexColor;
uniform Material material;

varying vec2 vUV;
varying vec3 vNormal;
varying vec3 fragPos;

void main()
{
	vec3 ambient = ambientLightColor, phong = vec3(0.0);
	vec3 lightDir, reflectDir, viewDir = normalize(cameraPos - fragPos);
	float diff, spec, dist, att, shadow;
	vec3 normal = vNormal;

	#if NUM_DIR_LIGHTS > 0

		#pragma unroll_loop_start
		for (int i = 0; i < NUM_DIR_LIGHTS; i++)
		{
			// diffuse
			lightDir = normalize(directionalLights[i].direction);
			diff = max(0.0, dot(normal, lightDir));

			// specular
			reflectDir = reflect(-lightDir, normal);
			spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);

			// shadow
			shadow = 1.0;
			#if UNROLLED_LOOP_INDEX < NUM_DIR_LIGHT_SHADOWS
				shadow = receiveShadow ? getShadow(
					directionalShadowMap[i],
					directionalLightShadows[i].shadowMapSize,
					directionalLightShadows[i].shadowIntensity,
					directionalLightShadows[i].shadowBias,
					directionalLightShadows[i].shadowRadius,
					vDirectionalShadowCoord[i]
				) : 1.0;
			#endif

			// phong
			phong += (diff * material.diffuseColor + spec * material.specularColor) * directionalLights[i].color * shadow;
		}
		#pragma unroll_loop_end

	#endif

	#if NUM_POINT_LIGHTS > 0

		#pragma unroll_loop_start
		for (int i = 0; i < NUM_POINT_LIGHTS; i++)
		{
			dist = length(pointLights[i].position - fragPos);
			att = getDistanceAttenuation(dist, pointLights[i].distance, pointLights[i].decay);

			// diffuse
			lightDir = normalize(pointLights[i].position - fragPos);
			diff = max(0.0, dot(normal, lightDir));

			// specular
			reflectDir = reflect(-lightDir, normal);
			spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);

			// shadow
			shadow = 1.0;
			#if UNROLLED_LOOP_INDEX < NUM_POINT_LIGHT_SHADOWS
				shadow = receiveShadow ? getPointShadow(
					pointShadowMap[i],
					pointLightShadows[i].shadowMapSize,
					pointLightShadows[i].shadowIntensity,
					pointLightShadows[i].shadowBias,
					pointLightShadows[i].shadowRadius,
					vPointShadowCoord[i],
					pointLightShadows[i].shadowCameraNear,
					pointLightShadows[i].shadowCameraFar
				) : 1.0;
			#endif

			// phong
			phong += (diff * material.diffuseColor + spec * material.specularColor) * pointLights[i].color * att * shadow;
		}
		#pragma unroll_loop_end

	#endif

	#if NUM_SPOT_LIGHTS > 0

		#pragma unroll_loop_start
		for (int i = 0; i < NUM_SPOT_LIGHTS; i++)
		{
			dist = length(spotLights[i].position - fragPos);
			lightDir = normalize(spotLights[i].position - fragPos);
			att = getDistanceAttenuation(dist, spotLights[i].distance, spotLights[i].decay);
			att *= getSpotAttenuation(spotLights[i].coneCos, spotLights[i].penumbraCos, dot(lightDir, spotLights[i].direction));

			// diffuse
			diff = max(0.0, dot(normal, lightDir));

			// specular
			reflectDir = reflect(-lightDir, normal);
			spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);

			// shadow
			shadow = 1.0;
			#if UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS
				shadow = receiveShadow ? getShadow(
					spotShadowMap[i],
					spotLightShadows[i].shadowMapSize,
					spotLightShadows[i].shadowIntensity,
					spotLightShadows[i].shadowBias,
					spotLightShadows[i].shadowRadius,
					vSpotLightCoord[i]
				) : 1.0;
			#endif

			// phong
			phong += (diff * material.diffuseColor + spec * material.specularColor) * spotLights[i].color * att * shadow;
		}
		#pragma unroll_loop_end

	#endif

	gl_FragColor = (useTexture ? texture2D(map, vUV) : vec4(noTexColor, 1.0)) * vec4(ambient + phong, 1.0);

	#include <fog_fragment>
}
