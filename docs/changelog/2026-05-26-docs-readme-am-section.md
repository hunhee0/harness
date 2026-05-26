# 2026-05-26 docs: README에 AM(유지보수) 과제 적용 섹션 추가

## 변경 내용

### 수정

- **`README.md`**
  - "두 가지 사용 시나리오" 섹션을 사실상 **세 가지**로 확장
  - 신규 하위 섹션: **"C. AM (유지보수) 과제에 적용 시"**
    - 적합(강점) 표 — Surgical Changes / SDD / Verification Loop / reviewer+qa / Human-in-the-loop / changelog / harness-adapt / constitution
    - 주의·조정 표 — 핫픽스 오버헤드 / 80% 커버리지 / 티켓 연동 / SLA / 머지 정책 / touch 금지 모듈
    - 효용 낮은 케이스 2종
    - `am-mode` 스킬 신설 옵션 명시 (현재 미구현)

## 영향 범위

- README 진입점 문서에 AM 적용 가이드 추가
- 신규/ITO에 이어 AM(유지보수)까지 적용 시나리오 명문화
- `am-mode` 스킬은 별도 요청 시 신설 예정 (지금은 미구현)
