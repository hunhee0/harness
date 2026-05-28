---
name: motion-ui
description: "React/Next.js용 프로덕션 준비 UI 모션 시스템. 애니메이션·전환·모션 패턴 구현 시 사용 (Production-ready UI motion system for React/Next.js. Use when implementing animations, transitions, or motion patterns)."
origin: ECC
---

# Motion System v4.2

React / Next.js용 프로덕션 준비 UI 모션 시스템.

**성능·접근성·사용성**에 집중 — 장식이 아님.

## 사용 시점

모션이 다음과 같을 때 이 모션 시스템 사용:

* 주의 안내 (예: 온보딩·핵심 액션)
* 상태 전달 (로딩·성공·에러·전환)
* 공간 연속성 보존 (레이아웃 변경·네비게이션)

### 적절한 시나리오

* 인터랙티브 컴포넌트 (버튼·모달·메뉴)
* 상태 전환 (loading → loaded·open → closed)
* 네비게이션·레이아웃 연속성 (shared element·crossfade)

### 고려사항

* **접근성**: 항상 reduced motion 지원
* **디바이스 적응**: 저사양 디바이스 대응 조정
* **성능 트레이드오프**: 시각 매끄러움보다 반응성 선호

### 모션 회피 시점

* 순수 장식용
* 사용성·명료성 저하
* 성능 부정적 영향

---

## 동작 원리

### 핵심 원칙

모션은 반드시:

* 주의 안내
* 상태 전달
* 공간 연속성 보존

어느 것도 안 하면 → 제거.

---

### 설치

```bash
npm install motion
```

---

### 버전

* `motion/react` - 현재 Motion for React 프로젝트의 기본 (패키지: `motion`)
* `framer-motion` - 여전히 Framer Motion에 의존하는 프로젝트의 legacy import 경로

**혼용 금지.** 혼용은 충돌하는 내부 스케줄러와 깨진 `AnimatePresence` 컨텍스트 유발 — 한 패키지의 컴포넌트가 다른 패키지의 exit 애니메이션과 조율되지 않음.

프로젝트가 어떤 버전 사용 중인지 확인:

```bash
cat package.json | grep -E '"motion"|"framer-motion"'
```

항상 한 소스에서 일관되게 import:

```ts
// 올바름 (모던)
import { motion, AnimatePresence } from "motion/react"

// 올바름 (legacy)
import { motion, AnimatePresence } from "framer-motion"

// 같은 프로젝트에서 절대 혼용 금지
```

---

### Motion 토큰

```ts
// motionTokens.ts
export const motionTokens = {
  duration: {
    fast: 0.18,
    normal: 0.35,
    slow: 0.6
  },
  // `transition` 객체 내부의 `ease` 값으로 사용:
  // transition={{ duration: motionTokens.duration.normal, ease: motionTokens.easing.smooth }}
  easing: {
    smooth: [0.22, 1, 0.36, 1] as [number, number, number, number],
    sharp:  [0.4,  0, 0.2, 1] as [number, number, number, number]
  },
  distance: {
    sm: 8,
    md: 16,
    lg: 24
  }
}
```

사용 예:

```tsx
import { motionTokens } from "@/lib/motionTokens"

<motion.div
  initial={{ opacity: 0, y: motionTokens.distance.md }}
  animate={{ opacity: 1, y: 0 }}
  transition={{
    duration: motionTokens.duration.normal,
    ease: motionTokens.easing.smooth
  }}
/>
```

---

### 성능 규칙

**안전**

* transform
* opacity

**회피**

* width / height
* top / left

규칙: 반응성 > 매끄러움

---

### 디바이스 적응

휴리스틱은 더 신뢰할 수 있는 신호를 위해 CPU 코어 수**와** 가용 메모리를 결합. `deviceMemory`는 Chrome/Android에서 사용 가능. fallback은 Safari·Firefox 커버.

```ts
const isLowEnd =
  typeof navigator !== "undefined" && (
    // 저메모리 (Chrome/Android만; 그 외 undefined → capable으로 처리)
    (navigator.deviceMemory !== undefined && navigator.deviceMemory <= 2) ||
    // 적은 코어 AND 메모리 API 없음 (약한 하드웨어의 Safari/Firefox 커버)
    (navigator.deviceMemory === undefined && navigator.hardwareConcurrency <= 4)
  )

const duration = isLowEnd ? 0.2 : 0.4
```

---

### 접근성

#### JS (useReducedMotion)

```tsx
import { motion, useReducedMotion } from "motion/react"

export function FadeIn() {
  const reduce = useReducedMotion()

  return (
    <motion.div
      initial={{ opacity: 0, y: reduce ? 0 : 24 }}
      animate={{ opacity: 1, y: 0 }}
    />
  )
}
```

#### CSS

```css
@media (prefers-reduced-motion: reduce) {
  .motion-safe-transition {
    transition: opacity 0.2s;
  }

  .motion-reduce-transform {
    transform: none !important;
  }
}
```

#### Tailwind

```html
<div class="motion-safe:animate-fade motion-reduce:opacity-100"></div>
```

---

### 아키텍처 & 패턴

