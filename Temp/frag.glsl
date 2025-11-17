#include <common>
#include <packing>
#include <lights_pars_begin>
#include <shadowmap_pars_fragment>

struct Material
{
	vec3 specular;
	float shininess;
};

uniform sampler2D myTexture;
uniform sampler2D normalMap;
uniform vec3 cameraPos;
uniform bool useTexture;
uniform bool useNormalMap;
uniform vec3 noTexColor;
uniform Material material;

varying vec2 vUV;
varying vec3 fragPos;
varying mat3 TBN;

void main()
{
	vec3 ambient = ambientLightColor, phong = vec3(0.0);
	vec3 lightDir, viewDir, reflectDir;	
	float diff, spec, dist, att, shadow;
	vec3 normal = useNormalMap ? normalize(TBN * (texture2D(normalMap, vUV).rgb * 2.0 - 1.0)) : normalize(TBN * vec3(0.0, 0.0, 1.0));

	#if NUM_DIR_LIGHTS > 0

		#pragma unroll_loop_start
		for (int i = 0; i < NUM_DIR_LIGHTS; i++)
		{
			// diffuse
			lightDir = normalize(directionalLights[0].direction);
			diff = max(0.0, dot(normal, lightDir));

			// specular
			viewDir = normalize(cameraPos - fragPos);
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
			phong += (diff + material.specular * spec) * directionalLights[0].color * shadow;
		}
		#pragma unroll_loop_end

	#endif

	#if NUM_POINT_LIGHTS > 0

		#pragma unroll_loop_start
		for (int i = 0; i < NUM_POINT_LIGHTS; i++)
		{
			dist = length(pointLights[i].position - fragPos);
			att = getDistanceAttenuation(dist, pointLights[i].distance, pointLights[0].decay);

			// diffuse
			lightDir = normalize(pointLights[i].position - fragPos);
			diff = max(0.0, dot(normal, lightDir));

			// specular
			viewDir = normalize(cameraPos - fragPos);
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
			phong += (diff + material.specular * spec) * pointLights[i].color * att * shadow;
		}
		#pragma unroll_loop_end

	#endif

	#if NUM_SPOT_LIGHTS > 0

		#pragma unroll_loop_start
		for (int i = 0; i < NUM_SPOT_LIGHTS; i++)
		{
			dist = length(spotLights[0].position - fragPos);
			lightDir = normalize(spotLights[0].position - fragPos);
			att = getDistanceAttenuation(dist, spotLights[0].distance, spotLights[0].decay);
			att *= getSpotAttenuation(spotLights[0].coneCos, spotLights[0].penumbraCos, dot(lightDir, spotLights[0].direction));

			// diffuse
			diff = max(0.0, dot(normal, lightDir));

			// specular
			viewDir = normalize(cameraPos - fragPos);
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
			phong += (diff + material.specular * spec) * spotLights[0].color * att * shadow;
		}
		#pragma unroll_loop_end

	#endif

	shadow = 1.0;//getShadowMask();
	gl_FragColor = (useTexture ? texture2D(myTexture, vUV) : vec4(noTexColor, 1.0)) * vec4(ambient + phong * shadow, 1.0);
	gl_FragColor = vec4(1.0 - gl_FragColor.r, 1.0 - gl_FragColor.g, 1.0 - gl_FragColor.b, gl_FragColor.a);
}
