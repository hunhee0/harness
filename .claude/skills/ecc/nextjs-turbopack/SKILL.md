---
name: nextjs-turbopack
description: Next.js 16+와 Turbopack — 증분 번들링·FS 캐싱·개발 속도·Turbopack vs webpack 사용 시점 (Next.js 16+ and Turbopack — incremental bundling, FS caching, dev speed, and when to use Turbopack vs webpack).
---

# Next.js와 Turbopack

Next.js 16+는 로컬 개발에서 Turbopack을 기본으로 사용: Rust로 작성된 증분 번들러로 개발 시작·HMR 속도를 크게 향상.

## 사용 시점

- **Turbopack (기본 dev)**: 일상 개발에 사용. 특히 큰 앱에서 cold start와 HMR이 더 빠름.
- **Webpack (legacy dev)**: Turbopack 버그가 있거나 dev에서 webpack 전용 플러그인에 의존할 때만. `--webpack` (또는 Next.js 버전에 따라 `--no-turbopack`)으로 비활성화. 사용 중인 릴리스의 docs 확인.
- **프로덕션**: 프로덕션 빌드 동작(`next build`)은 Next.js 버전에 따라 Turbopack 또는 webpack 사용. 버전에 맞는 공식 Next.js 문서 확인.

사용 시기: Next.js 16+ 앱 개발·디버깅, 느린 dev 시작·HMR 진단, 프로덕션 번들 최적화.

## 동작 원리

- **Turbopack**: Next.js dev용 증분 번들러. 파일 시스템 캐싱으로 재시작이 훨씬 빠름 (예: 대규모 프로젝트에서 5~14배).
- **dev 기본**: Next.js 16부터 비활성화하지 않는 한 `next dev`가 Turbopack으로 실행.
- **파일 시스템 캐싱**: 재시작 시 이전 작업 재사용. 캐시는 보통 `.next` 하위. 기본 사용에 추가 설정 불필요.
- **Bundle Analyzer (Next.js 16.1+)**: 출력 검사·무거운 의존성 검색용 실험 Bundle Analyzer. 설정 또는 실험 플래그로 활성화 (버전별 Next.js docs 참조).

## 예시

### 명령

```bash
next dev
next build
next start
```

### 사용

`next dev`로 Turbopack 기반 로컬 개발 실행. Bundle Analyzer (Next.js docs 참조)로 코드 스플리팅 최적화·큰 의존성 제거. 가능한 경우 App Router·server component 선호.

## 모범 사례

- 안정적인 Turbopack·캐싱 동작을 위해 최신 Next.js 16.x 유지.
- dev가 느리면 Turbopack(기본) 사용 중인지·캐시가 불필요하게 지워지지 않는지 확인.
- 프로덕션 번들 크기 이슈는 사용 버전에 맞는 공식 Next.js 번들 분석 도구 사용.
