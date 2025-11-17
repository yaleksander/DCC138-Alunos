// https://learnopengl.com/Advanced-Lighting/Shadows/Shadow-Mapping
// https://github.com/mrdoob/three.js/tree/master/src/renderers/shaders/ShaderChunk

import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";

var camera, scene, renderer, spotTarget, dirTarget, rot, mesh, controls;

init();

function fixChildren(mesh, material)
{
	if (mesh.isMesh)
	{
		mesh.geometry.computeTangents();
		mesh.material = material;
		/*
		const shaderMaterial = new THREE.ShaderMaterial();
		shaderMaterial.vertexShader = material.vertexShader;
		shaderMaterial.fragmentShader = material.fragmentShader;
		for(var k in mesh.material)
			shaderMaterial[k] = mesh.material[k];
		//for(var k in material)
		//	shaderMaterial[k] = material[k];
		mesh.material = shaderMaterial;
		*/
	}
	for (var i = 0; i < mesh.children.length; i++)
		fixChildren(mesh.children[i], material);
}

async function init()
{
	const vert = await (await fetch("vert.glsl")).text();
	const frag = await (await fetch("frag.glsl")).text();

	camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 0.1, 100);
	camera.position.set(0, 2, 2);
	scene = new THREE.Scene();
	scene.add(camera);
	scene.add(new THREE.AmbientLight(0x777777));

	const gltfLoader = new GLTFLoader();
	const gltf = await gltfLoader.loadAsync("assets/scooby_doo.glb");
	mesh = gltf.scene;
	scene.add(mesh);

	const textureLoader = new THREE.TextureLoader();
	const geometry = new THREE.BoxGeometry(1, 1, 1);
	geometry.computeTangents();
	const material = new THREE.ShaderMaterial(
	{
		uniforms: THREE.UniformsUtils.merge(
		[
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
						specular: new THREE.Vector3(0.75, 0.75, 0.75),
						shininess: 16
					}
				}
			}
		]),
		vertexShader: vert,
		fragmentShader: frag,
		lights: true
	});

	console.log(THREE.ShaderLib['standard'].vertexShader);
	fixChildren(mesh, material);

	rot = 0;
	dirTarget = new THREE.Object3D();
	spotTarget = new THREE.Object3D();
	scene.add(dirTarget);
	scene.add(spotTarget);

	/*
	const s = 3;
	box = new THREE.Mesh(geometry, material.clone());
	box.position.set(0, 0.5, 0);
	box.castShadow = true;
	scene.add(box);
	*/

	const planeGeo = new THREE.PlaneGeometry(10, 10);
	const planeMat = material.clone();
	planeMat.uniforms.useTexture.value = false;
	planeMat.uniforms.useNormalMap.value = false;
	planeMat.uniforms.noTexColor.value = new THREE.Color(0.8, 0.8, 0.8);
	const floor = new THREE.Mesh(planeGeo, planeMat);
	floor.castShadow = floor.receiveShadow = true;
	floor.rotation.set(-Math.PI / 2, 0, 0);
	scene.add(floor);

	const dirLight = new THREE.DirectionalLight(0xffffff, 0.25);
	dirLight.position.set(-5, 5, -5);
	dirLight.target = dirTarget;
	dirLight.castShadow = true;
	const d = 10;
	dirLight.shadow.camera.left = -d;
	dirLight.shadow.camera.right = d;
	dirLight.shadow.camera.top = d;
	dirLight.shadow.camera.bottom = -d;
	dirLight.shadow.camera.far = d * 2;
	dirLight.shadow.bias = 0.02;
	dirLight.shadow.mapSize = new THREE.Vector2(4096, 4096);
	scene.add(dirLight);
    const cameraHelper = new THREE.CameraHelper(dirLight.shadow.camera);
    scene.add(cameraHelper);

	const pointLight1 = new THREE.PointLight(0xffffff, 3.0);
	pointLight1.position.set(-3, 2, 0);
	pointLight1.castShadow = true;
	scene.add(pointLight1);
	const pointLight2 = new THREE.PointLight(0xffffff, 3.0);
	pointLight2.position.set(3, 2, 0);
	pointLight2.castShadow = true;
	scene.add(pointLight2);

	const spotLight = new THREE.SpotLight(0xffffff, 4.0);
	spotLight.target = spotTarget;
	spotLight.position.set(3, 3, 3);
	spotLight.penumbra = 0.15;
	spotLight.castShadow = true;
	scene.add(spotLight);

	renderer = new THREE.WebGLRenderer({ antialias: true });
	renderer.setClearColor(0xffffff, 1);
	renderer.setPixelRatio(window.devicePixelRatio);
	renderer.setSize(window.innerWidth, window.innerHeight);
	renderer.setAnimationLoop(animate);
	renderer.shadowMap.enabled = true;
	document.body.appendChild(renderer.domElement);

	controls = new OrbitControls(camera, renderer.domElement);
	controls.maxPolarAngle = Infinity;
	controls.enablePan = false;

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
