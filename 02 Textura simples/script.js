import * as THREE from "https://threejs.org/build/three.module.js";

var camera, scene, renderer, mesh;

init();

async function init()
{
	const vert = await (await fetch("vert.glsl")).text();
	const frag = await (await fetch("frag.glsl")).text();

	camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 0.1, 100);
	camera.position.z = 1;

	scene = new THREE.Scene();

	const texture = new THREE.TextureLoader().load("./goose.png");
	const material = new THREE.ShaderMaterial(
	{
		uniforms:
		{
			myTexture: { value: texture },
		},
		vertexShader: vert,
		fragmentShader: frag
	});
	mesh = new THREE.Mesh(new THREE.PlaneGeometry(), material);
	scene.add(mesh);

	renderer = new THREE.WebGLRenderer({ antialias: true });
	renderer.setClearColor(0xffffff, 1);
	renderer.setPixelRatio(window.devicePixelRatio);
	renderer.setSize(window.innerWidth, window.innerHeight);
	renderer.setAnimationLoop(animate);
	document.body.appendChild(renderer.domElement);

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
	renderer.render(scene, camera);
}
