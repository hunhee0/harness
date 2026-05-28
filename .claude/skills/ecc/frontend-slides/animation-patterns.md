# 애니메이션 패턴 레퍼런스

프레젠테이션 생성 시 이 레퍼런스 사용. 의도된 느낌에 애니메이션 매칭.

## 효과→느낌 가이드

| Feeling | Animations | Visual Cues |
|---------|-----------|-------------|
| **Dramatic / Cinematic** | 느린 fade-in (1-1.5s)·대규모 전환 (0.9 to 1)·parallax 스크롤 | 다크 배경·spotlight 효과·full-bleed 이미지 |
| **Techy / Futuristic** | Neon glow (box-shadow)·glitch/scramble 텍스트·그리드 reveal | 파티클 시스템 (canvas)·그리드 패턴·monospace 액센트·cyan/magenta/electric blue |
| **Playful / Friendly** | Bouncy easing (spring 물리)·floating/bobbing | 둥근 코너·pastel/bright 색상·hand-drawn 요소 |
| **Professional / Corporate** | 미묘한 빠른 애니메이션 (200-300ms)·깨끗한 슬라이드 | Navy/slate/charcoal·정밀 간격·데이터 시각화 초점 |
| **Calm / Minimal** | 매우 느린 미묘한 모션·gentle fade | 많은 whitespace·muted 팔레트·serif 타이포그래피·넉넉한 패딩 |
| **Editorial / Magazine** | 교차 텍스트 reveal·이미지-텍스트 상호작용 | 강한 타입 계층·pull quote·그리드 깨기 레이아웃·serif 헤드라인 + sans body |

## 진입 애니메이션

```css
/* Fade + Slide Up (가장 다재다능) */
.reveal {
    opacity: 0;
    transform: translateY(30px);
    transition: opacity 0.6s var(--ease-out-expo),
                transform 0.6s var(--ease-out-expo);
}
.visible .reveal {
    opacity: 1;
    transform: translateY(0);
}

/* Scale In */
.reveal-scale {
    opacity: 0;
    transform: scale(0.9);
    transition: opacity 0.6s, transform 0.6s var(--ease-out-expo);
}
.visible .reveal-scale {
    opacity: 1;
    transform: scale(1);
}

/* Slide from Left */
.reveal-left {
    opacity: 0;
    transform: translateX(-50px);
    transition: opacity 0.6s, transform 0.6s var(--ease-out-expo);
}
.visible .reveal-left {
    opacity: 1;
    transform: translateX(0);
}

/* Blur In */
.reveal-blur {
    opacity: 0;
    filter: blur(10px);
    transition: opacity 0.8s, filter 0.8s var(--ease-out-expo);
}
.visible .reveal-blur {
    opacity: 1;
    filter: blur(0);
}
```

## 배경 효과

```css
/* Gradient Mesh — 깊이를 위한 계층 radial gradient */
.gradient-bg {
    background:
        radial-gradient(ellipse at 20% 80%, rgba(120, 0, 255, 0.3) 0%, transparent 50%),
        radial-gradient(ellipse at 80% 20%, rgba(0, 255, 200, 0.2) 0%, transparent 50%),
        var(--bg-primary);
}

/* Noise Texture — grain용 inline SVG */
.noise-bg {
    background-image: url("data:image/svg+xml,..."); /* Inline SVG noise */
}

/* Grid Pattern — 미묘한 구조 라인 */
.grid-bg {
    background-image:
        linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px),
        linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px);
    background-size: 50px 50px;
}
```

## 인터랙티브 효과

```javascript
/* Hover 시 3D Tilt — 카드/패널에 깊이 추가 */
class TiltEffect {
    constructor(element) {
        this.element = element;
        this.element.style.transformStyle = 'preserve-3d';
        this.element.style.perspective = '1000px';

        this.element.addEventListener('mousemove', (e) => {
            const rect = this.element.getBoundingClientRect();
            const x = (e.clientX - rect.left) / rect.width - 0.5;
            const y = (e.clientY - rect.top) / rect.height - 0.5;
            this.element.style.transform = `rotateY(${x * 10}deg) rotateX(${-y * 10}deg)`;
        });

        this.element.addEventListener('mouseleave', () => {
            this.element.style.transform = 'rotateY(0) rotateX(0)';
        });
    }
}
```

## 트러블슈팅

| Problem | Fix |
|---------|-----|
| 폰트 로딩 안 됨 | Fontshare/Google Fonts URL 확인. CSS의 폰트명 일치 확인 |
| 애니메이션 트리거 안 됨 | Intersection Observer 실행 확인. `.visible` 클래스 추가 여부 확인 |
| Scroll snap 동작 안 함 | html에 `scroll-snap-type: y mandatory` 보장. 각 슬라이드에 `scroll-snap-align: start` 필요 |
| 모바일 이슈 | 768px 브레이크포인트에서 무거운 효과 비활성. 터치 이벤트 테스트. 파티클 수 감소 |
| 성능 이슈 | `will-change` 절제 사용. `transform`/`opacity` 애니메이션 선호. 스크롤 핸들러 스로틀 |
