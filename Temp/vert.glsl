#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>

attribute vec4 tangent;

varying vec3 fragPos;
varying vec2 vUV;
varying mat3 TBN;

void main()
{
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>

	vUV = uv;
	mat3 normalMatrix = mat3(transpose(inverse(modelViewMatrix)));
	vec3 T = normalize(vec3(modelViewMatrix * vec4(tangent.xyz, 0.0)));
	vec3 N = normalize(vec3(modelViewMatrix * vec4(normal, 0.0)));
	vec3 B = normalize(vec3(modelViewMatrix * vec4(cross(T, N), 0.0)));
	TBN = (mat3(T, B, N));
	fragPos = vec3(modelViewMatrix * vec4(position, 1.0));
}
