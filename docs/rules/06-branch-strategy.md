# 06-브랜치 전략

**작성일**: 2026-05-26

---

## 브랜치 생성

Speckit이 `/speckit-specify` 실행 시 자동 생성합니다.

### 자동 생성 형식

```
{순번}-{short-name}                   # sequential 모드 (기본)
{YYYYMMDD-HHMMSS}-{short-name}        # timestamp 모드
```

예시: `001-user-auth`, `20260526-143021-payment-api`

### 수동 생성 시 규칙

Speckit 자동 생성이 불가한 경우에만:

```
feat/{short-name}     # 신규 기능
fix/{short-name}      # 버그 수정
chore/{short-name}    # 설정/인프라
docs/{short-name}     # 문서만
```

---

## PR 규칙

### 제목 형식

```
{type}: {기능 한 줄 요약}
```

예시: `feat: 사용자 인증 JWT 토큰 방식 구현`

### PR 본문 필수 포함

```markdown
## 변경 내용
- 구현한 것 요약

## 스펙 참조
- docs/specs/{feature}/spec.md

## 검증
- [ ] 단위 테스트 통과
- [ ] 통합 테스트 통과
- [ ] Verification Loop 완료 (Gather → Action → Verify)
- [ ] reviewer 승인
- [ ] qa 통과
```

---

## 머지 전략

- **기본**: Squash merge (커밋 이력 정리)
- **예외**: 이력 보존이 필요한 경우 Merge commit 허용

## 브랜치 정리

머지 완료 후 원격 브랜치 즉시 삭제.

---

## main/master 보호

- 직접 push 금지 — 반드시 PR 경유
- CI 통과 필수 (구성된 경우)
- force push 금지 (사용자 명시 동의 없이)