#### 핵심 패턴

| Scenario | Pattern |
|---|---|
| Hover 피드백 | `whileHover` |
| Tap·press 피드백 | `whileTap` |
| 스크롤 reveal | `whileInView` |
| 스크롤 연동 값 | `useScroll` + `useTransform` |
| 조건부 mount/unmount | `AnimatePresence` |
| 소규모 레이아웃 이동 (단일 요소, < ~300px 변경) | `layout` prop |
| 대규모 레이아웃 이동·전체 페이지 리플로 | `layout` 회피. CSS 전환 또는 페이지 레벨 라우팅 사용 |
| 복잡한 명령형 시퀀스 | `useAnimate` |

> **왜 큰 컨테이너에 `layout` 회피?** Framer의 layout 애니메이션은 `transform`으로 위치 조정. 전체 viewport에 걸치거나 깊은 리플로 트리거하는 요소는 측정 비용이 가시적 jank·CLS 유발. CSS Grid/Flexbox 전환 선호 또는 특정 자식 요소에만 `layoutId` 조정.

#### 레이아웃 & 전환

* Shared element 전환 → `layoutId` (마운트된 인스턴스당 고유해야 함)
* enter/exit 전환 → `AnimatePresence` (아래 `mode` 가이던스 참조)

#### AnimatePresence `mode`

항상 `mode`를 명시적으로 지정 — 기본(`"sync"`)은 enter·exit를 동시 실행. 대부분의 UI 패턴에서 시각적 오버랩 유발.

| `mode` | When to use |
|---|---|
| `"wait"` | exit가 끝난 뒤 enter 시작. **모달·토스트·페이지 전환**에 사용. |
| `"sync"` (기본) | enter와 exit 오버랩. 오버랩 의도(예: crossfade carousel)일 때만 사용. |
| `"popLayout"` | exiting 요소가 즉시 flow에서 pop. 남은 항목이 채움 애니메이션. **리스트·탭·dismissible 카드**에 사용. |

```tsx
// 모달 — 항상 "wait"
<AnimatePresence mode="wait">
  {open && <Modal key="modal" />}
</AnimatePresence>

// dismissible 리스트 항목 — "popLayout"
<AnimatePresence mode="popLayout">
  {items.map(item => <Card key={item.id} />)}
</AnimatePresence>
```

---

### 고급 패턴 (개념)

* Parallax (스크롤 연동 transform)
* 스크롤 storytelling (sticky 섹션)
* 3D tilt (포인터 기반 transform)
* Crossfade (공유 `layoutId`)
* Progressive reveal (clip-path)
* Skeleton 로딩 (반복 opacity)
* Micro-interaction (hover/tap 피드백)
* Spring 시스템 (물리 기반 모션)

---

### 모달 필수요소

* 포커스 트랩
* Escape 닫기
* 스크롤 락
* ARIA role
* 다음 모달 enter 전에 exit 애니메이션 완료 위해 `AnimatePresence mode="wait"` 사용

#### 전체 예제

```tsx
import React, { useEffect, useRef, useState } from "react"
import { motion, AnimatePresence } from "motion/react"

function useFocusTrap(ref: React.RefObject<HTMLDivElement | null>, active: boolean) {
  useEffect(() => {
    if (!active || !ref.current) return
    const el = ref.current
    const focusable = el.querySelectorAll<HTMLElement>(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )
    const first = focusable[0]
    const last  = focusable[focusable.length - 1]

    function handleKey(e: KeyboardEvent) {
      if (e.key !== "Tab") return
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault()
        last?.focus()
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault()
        first?.focus()
      }
    }

    el.addEventListener("keydown", handleKey)
    first?.focus()
    return () => el.removeEventListener("keydown", handleKey)
  }, [active, ref])
}

function useScrollLock(active: boolean) {
  useEffect(() => {
    if (!active) return
    const prev = document.body.style.overflow
    document.body.style.overflow = "hidden"
    return () => { document.body.style.overflow = prev }
  }, [active])
}

function Modal({ open, closeModal }: { open: boolean; closeModal: () => void }) {
  const ref = useRef<HTMLDivElement>(null)

  useFocusTrap(ref, open)
  useScrollLock(open)

  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") closeModal()
    }
    if (open) window.addEventListener("keydown", onKey)
    return () => window.removeEventListener("keydown", onKey)
  }, [open, closeModal])

  return (
    // mode="wait"로 새 모달 enter 전 exit 애니메이션 완료 보장
    <AnimatePresence mode="wait">
      {open && (
        <motion.div
          role="dialog"
          aria-modal="true"
          aria-labelledby="modal-title"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
          className="fixed inset-0 flex items-center justify-center bg-black/40"
        >
          <motion.div
            ref={ref}
            initial={{ scale: 0.95, opacity: 0 }}
            animate={{ scale: 1,    opacity: 1 }}
            exit={{    scale: 0.95, opacity: 0 }}
            transition={{ duration: 0.2, ease: [0.22, 1, 0.36, 1] }}
            className="bg-white p-6 rounded"
          >
            <h2 id="modal-title">Dialog Title</h2>
            <button onClick={closeModal}>Close</button>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

export function Example() {
  const [open, setOpen] = useState(false)

  return (
    <>
      <button onClick={() => setOpen(true)}>Open</button>
      <Modal open={open} closeModal={() => setOpen(false)} />
    </>
  )
}
```

