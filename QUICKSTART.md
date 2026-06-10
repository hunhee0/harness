# QUICKSTART — 처음 30분

이 하네스를 새 프로젝트(또는 기존 코드)에 적용하고 첫 기능을 시작하기까지의 최단 경로.
배경·철학은 `README.md`, 절대 규칙은 `CLAUDE.md`를 참조.

---

## 1. 복사 (setup)

```powershell
# Windows (Claude Code 기본)
.\setup.ps1 -TargetDir "C:\path\to\my-project"
```
```bash
# Mac / Linux
./setup.sh /path/to/my-project
```

- 사내 **opencode** 배포 시: `-Opencode` / `--opencode` 추가 (agent model → KTDS Qwen, `.claude/*` → `.opencode/*`). 상세 `docs/INSTALL.md` §2.
- `--dry-run` / `-DryRun`으로 무엇이 복사될지 먼저 확인 가능.
- 대상에 `CLAUDE.md`·`constitution.md`가 이미 있으면 **덮어쓰지 않고 스킵**(수동 병합).

## 2. 타겟 환경·스택 확정

- **타겟**: 기본은 Claude Code. 사내 opencode면 `-Opencode`로 변환된 결과 사용.
- **스택([STACK])**:
  - 기존 코드가 있으면 → 새 세션에서 **"하네스 적용해줘"** (`harness-adapt` 스킬)로 자동 분석 → `CLAUDE.md`·`01-project-structure.md`·`03-ai-agent-guidelines.md` 갱신.
  - 그린필드(빈 `src/`)면 → `harness-adapt`는 감지할 신호가 없으므로 **수동**으로 `docs/rules/01-project-structure.md`의 잠정 스택을 실제 값으로 교체.

## 3. (권장) 프로젝트 헌법 작성

```
/speckit-constitution
```
- `.specify/memory/constitution.md`는 **빈 플레이스홀더**로 배포됨. 첫 기능 전에 핵심 원칙·금지 패턴·수정 금지 모듈을 채울 것.
- 비워두면 orchestrator가 첫 `/speckit-specify`에서 경고한다(하드 블록 아님).

## 4. 첫 기능 — SDD 파이프라인

자연어로 요청하면 `harness-orchestrator`가 자동 트리거:

```
"사용자 로그인 기능 만들어줘"
```

흐름 (각 단계 사용자 확인 게이트):
```
Phase 0   컨텍스트·상태 확인
Phase 0.5 스택 감지 ([STACK] 전파, constitution 점검)
Phase 1   specify → 🚦 → plan → 🚦 → tasks → 🚦(BLOCKING)
Phase 2   implementer (TDD: RED→GREEN→REFACTOR)
Phase 3   reviewer (1차 스펙 + 2차 팬아웃 + 통합)
Phase 4   qa (통합·엣지·E2E)
Phase 5   changelog + doc-updater + PR
```
- 산출물 예시 구조는 `docs/specs/example-feature/`(spec/plan/tasks) 참조.
- 1-3줄 버그·타이포·설정 변경만 SDD 생략 가능(`CLAUDE.md` §4).

## 5. 안전장치 확인

- 위험 명령(`rm -rf`·force push·`reset --hard`·`clean -fd`·`branch -D`)은 실행 전 확인·차단된다 — Claude Code: `settings.json`의 `permissions.ask` / opencode: plugin `harness-rules.js` 가드 (해제: `HARNESS_GUARD_OFF=1`).
- 모든 코드/문서 변경은 diff·요약을 먼저 보여주고 확인받는다(`CLAUDE.md` §3).

---

## 막히면

| 증상 | 참조 |
|---|---|
| 빌드·테스트 실패, 루프 반복 | `docs/rules/07-error-recovery.md` |
| 컨텍스트 과부하·일관성 저하 | `docs/rules/05-context-management.md` (`/clear`·`/compact`) |
| 스킬·에이전트 사용법 | `docs/rules/03-ai-agent-guidelines.md` |
| 이식·opencode 변환 상세 | `docs/INSTALL.md` |
