# 04-변경 이력 관리 가이드

**작성일**: 2026-05-14  
**최종 수정**: 2026-05-14

---

## 📋 변경 이력 관리 규칙

모든 변경사항은 `docs/changelog/`에 기록됩니다.

### 파일명 규칙

```
docs/changelog/YYYY-MM-DD-{type}-{short-id}.md
```

**type 종류:**
- `feat` — 신규 기능
- `fix` — 버그 수정
- `refactor` — 리팩토링
- `docs` — 문서 변경
- `chore` — 설정/인프라 변경
- `breaking` —破壊적 변경

**예시:**
- `2026-05-14-feat-initial-harness-setup.md`
- `2026-05-15-feat-user-auth.md`
- `2026-05-16-fix-api-timeout.md`

### 파일 내용 템플릿

```markdown
# YYYY-MM-DD {type}: {제목}

## 변경 내용
- 변경 내용 1
- 변경 내용 2

## 영향 범위
- 영향받은 파일/모듈

## 관련 스펙
- `docs/spec/{feature}/spec.md` (관련된 경우)
```

### 기록 시점

1. **기능 추가/수정** — 구현 완료 시
2. **문서 변경** — docs/rules 변경 시
3. **아키텍처 변경** — 계층/의존성 변경 시
4. **설정 변경** — 환경/도구 변경 시
