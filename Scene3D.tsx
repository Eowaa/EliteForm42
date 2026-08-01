"use client";

import { Canvas, useFrame } from "@react-three/fiber";
import {
  OrbitControls,
  Environment,
  Float,
} from "@react-three/drei";
import { useRef, Suspense } from "react";
import * as THREE from "three";

function RotatingCube() {
  const meshRef = useRef<THREE.Mesh>(null);

  useFrame((_, delta) => {
    if (meshRef.current) {
      meshRef.current.rotation.y += delta * 0.4;
      meshRef.current.rotation.x += delta * 0.15;
    }
  });

  return (
    <Float speed={1.5} rotationIntensity={0.4} floatIntensity={0.6}>
      <mesh ref={meshRef} castShadow receiveShadow>
        <boxGeometry args={[1.6, 1.6, 1.6]} />
        <meshStandardMaterial
          color="#c9a227"
          metalness={0.85}
          roughness={0.2}
          envMapIntensity={1.2}
        />
      </mesh>
      {/* Inner glow cube */}
      <mesh scale={0.98}>
        <boxGeometry args={[1.6, 1.6, 1.6]} />
        <meshBasicMaterial color="#e0b85a" transparent opacity={0.15} />
      </mesh>
    </Float>
  );
}

function GoldRing() {
  const ringRef = useRef<THREE.Mesh>(null);
  useFrame((_, delta) => {
    if (ringRef.current) {
      ringRef.current.rotation.z += delta * 0.3;
    }
  });

  return (
    <mesh ref={ringRef} rotation={[Math.PI / 2, 0, 0]} position={[0, 0, 0]}>
      <torusGeometry args={[2.2, 0.06, 16, 100]} />
      <meshStandardMaterial
        color="#c9a227"
        metalness={0.9}
        roughness={0.15}
        emissive="#c9a227"
        emissiveIntensity={0.2}
      />
    </mesh>
  );
}

function SceneContent() {
  return (
    <>
      <ambientLight intensity={0.3} />
      <directionalLight
        position={[5, 8, 5]}
        intensity={1.2}
        castShadow
        shadow-mapSize={[1024, 1024]}
      />
      <pointLight position={[-4, 3, -2]} intensity={0.6} color="#e0b85a" />
      <pointLight position={[3, -2, 4]} intensity={0.4} color="#ffffff" />

      <RotatingCube />
      <GoldRing />

      <OrbitControls
        enableZoom={true}
        enablePan={false}
        minDistance={3}
        maxDistance={8}
        autoRotate
        autoRotateSpeed={0.6}
      />
      <Environment preset="city" />
    </>
  );
}

function Loader() {
  return (
    <div className="absolute inset-0 flex items-center justify-center bg-dark-950/80">
      <div className="w-10 h-10 border-2 border-gold-500 border-t-transparent rounded-full animate-spin" />
    </div>
  );
}

interface Scene3DProps {
  className?: string;
  height?: string;
}

export default function Scene3D({
  className = "",
  height = "h-[420px] md:h-[520px]",
}: Scene3DProps) {
  return (
    <div
      className={`relative w-full ${height} rounded-2xl overflow-hidden gold-border bg-dark-950 ${className}`}
    >
      <Suspense fallback={<Loader />}>
        <Canvas
          camera={{ position: [0, 1.5, 5], fov: 45 }}
          gl={{ antialias: true, alpha: true }}
          dpr={[1, 1.5]}
        >
          <color attach="background" args={["#0a0a0a"]} />
          <fog attach="fog" args={["#0a0a0a", 6, 14]} />
          <SceneContent />
        </Canvas>
      </Suspense>
      <div className="absolute bottom-3 left-3 right-3 flex justify-between items-center pointer-events-none">
        <span className="text-[10px] uppercase tracking-widest text-gold-500/60">
          Interaktiv · Drehen & Zoomen
        </span>
        <span className="text-[10px] text-gold-500/40 font-mono">EliteForm42</span>
      </div>
    </div>
  );
}
