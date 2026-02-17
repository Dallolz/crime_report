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

@Component({
  selector: 'app-stats-chart',
  standalone: true,
  imports: [CommonModule],
  template: `<div #container class="w-full h-full"></div>`,
})
export class StatsChartComponent implements AfterViewInit, OnDestroy, OnChanges {
  @ViewChild('container', { static: true }) containerRef!: ElementRef<HTMLDivElement>;
  @Input() data: { label: string; value: number; color: string }[] = [];

  private scene!: THREE.Scene;
  private camera!: THREE.PerspectiveCamera;
  private renderer!: THREE.WebGLRenderer;
  private barGroup!: THREE.Group;
  private animationId = 0;
  private resizeObserver!: ResizeObserver;
  private animationProgress = 0;
  private targetScales: number[] = [];

  constructor(private ngZone: NgZone) {}

  ngAfterViewInit(): void {
    this.ngZone.runOutsideAngular(() => {
      this.initScene();
      this.addLights();
      this.createBars();
      this.animate();
      this.setupResize();
    });
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['data'] && this.scene) {
      this.createBars();
      this.animationProgress = 0;
    }
  }

  ngOnDestroy(): void {
    cancelAnimationFrame(this.animationId);
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
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

    this.camera = new THREE.PerspectiveCamera(50, width / height, 0.1, 1000);
    this.camera.position.set(4, 3, 5);
    this.camera.lookAt(0, 0, 0);

    this.renderer = new THREE.WebGLRenderer({ antialias: true });
    this.renderer.setSize(width, height);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    container.appendChild(this.renderer.domElement);
  }

  private addLights(): void {
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    this.scene.add(ambientLight);

    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(5, 10, 5);
    this.scene.add(directionalLight);

    const pointLight = new THREE.PointLight(0x3b82f6, 0.5, 100);
    pointLight.position.set(-3, 5, -3);
    this.scene.add(pointLight);
  }

  private createBars(): void {
    if (this.barGroup) {
      this.scene.remove(this.barGroup);
    }

    this.barGroup = new THREE.Group();
    this.targetScales = [];

    if (!this.data || this.data.length === 0) {
      this.scene.add(this.barGroup);
      return;
    }

    const maxValue = Math.max(...this.data.map((d) => d.value), 1);
    const barWidth = 0.5;
    const gap = 0.3;
    const totalWidth = this.data.length * (barWidth + gap) - gap;
    const startX = -totalWidth / 2;

    // Floor grid
    const gridHelper = new THREE.GridHelper(totalWidth + 2, 10, 0x334155, 0x1e293b);
    gridHelper.position.y = -0.01;
    this.barGroup.add(gridHelper);

    this.data.forEach((item, index) => {
      const normalizedHeight = (item.value / maxValue) * 3;
      this.targetScales.push(normalizedHeight);

      const x = startX + index * (barWidth + gap) + barWidth / 2;

      // Bar
      const geometry = new THREE.BoxGeometry(barWidth, 1, barWidth);
      geometry.translate(0, 0.5, 0); // Pivot from bottom

      const color = new THREE.Color(item.color);
      const material = new THREE.MeshPhongMaterial({
        color,
        transparent: true,
        opacity: 0.9,
        shininess: 60,
      });

      const bar = new THREE.Mesh(geometry, material);
      bar.position.set(x, 0, 0);
      bar.scale.y = 0.01; // Start small for animation
      bar.userData['targetScale'] = normalizedHeight;
      this.barGroup.add(bar);

      // Top glow
      const glowGeometry = new THREE.BoxGeometry(barWidth + 0.05, 0.05, barWidth + 0.05);
      const glowMaterial = new THREE.MeshBasicMaterial({
        color,
        transparent: true,
        opacity: 0.5,
      });
      const glow = new THREE.Mesh(glowGeometry, glowMaterial);
      glow.position.set(x, 0.01, 0);
      glow.userData['isGlow'] = true;
      glow.userData['barIndex'] = index;
      this.barGroup.add(glow);

      // Label using a sprite
      const canvas = document.createElement('canvas');
      canvas.width = 256;
      canvas.height = 64;
      const ctx = canvas.getContext('2d')!;
      ctx.fillStyle = '#94a3b8';
      ctx.font = 'bold 28px Inter, sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      const displayText = item.label.length > 10 ? item.label.substring(0, 9) + '..' : item.label;
      ctx.fillText(displayText, 128, 32);

      const texture = new THREE.CanvasTexture(canvas);
      const spriteMaterial = new THREE.SpriteMaterial({
        map: texture,
        transparent: true,
      });
      const sprite = new THREE.Sprite(spriteMaterial);
      sprite.position.set(x, -0.3, 0);
      sprite.scale.set(1.2, 0.3, 1);
      this.barGroup.add(sprite);

      // Value label
      const valCanvas = document.createElement('canvas');
      valCanvas.width = 128;
      valCanvas.height = 64;
      const valCtx = valCanvas.getContext('2d')!;
      valCtx.fillStyle = '#ffffff';
      valCtx.font = 'bold 36px Inter, sans-serif';
      valCtx.textAlign = 'center';
      valCtx.textBaseline = 'middle';
      valCtx.fillText(String(item.value), 64, 32);

      const valTexture = new THREE.CanvasTexture(valCanvas);
      const valSpriteMaterial = new THREE.SpriteMaterial({
        map: valTexture,
        transparent: true,
      });
      const valSprite = new THREE.Sprite(valSpriteMaterial);
      valSprite.position.set(x, 0.01, 0);
      valSprite.scale.set(0.6, 0.3, 1);
      valSprite.userData['isValueLabel'] = true;
      valSprite.userData['barIndex'] = index;
      this.barGroup.add(valSprite);
    });

    this.scene.add(this.barGroup);
    this.animationProgress = 0;
  }

  private animate(): void {
    this.animationId = requestAnimationFrame(() => this.animate());

    // Entrance animation
    if (this.animationProgress < 1) {
      this.animationProgress = Math.min(this.animationProgress + 0.02, 1);
      const eased = this.easeOutCubic(this.animationProgress);

      if (this.barGroup) {
        let barIndex = 0;
        this.barGroup.children.forEach((child) => {
          if (child instanceof THREE.Mesh && child.userData['targetScale'] !== undefined) {
            child.scale.y = child.userData['targetScale'] * eased;
          }
          if (child.userData['isGlow'] && child.userData['barIndex'] !== undefined) {
            const idx = child.userData['barIndex'];
            if (this.targetScales[idx] !== undefined) {
              child.position.y = this.targetScales[idx] * eased;
            }
          }
          if (child.userData['isValueLabel'] && child.userData['barIndex'] !== undefined) {
            const idx = child.userData['barIndex'];
            if (this.targetScales[idx] !== undefined) {
              child.position.y = this.targetScales[idx] * eased + 0.3;
            }
          }
        });
      }
    }

    // Slow rotation
    const time = Date.now() * 0.0002;
    if (this.camera) {
      this.camera.position.x = 4 * Math.cos(time) + 0.5;
      this.camera.position.z = 5 * Math.sin(time) + 0.5;
      this.camera.lookAt(0, 1, 0);
    }

    this.renderer.render(this.scene, this.camera);
  }

  private easeOutCubic(t: number): number {
    return 1 - Math.pow(1 - t, 3);
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