---

### SSR 안전성

* 서버·클라이언트 렌더 간 초기 상태 일치
* 암묵적 애니메이션 origin 회피 (항상 `initial` 명시)
* Next.js App Router에서 motion 컴포넌트를 `"use client"`로 wrap

---

### 디버깅

체크:

* 잘못된 import (`motion/react`와 `framer-motion` 혼용)
* Next.js App Router의 `"use client"` 지시문 누락
* `AnimatePresence` 자식의 `key` prop 누락
* hydration 불일치 (SSR과 클라이언트 간 초기 상태 다름)
* 큰 컨테이너의 `layout` prop 오용 → 리플로 jank
* 상태 기반 애니메이션 트리거 안 됨 (deps 배열 확인)

---

### QA

* CLS 없음
* 키보드 동작
* 모달에 포커스 트랩
* ARIA role 올바름 (`role="dialog"`, `aria-modal="true"`)
* Reduced motion 존중 (`useReducedMotion` + CSS 미디어 쿼리)
* Next.js에서 hydration 경고 없음
* 언마운트 시 애니메이션 깨끗이 정지 (메모리 누수 없음)
* 모든 사용 사이트에서 `AnimatePresence mode` 명시 설정

---

### 안티패턴

* 레이아웃 속성(`width`·`height`·`top`·`left`) 애니메이션
* 목적 없는 무한 애니메이션 (항상 자문: 이것이 어떤 상태를 전달하는가?)
* 리스트 과도한 stagger (`staggerChildren` ≤ 0.1s 유지. 넘으면 느리게 느껴짐)
* reduced motion 선호 무시
* 큰·전체 viewport 컨테이너에 `layout` 사용
* `AnimatePresence`에 `mode` 누락 (기본 `"sync"`가 시각 오버랩 유발)
* 순수 장식용 모션 사용

---

### 철학

모션은 인터랙션 디자인이다.

---

### 최종 규칙

> 모션이 UX를 개선하지 않으면 → 제거.

---

## 예시

### 버튼 상호작용

```tsx
import { motion } from "motion/react"

export function Button() {
  return (
    <motion.button
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.97 }}
      transition={{ duration: 0.15, ease: [0.4, 0, 0.2, 1] }}
    >
      Click me
    </motion.button>
  )
}
```

---

### Reduced Motion 예시

```tsx
import { motion, useReducedMotion } from "motion/react"

export function FadeIn() {
  const reduce = useReducedMotion()

  return (
    <motion.div
      initial={{ opacity: 0, y: reduce ? 0 : 24 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: reduce ? 0.1 : 0.35, ease: [0.22, 1, 0.36, 1] }}
    />
  )
}
```

---

### Stagger 리스트

```tsx
import { motion } from "motion/react"

const container = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.08 } // 느림 회피 위해 ≤ 0.1s 유지
  }
}

const item = {
  hidden:  { opacity: 0, y: 10 },
  visible: { opacity: 1, y: 0,  transition: { duration: 0.3, ease: [0.22, 1, 0.36, 1] } }
}

export function List() {
  return (
    <motion.ul variants={container} initial="hidden" animate="visible">
      {[1, 2, 3].map(i => (
        <motion.li key={i} variants={item}>Item {i}</motion.li>
      ))}
    </motion.ul>
  )
}
```

---

### AnimatePresence 모달

```tsx
import { motion, AnimatePresence } from "motion/react"

export function Modal({ open }: { open: boolean }) {
  return (
    <AnimatePresence mode="wait">
      {open && (
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1    }}
          exit={{    opacity: 0, scale: 0.95 }}
          transition={{ duration: 0.2, ease: [0.22, 1, 0.36, 1] }}
        />
      )}
    </AnimatePresence>
  )
}
```

---

### 스크롤 Parallax

```tsx
import { useScroll, useTransform, motion } from "motion/react"

export function Parallax() {
  const { scrollYProgress } = useScroll()
  const y = useTransform(scrollYProgress, [0, 1], [0, -80])

  return <motion.div style={{ y }} />
}
```

---

### Skeleton 로딩

```tsx
import { motion } from "motion/react"

export function Skeleton() {
  return (
    <motion.div
      className="bg-gray-200 h-6 w-full rounded"
      animate={{ opacity: [0.5, 1, 0.5] }}
      transition={{
        duration: 1.5,       // 편안한 펄스 — 누락되면 빠른 flash
        repeat: Infinity,
        ease: "easeInOut"
      }}
    />
  )
}
```

---

### Shared Layout (Crossfade)

```tsx
import { motion } from "motion/react"

// layoutId는 마운트된 인스턴스당 고유해야 함.
// 여러 인스턴스가 동시에 존재 가능하면 고유 id 추가:
// layoutId={`shared-${item.id}`}
export function Shared() {
  return <motion.div layoutId="shared" />
}
```
