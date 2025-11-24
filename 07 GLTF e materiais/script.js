// https://learnopengl.com/Advanced-Lighting/Shadows/Shadow-Mapping
// https://github.com/mrdoob/three.js/tree/master/src/renderers/shaders/ShaderChunk

import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";

var camera, scene, renderer, spotTarget, dirTarget, mesh, controls;

init();

function setMeshMaterial(mesh, material)
{
	if (mesh.isMesh)
	{
		mesh.geometry.computeTangents();
		mesh.castShadow = mesh.receiveShadow = true;
		const map = mesh.material.map;
		const shaderMaterial = material.clone();
		const uniforms = THREE.UniformsUtils.merge([material.uniforms, mesh.material.uniforms ? mesh.material.uniforms : THREE.ShaderLib["standard"].uniforms]);
		if (!uniforms.normalMap.value)
			uniforms.useNormalMap.value = false;
		for(var k in mesh.material)
			if (k != "uniforms" && k != "type" && k != "uuid" && k != "vertexShader" && k != "fragmentShader")
				shaderMaterial[k] = mesh.material[k];
		mesh.material = shaderMaterial;
		mesh.material.uniforms = uniforms;
		mesh.material.uniforms.material.value.specularColor = new THREE.Vector3(0, 0, 0);
		mesh.material.map = map;
	}
	for (var i = 0; i < mesh.children.length; i++)
		setMeshMaterial(mesh.children[i], material);
}

async function init()
{
	const vert = await (await fetch("vert.glsl")).text();
	const frag = await (await fetch("frag.glsl")).text();

	camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 0.1, 100);
	camera.position.set(0, 3, 3);
	scene = new THREE.Scene();
	scene.add(camera);
	scene.add(new THREE.AmbientLight(0xaaaaaa));

	const gltfLoader = new GLTFLoader();
	const gltf = await gltfLoader.loadAsync("assets/scooby_doo.glb");
	mesh = gltf.scene;
	scene.add(mesh);

	const textureLoader = new THREE.TextureLoader();
	const texture = textureLoader.load("assets/goose.png");
	const geometry = new THREE.BoxGeometry(1, 1, 1);
	geometry.computeTangents();
	const material = new THREE.ShaderMaterial(
	{
		uniforms: THREE.UniformsUtils.merge(
		[
			THREE.UniformsLib["common"],
			THREE.UniformsLib["lights"],
			{
				cameraPos: { value: camera.position },
				myTexture: { value: textureLoader.load("assets/goose.png") },
				normalMap: { value: textureLoader.load("assets/normal_map.png") },
				useNormalMap: { value: true },
				useTexture: { value: true },
				noTexColor: { value: new THREE.Color(0, 0, 0) },

				material:
				{
					value:
					{
						diffuseColor: new THREE.Vector3(0.75, 0.75, 0.75),
						specularColor: new THREE.Vector3(0.75, 0.75, 0.75),
						shininess: 32
					}
				}
			}
		]),
		vertexShader: vert,
		fragmentShader: frag,
		lights: true
	});

	setMeshMaterial(mesh, material);

	dirTarget = new THREE.Object3D();
	spotTarget = new THREE.Object3D();
	scene.add(dirTarget);
	scene.add(spotTarget);

	const planeGeo = new THREE.PlaneGeometry(10, 10);
	const planeMat = material.clone();
	planeMat.uniforms.useTexture.value = false;
	planeMat.uniforms.useNormalMap.value = false;
	planeMat.uniforms.noTexColor.value = new THREE.Color(0.8, 0.8, 0.8);
	const floor = new THREE.Mesh(planeGeo, planeMat);
	floor.castShadow = floor.receiveShadow = true;
	floor.rotation.set(-Math.PI / 2, 0, 0);
	scene.add(floor);

	const dirLight = new THREE.DirectionalLight(0xffffff, 0.75);
	dirLight.position.set(15, 15, 15);
	dirLight.target = dirTarget;
	dirLight.castShadow = true;
	const d = 10;
	dirLight.shadow.camera.left = -d;
	dirLight.shadow.camera.right = d;
	dirLight.shadow.camera.top = d;
	dirLight.shadow.camera.bottom = -d;
	dirLight.shadow.camera.far = d * 2;
	//dirLight.shadow.bias = 0.0002;
	dirLight.shadow.mapSize = new THREE.Vector2(4096, 4096);
	scene.add(dirLight);
    const cameraHelper = new THREE.CameraHelper(dirLight.shadow.camera);
    scene.add(cameraHelper);
/*
	const pointLight1 = new THREE.PointLight(0xffffff, 3.0);
	pointLight1.position.set(-3, 2, 0);
	pointLight1.castShadow = true;
	scene.add(pointLight1);
	const pointLight2 = new THREE.PointLight(0xffffff, 3.0);
	pointLight2.position.set(3, 2, 0);
	pointLight2.castShadow = true;
	scene.add(pointLight2);
	pointLight1.shadow.bias = pointLight2.shadow.bias = 0.00005;

	const spotLight = new THREE.SpotLight(0xffffff, 4.0);
	spotLight.target = spotTarget;
	spotLight.position.set(3, 3, 3);
	spotLight.penumbra = 0.15;
	spotLight.castShadow = true;
	scene.add(spotLight);
*/
	renderer = new THREE.WebGLRenderer({ antialias: true });
	renderer.setClearColor(0xffffff, 1);
	renderer.setPixelRatio(window.devicePixelRatio);
	renderer.setSize(window.innerWidth, window.innerHeight);
	renderer.setAnimationLoop(animate);
	renderer.shadowMap.enabled = true;
	document.body.appendChild(renderer.domElement);

	controls = new OrbitControls(camera, renderer.domElement);
	controls.maxPolarAngle = Infinity;

	window.addEventListener("resize", onWindowResize);
}

function onWindowResize()
{
	camera.aspect = window.innerWidth / window.innerHeight;
	camera.updateProjectionMatrix();
	renderer.setSize(window.innerWidth, window.innerHeight);
}

function animate()
{
	controls.update();
	renderer.render(scene, camera);
}
