# 2026-06-03 — 하네스 감사 보완 (문서-구현 괴리 해소 + 이중 타겟 확정 + 온보딩)

## 배경

10차원 멀티에이전트 감사 + 적대적 검증 결과, "문서가 약속한 것 ≠ 실제 강제되는 것" 괴리와
Claude Code vs KTDS/opencode 이중 타겟 혼선이 핵심으로 식별됨. 검증된 CRITICAL/HIGH/MEDIUM 발견을 보완.

## 핵심 결정

- **1차 타겟 = Claude Code** 확정. `setup -Opencode`는 사내 KTDS opencode 배포용 보조 경로(이때만 Qwen 매핑).

## 변경 요약 (4개 스코프)

### ① 안전·정합
| 파일 | 변경 |
|------|------|
| `.claude/settings.json` | `permissions.ask` 블록 신규 — `rm -rf`·`git push --force/-f`·`reset --hard`·`clean -fd` 실행 전 확인 강제 (문서상 Permission Gating의 실제 구현) |
| `.claude/agents/{planner,implementer,reviewer,qa}.md` | L1 frontmatter에 `tools`+`model: sonnet` 추가 (reviewer는 읽기전용, 나머지 mutate 가능) |
| `.claude/skills/caveman/SKILL.md` | 기본값 모순 해소 — 이 프로젝트 기본=lite 명시, 훅 리마인더가 정적임을 명문화 |

### ② 이중 타겟 확정·문서화
| 파일 | 변경 |
|------|------|
| `.claude/skills/harness-orchestrator/SKILL.md` | "타겟 환경" 섹션 신규. 호출 형식을 `subagent_type=<실제 에이전트명>`(frontmatter tools·model 자동 적용)으로 교정, `general-purpose`는 opencode 폴백으로 명시. 잘못된 "model 미지정—사내 LLM" 주석 정정. Phase 1a에 constitution 플레이스홀더 경고 추가 |
| `docs/rules/03-ai-agent-guidelines.md` | 타겟·호출 노트 추가, 호출 형식 예시 정정 |

### ③ 문서 정합성
| 파일 | 변경 |
|------|------|
| `CLAUDE.md` | 158→135줄. Permission/caveman 표현을 구현과 일치, §4 constitution 권장 추가, §9 트리거 압축, 하단 중복 디렉토리 트리 제거(→README/01 링크) |
| `README.md` | "긴급 핫픽스 모드"에 (예정·미구현) 표기, Permission 표현 정합, QUICKSTART 링크 |
| `.claude/skills/ecc/nextjs-turbopack/agents/openai.yaml` | **삭제** — in-process 파이프라인과 무관한 외부모델 잔재 |

### ④ 신규 사용자 온보딩
| 파일 | 변경 |
|------|------|
| `QUICKSTART.md` | 신규 — setup→[STACK]→constitution→첫 기능 30분 경로 |
| `docs/specs/example-feature/{spec,plan,tasks}.md` | 신규 — `[EXAMPLE]` 표기 참조 산출물 (FastAPI 로그인) |
| `.gitignore` | 신규 — 다언어 기본 (secrets·settings.local·py·node·jvm·IDE·OS) |
| `setup.ps1` / `setup.sh` | `.gitignore`·`QUICKSTART.md` 복사 추가 |
| `docs/INSTALL.md` | 복사 항목 표에 신규 2개 추가 |

## 감사 오탐 (정정·미수정)

- settings.json `hooks>Event>[{hooks:[]}]` 중첩은 **정상 스키마** — 변경 안 함.
- ECC 스킬 21개가 정확(일부 에이전트가 24로 오집계) — 문서 21 유지.
- setup 스크립트 시크릿·동적실행 없음 — 보안 양호, 변경 안 함.

## 미반영 (의도적 보류)

- "긴급 핫픽스 모드" 실제 구현 — (예정) 표기만. 현재는 부분 재실행으로 수동 우회.
- caveman 훅 동적화 — 크로스플랫폼 위험으로 보류, 정적 lite로 정직화.
- LICENSE — 사용자 선택 "생략".
- 인라인 예시의 `general-purpose` 표기 전수 개편 — Surgical Changes 원칙상 보류, 권위 정의 + 지배 규칙으로 대체.

## 검증

- `settings.json` JSON 파싱 OK, `CLAUDE.md` 135줄 확인.
- 에이전트 frontmatter YAML 유효성 확인.
- 실제 기능 개발 1회로 회귀 검증 권장(다음 작업 시).
