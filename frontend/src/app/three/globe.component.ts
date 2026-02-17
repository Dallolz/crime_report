import {
  Component,
  Input,
  ElementRef,
  ViewChild,
  AfterViewInit,
  OnDestroy,
  OnChanges,
  SimpleChanges,
  NgZone,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

@Component({
  selector: 'app-globe',
  standalone: true,
  imports: [CommonModule],
  template: `<div #container class="w-full h-full"></div>`,
})
export class GlobeComponent implements AfterViewInit, OnDestroy, OnChanges {
  @ViewChild('container', { static: true }) containerRef!: ElementRef<HTMLDivElement>;
  @Input() markers: { lat: number; lng: number; label: string }[] = [];

  private scene!: THREE.Scene;
  private camera!: THREE.PerspectiveCamera;
  private renderer!: THREE.WebGLRenderer;
  private controls!: OrbitControls;
  private globe!: THREE.Mesh;
  private markerGroup!: THREE.Group;
  private animationId = 0;
  private resizeObserver!: ResizeObserver;

  constructor(private ngZone: NgZone) {}

  ngAfterViewInit(): void {
    this.ngZone.runOutsideAngular(() => {
      this.initScene();
      this.createGlobe();
      this.addLights();
      this.addMarkers();
      this.animate();
      this.setupResize();
    });
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['markers'] && this.scene) {
      this.addMarkers();
    }
  }

  ngOnDestroy(): void {
    cancelAnimationFrame(this.animationId);
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
    }
    if (this.controls) {
      this.controls.dispose();
    }
    if (this.renderer) {
      this.renderer.dispose();
    }
  }

  private initScene(): void {
    const container = this.containerRef.nativeElement;
    const width = container.clientWidth || 400;
    const height = container.clientHeight || 350;

    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x0f172a);

    this.camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 1000);
    this.camera.position.z = 3;

    this.renderer = new THREE.WebGLRenderer({ antialias: true });
    this.renderer.setSize(width, height);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    container.appendChild(this.renderer.domElement);

    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    this.controls.enableDamping = true;
    this.controls.dampingFactor = 0.05;
    this.controls.minDistance = 1.5;
    this.controls.maxDistance = 6;
    this.controls.autoRotate = true;
    this.controls.autoRotateSpeed = 0.5;
  }

  private createGlobe(): void {
    // Wireframe globe
    const geometry = new THREE.SphereGeometry(1, 48, 48);
    const material = new THREE.MeshPhongMaterial({
      color: 0x1e40af,
      wireframe: true,
      transparent: true,
      opacity: 0.3,
    });
    this.globe = new THREE.Mesh(geometry, material);
    this.scene.add(this.globe);

    // Inner solid sphere
    const innerGeometry = new THREE.SphereGeometry(0.98, 48, 48);
    const innerMaterial = new THREE.MeshPhongMaterial({
      color: 0x0f172a,
      transparent: true,
      opacity: 0.8,
    });
    const innerSphere = new THREE.Mesh(innerGeometry, innerMaterial);
    this.scene.add(innerSphere);

    // Atmosphere glow
    const atmosphereGeometry = new THREE.SphereGeometry(1.05, 48, 48);
    const atmosphereMaterial = new THREE.MeshBasicMaterial({
      color: 0x3b82f6,
      transparent: true,
      opacity: 0.08,
      side: THREE.BackSide,
    });
    const atmosphere = new THREE.Mesh(atmosphereGeometry, atmosphereMaterial);
    this.scene.add(atmosphere);

    // Equator and meridian lines
    this.addGridLines();
  }

  private addGridLines(): void {
    const lineMaterial = new THREE.LineBasicMaterial({
      color: 0x3b82f6,
      transparent: true,
      opacity: 0.15,
    });

    // Latitude lines
    for (let lat = -60; lat <= 60; lat += 30) {
      const phi = (90 - lat) * (Math.PI / 180);
      const points: THREE.Vector3[] = [];
      for (let lng = 0; lng <= 360; lng += 5) {
        const theta = lng * (Math.PI / 180);
        const x = 1.01 * Math.sin(phi) * Math.cos(theta);
        const y = 1.01 * Math.cos(phi);
        const z = 1.01 * Math.sin(phi) * Math.sin(theta);
        points.push(new THREE.Vector3(x, y, z));
      }
      const geometry = new THREE.BufferGeometry().setFromPoints(points);
      const line = new THREE.Line(geometry, lineMaterial);
      this.scene.add(line);
    }

    // Longitude lines
    for (let lng = 0; lng < 360; lng += 30) {
      const theta = lng * (Math.PI / 180);
      const points: THREE.Vector3[] = [];
      for (let lat = -90; lat <= 90; lat += 5) {
        const phi = (90 - lat) * (Math.PI / 180);
        const x = 1.01 * Math.sin(phi) * Math.cos(theta);
        const y = 1.01 * Math.cos(phi);
        const z = 1.01 * Math.sin(phi) * Math.sin(theta);
        points.push(new THREE.Vector3(x, y, z));
      }
      const geometry = new THREE.BufferGeometry().setFromPoints(points);
      const line = new THREE.Line(geometry, lineMaterial);
      this.scene.add(line);
    }
  }

  private addLights(): void {
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.4);
    this.scene.add(ambientLight);

    const pointLight1 = new THREE.PointLight(0x3b82f6, 2, 100);
    pointLight1.position.set(5, 3, 5);
    this.scene.add(pointLight1);

    const pointLight2 = new THREE.PointLight(0x8b5cf6, 1, 100);
    pointLight2.position.set(-5, -3, -5);
    this.scene.add(pointLight2);
  }

  private addMarkers(): void {
    if (this.markerGroup) {
      this.scene.remove(this.markerGroup);
    }

    this.markerGroup = new THREE.Group();

    this.markers.forEach((marker) => {
      const { x, y, z } = this.latLngToVector3(marker.lat, marker.lng, 1.02);

      // Marker dot
      const dotGeometry = new THREE.SphereGeometry(0.02, 8, 8);
      const dotMaterial = new THREE.MeshBasicMaterial({ color: 0xef4444 });
      const dot = new THREE.Mesh(dotGeometry, dotMaterial);
      dot.position.set(x, y, z);
      this.markerGroup.add(dot);

      // Glow ring
      const ringGeometry = new THREE.RingGeometry(0.03, 0.05, 16);
      const ringMaterial = new THREE.MeshBasicMaterial({
        color: 0xef4444,
        transparent: true,
        opacity: 0.5,
        side: THREE.DoubleSide,
      });
      const ring = new THREE.Mesh(ringGeometry, ringMaterial);
      ring.position.set(x, y, z);
      ring.lookAt(0, 0, 0);
      this.markerGroup.add(ring);

      // Pulse ring (animation will scale it)
      const pulseGeometry = new THREE.RingGeometry(0.04, 0.06, 16);
      const pulseMaterial = new THREE.MeshBasicMaterial({
        color: 0xef4444,
        transparent: true,
        opacity: 0.3,
        side: THREE.DoubleSide,
      });
      const pulse = new THREE.Mesh(pulseGeometry, pulseMaterial);
      pulse.position.set(x, y, z);
      pulse.lookAt(0, 0, 0);
      pulse.userData['isPulse'] = true;
      this.markerGroup.add(pulse);
    });

    this.scene.add(this.markerGroup);
  }

  private latLngToVector3(lat: number, lng: number, radius: number): THREE.Vector3 {
    const phi = (90 - lat) * (Math.PI / 180);
    const theta = (lng + 180) * (Math.PI / 180);

    const x = -(radius * Math.sin(phi) * Math.cos(theta));
    const y = radius * Math.cos(phi);
    const z = radius * Math.sin(phi) * Math.sin(theta);

    return new THREE.Vector3(x, y, z);
  }

  private animate(): void {
    this.animationId = requestAnimationFrame(() => this.animate());

    // Pulse animation for markers
    if (this.markerGroup) {
      const time = Date.now() * 0.001;
      this.markerGroup.children.forEach((child) => {
        if (child.userData['isPulse']) {
          const scale = 1 + Math.sin(time * 2) * 0.3;
          child.scale.set(scale, scale, scale);
          (child as THREE.Mesh).material = (child as THREE.Mesh).material as THREE.MeshBasicMaterial;
          ((child as THREE.Mesh).material as THREE.MeshBasicMaterial).opacity =
            0.3 * (1 - Math.sin(time * 2) * 0.5);
        }
      });
    }

    this.controls.update();
    this.renderer.render(this.scene, this.camera);
  }

  private setupResize(): void {
    const container = this.containerRef.nativeElement;
    this.resizeObserver = new ResizeObserver((entries) => {
      for (const entry of entries) {
        const { width, height } = entry.contentRect;
        if (width > 0 && height > 0) {
          this.camera.aspect = width / height;
          this.camera.updateProjectionMatrix();
          this.renderer.setSize(width, height);
        }
      }
    });
    this.resizeObserver.observe(container);
  }
}
