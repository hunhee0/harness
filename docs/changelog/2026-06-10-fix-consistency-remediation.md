# 2026-06-10 — 정합성 보완 (6/3 유실분 재적용 + typed subagent 호출 + 양 타겟 Permission Gating)

## 배경

2026-06-10 재감사에서 확인: **6/3 감사 보완(audit-remediation) 중 기존 파일 수정분이 전부 트리·git 이력에 없음**
(`git log -S "permissions" -- .claude/settings.json` 0건). 원인은 당시 작업 브랜치를 push 후 삭제하면서
tracked 수정이 소실된 것 (untracked 신규 파일 4개만 생존). 그 결과 `QUICKSTART.md`가 존재하지 않는
`permissions.ask`를 사실처럼 안내하는 상태였음. 본 변경으로 유실분 재적용 + 잔여 비일관성 일괄 해소.

## 핵심 결정

- **caveman 기본 intensity = `full` 통일** (사용자 결정). SKILL.md(기존 full) 기준으로 CLAUDE.md·훅 라벨을 맞춤.
- **호출 원본 표준 = `Agent(subagent_type="<실제 agent 이름>")`**. `general-purpose`는 변환기 폴백 전용으로 강등.
  변환기는 subagent_type 값과 무관하게 prompt의 `agents/<name>.md`에서 이름을 재추출하므로 **opencode 변환 결과 불변**,
  Claude Code에서는 agent frontmatter `tools`·`model`이 실제 적용됨 (기존엔 死 상태).
- **Permission Gating 양 타겟 실구현**: Claude Code는 `permissions.ask`, opencode는 plugin `tool.execute.before` 차단.
  두 목록 동일 유지 (rm -rf / git push --force·-f / reset --hard / clean -fd / branch -D / Remove-Item -Recurse -Force).
  `branch -D`는 이번 유실 사고의 직접 원인이라 목록에 추가.

## 변경 요약

### ① 안전장치 (6/3 유실 재적용 + 확장)

| 파일 | 변경 |
|------|------|
| `.claude/settings.json` | `permissions.ask` 신규 (Bash + PowerShell 양 셸, 위 6패턴) + 훅 라벨 `[CAVEMAN LITE]`→`[CAVEMAN FULL]` |
| `.opencode/plugins/harness-rules.js` | `tool.execute.before` 위험 명령 가드 신규 (같은 6패턴, throw 차단, 해제 `HARNESS_GUARD_OFF=1`). 기존 규칙 주입은 유지하되 `HARNESS_RULES_OFF`는 주입만 해제하도록 분리. CAVEMAN 주입문에 `(full)` 라벨 |

> 6/5 changelog가 "조건부 차단 plugin 부작용 우려로 미적용"이라 보류했던 항목 — 좁은 고정 패턴 6개 + env 해제로 한정하여 적용.
> `<!-- APPROVED -->` 마커 검증은 여전히 비차단(주입 규칙으로만 유도) — 1-3줄 핫픽스 SDD 예외와 충돌하는 하드 블록은 의도적 미적용.

### ② typed subagent 호출 전환 (L2 frontmatter 활성화)

| 파일 | 변경 |
|------|------|
| `harness-orchestrator/SKILL.md` | 전 호출 블록 `subagent_type="general-purpose"` → 실제 이름 (planner ×3·implementer·reviewer·python/security/code-reviewer·qa·doc-updater·architect/code-architect 예시). 호출 형식 설명·model 주석 양 타겟 표기로 정정. Phase 0.5에 constitution 플레이스홀더 점검 추가 (6/3 유실분) |
| `docs/rules/03` | §6 호출 형식 동일 교정 + general-purpose 금지 명시. multi-* 커맨드에 외부 wrapper 의존 명시 |
| `.claude/agents/{planner,implementer,reviewer,qa}.md` | frontmatter `model: sonnet` + `tools` 추가 (reviewer·qa는 읽기+Bash, planner·implementer는 mutate 가능) — 6/3 유실분 재적용. 본문 예시 블록도 실제 이름으로 교정. 호출 경로 주석의 `task()` 단독 표기 → 환경 중립 표기 (원본에 변환 후 문법 역류 제거) |
| `docs/rules/02` | `task()` 병렬 위임 표기 → 환경 중립 표기 |

### ③ ECC 규칙 스코프 정합

| 파일 | 변경 |
|------|------|
| `.claude/rules/ecc/web/{patterns,testing}.md` | `paths:` frontmatter 추가 (tsx·jsx·vue·css·scss·html) — java/python/typescript는 이미 스코프됨, web만 누락되어 모든 세션에 무조건 주입되던 것 수정. common 2개는 범용이라 의도적 always-on 유지 |
| `.claude/rules/ecc/typescript/testing.md` | 존재하지 않는 `e2e-runner` 에이전트 참조 → L1 `qa`로 교정 (ECC 임포트 잔재) |

### ④ 문서·이식 정합

| 파일 | 변경 |
|------|------|
| `CLAUDE.md` §8 | caveman 기본 lite→**full**, 훅 라벨 `[CAVEMAN FULL]` (3중 모순 해소 — SKILL.md는 원래 full이라 무변경) |
| `README.md` | "긴급 핫픽스 모드"에 **(예정·미구현)** 표기 (6/3 유실분 재적용) |
| `QUICKSTART.md` §5 | 안전장치 안내를 실제 구현과 일치 + 환경별(Claude Code/opencode) 표기 — opencode 변환 후에도 참이 되도록 경로 prefix 제거 |
| `setup.ps1` / `setup.sh` | `.gitignore`·`QUICKSTART.md` 복사 추가 (기존 파일 존재 시 스킵) — 6/3 유실분 재적용 |
| `docs/INSTALL.md` | 복사 항목 표에 신규 2행 + settings.json 설명을 permissions.ask 포함으로 정정 + ECC 규칙 paths 스코프 명시 + 변환 예시의 general-purpose 표기 제거 |

## 검증

- `settings.json` JSON 파싱 OK, plugin `node --check` OK, `bash -n setup.sh` OK, setup.ps1 파서 검증 OK
- setup 실제 실행 (임시 디렉터리, 일반 + opencode 양 모드):
  - opencode: `Agent(...)` → `task(subagent_type="planner" 등 실제 이름, load_skills 주입)` 변환 확인, `AskUserQuestion` 잔재 0,
    L1 frontmatter `model: ABCLab/[KTDS] Qwen3.6-27B-FP8` 매핑·`tools` 제거 확인, plugin 배치, settings.json 미생성
  - 일반: settings.json(permissions 포함) 생성, `.opencode` 미생성, `.gitignore`/`QUICKSTART.md` 복사
- 원본 `.claude/` 내 `subagent_type="general-purpose"` 잔재 0 (금지 안내 문구 제외)

## 미반영 (의도적 보류)

- "긴급 핫픽스 모드" 실구현 — (예정) 표기 유지.
- `python-review` 커맨드·`tdd-guide`/`loop-operator` 연결 재검토 — 동작에는 문제없어 Surgical Changes 원칙상 보류.
- speckit skill의 devai end-to-end 실행 검증 — 사내 환경 필요 (6/5 남은 과제 유지).
