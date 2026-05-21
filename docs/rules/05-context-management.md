# 05-컨텍스트 관리 (하네스 엔지니어링)

**작성일**: 2026-05-21

---

## 🧠 왜 중요한가

LLM은 컨텍스트가 가득 찰수록 성능이 저하됩니다.
또한 약 **150-200개 instruction까지만** 안정적으로 따르며, 그 이상은 누락되거나 무작위로 무시됩니다.
하네스(harness) 측면에서 **컨텍스트 관리는 모델 능력만큼 중요**합니다.

---

## 📐 핵심 원칙

### 1. Progressive Disclosure (점진적 공개)

- **루트 `CLAUDE.md`는 짧게** — 인덱스/요약만, 80-120줄 이내 유지
- **상세는 `docs/rules/`** — 필요할 때만 로드
- **작업별 스펙은 `docs/spec/{feature}/`** — 해당 작업 진행 시에만 참조

### 2. Context Compaction (컨텍스트 압축)

- **무관한 작업 섞기 금지** — 작업 전환 시 `/clear` 사용 (Kitchen Sink Session 방지)
- **실패한 시도 누적 금지** — 2회 교정 실패 시 `/clear` 후 새 프롬프트 (Correction Loop 방지)
- **큰 결과는 서브에이전트에 위임** — 메인 컨텍스트 보호

### 3. Memory Tiering (메모리 계층)

| 계층 | 위치 | 변경 주기 | 용도 |
|---|---|---|---|
| **Tier 1 (Always-on)** | `CLAUDE.md` | 거의 안 바뀜 | 절대 규칙 인덱스 |
| **Tier 2 (Domain Rules)** | `docs/rules/*.md` | 가끔 | 도메인별 상세 규칙 |
| **Tier 3 (Task Context)** | `docs/spec/{feature}/` | 작업마다 | 기능별 spec/plan/tasks |
| **Tier 4 (History)** | `docs/changelog/` | 변경 시 | 변경 이력 |

### 4. Instruction Overload 방지

- **Net-zero 원칙** — 신규 규칙 추가 시 기존 규칙 1개 제거를 검토
- **"이 줄을 지우면 Claude가 실수할까?"** → 아니면 삭제
- **코드 스타일 규칙은 린터에 위임** — LLM에게 시키지 말 것 (토큰 낭비 + 성능 저하)

---

## 🛠️ 실전 체크리스트

**작업 시작 전**:
- [ ] 현재 컨텍스트에 무관한 정보가 누적되어 있다면 `/clear` 고려
- [ ] 필요한 스펙/규칙만 명시적으로 참조 (관련 없는 파일 미리 읽지 않기)

**작업 중**:
- [ ] 검색 결과가 5개 이상이면 서브에이전트로 위임
- [ ] 같은 실수가 2회 반복되면 `/clear` 후 명확한 프롬프트 재작성

**작업 후**:
- [ ] 새로 추가한 규칙이 기존 규칙과 중복/충돌하지 않는지 확인
- [ ] `CLAUDE.md` 또는 `docs/rules/`가 길어졌다면 압축 필요 검토

---

## 📚 참고 (2026년 업계 컨센서스)

- Anthropic Claude Code 베스트 프랙티스 (gather → action → verify 루프)
- HumanLayer — *Writing a good CLAUDE.md*
- Augment Code — *Harness Engineering for AI Coding Agents*
- Red Hat — *Harness engineering: Structured workflows for AI-assisted development*
- Epsilla — *12 Reusable Agentic Harness Design Patterns from Claude Code*
