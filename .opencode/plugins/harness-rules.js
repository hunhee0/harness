// .opencode/plugins/harness-rules.js
//
// ① caveman 출력 규칙 + Karpathy 4원칙 + SDD/orchestrator 워크플로 규칙을
//    매 호출 system prompt 에 주입한다 (experimental.chat.system.transform).
// ② 위험 명령(rm -rf · force push · reset --hard · clean -fd · branch -D)만
//    tool.execute.before 에서 차단(throw)한다 — settings.json permissions.ask 의 opencode 등가물.
//
// - 차단은 위 위험 패턴에 한정. 그 외 모든 작업은 규칙 주입으로 유도만 한다 (내장 도구·agent 자유 사용).
// - SDD 규칙은 조건문("기능 개발 요청 시...")이라 일반 작업에는 발동하지 않는다.
// - 이 파일은 setup.ps1/.sh 의 -Opencode (opencode) 옵션일 때만 타겟 .opencode/plugins/ 에 배치된다.
// - 해제(디버깅): 규칙 주입 HARNESS_RULES_OFF=1 / 위험 명령 가드 HARNESS_GUARD_OFF=1
//
// 검증된 동작: output.system 은 문자열 배열(len 1). 마지막 원소에 append (push 는 호출이 깨지므로 금지).
// tool.execute.before 의 throw 차단은 devai 실측으로 작동 확인됨 (2026-06-05 changelog).

const LANG =
  "\n\n[언어·절대규칙] 모든 응답·산출물(spec.md/plan.md/tasks.md 포함)은 한국어로 작성한다. " +
  "영어로 답하지 말 것. 코드·키워드·식별자·표준 영문 기술용어(HTTP·REST·CRUD·OAuth 등)·로그·오류문자열은 원문 유지. " +
  "그 외 산문·제목·설명·질문·결정·근거는 모두 한국어.\n"

const CAVEMAN =
  "\n[출력규칙·최우선] CAVEMAN(full) 항상 활성. 관사·잡담·인사·헤징 제거. " +
  "단편 허용. 기술용어·코드·오류문자열 정확 유지. " +
  "예외(정상문장): 코드·커밋·문서, 보안경고, 파괴적작업 확인, 선택지질문, diff/요약.\n"

const KARPATHY =
  "\n[Karpathy 4원칙] " +
  "1)Think First: 가정 말고 질문, 혼란 숨기지 말고, tradeoff 드러내라. " +
  "2)Simplicity First: 문제 푸는 최소 코드만, 과잉 추상화·옵션·불가능 상황 처리 금지. " +
  "3)Surgical Changes: 필요한 것만, 작동·인접 코드 손대지 말 것, 기존 스타일 유지. " +
  "4)Goal-Driven: 검증 가능한 성공 기준, 테스트 먼저, 검증까지 반복. Tradeoff: 속도보다 신중.\n"

const SDD =
  "\n[SDD·orchestrator 규칙] 기능 개발·수정·보완 요청 시 harness-orchestrator 흐름 사용: " +
  "spec(GATE1)→plan(GATE2)→tasks(GATE3)→implement(GATE4)→review(GATE5)→qa(GATE6)→완료·PR(GATE7), " +
  "모든 Phase 전환에 사용자 승인. " +
  "각 단계는 반드시 planner/implementer/reviewer/qa subagent 를 " +
  "task(subagent_type=\"planner\" 등)로 호출한다. " +
  "이 흐름에서는 내장 Worker 대신 위 custom agent 를 사용. " +
  "구현(src/·app/·lib/ 편집)은 tasks.md 사용자 승인(<!-- APPROVED -->) 후에만.\n"

// 위험 명령 가드 — settings.json permissions.ask 와 동일 목록 유지 (양 타겟 정합).
// 좁은 패턴만 차단해 오차단(false positive)을 피한다. 정당한 사용은 사용자가 직접 실행.
const DANGEROUS = [
  { re: /\brm\s+-[a-zA-Z]*r[a-zA-Z]*f|\brm\s+-[a-zA-Z]*f[a-zA-Z]*r/, label: "rm -rf (재귀 강제 삭제)" },
  { re: /\bgit\s+push\b[^\n]*(\s--force\b|\s-f\b)/, label: "git push --force" },
  { re: /\bgit\s+reset\s+--hard\b/, label: "git reset --hard" },
  { re: /\bgit\s+clean\b[^\n]*\s-[a-zA-Z]*f/, label: "git clean -f*" },
  { re: /\bgit\s+branch\s+(-D\b|--delete\s+--force\b)/, label: "git branch -D (강제 삭제)" },
  { re: /Remove-Item\b[^\n]*-Recurse\b[^\n]*-Force\b/i, label: "Remove-Item -Recurse -Force" },
]

export const HarnessRules = async () => {
  return {
    "experimental.chat.system.transform": async (input, output) => {
      if (process.env.HARNESS_RULES_OFF === "1") return
      const s = output && output.system
      if (Array.isArray(s) && s.length && typeof s[s.length - 1] === "string") {
        s[s.length - 1] += LANG + CAVEMAN + KARPATHY + SDD
      }
    },

    "tool.execute.before": async (input, output) => {
      if (process.env.HARNESS_GUARD_OFF === "1") return
      const cmd = output && output.args && (output.args.command || output.args.cmd)
      if (typeof cmd !== "string" || !cmd) return
      for (const d of DANGEROUS) {
        if (d.re.test(cmd)) {
          throw new Error(
            "[HARNESS GUARD] 위험 명령 차단: " + d.label + "\n" +
            "이 명령은 되돌릴 수 없는 손실을 일으킬 수 있어 자동 실행이 금지된다 (CLAUDE.md §6 Permission Gating).\n" +
            "정말 필요하면 사용자에게 명령 전문을 보여주고 직접 실행을 요청할 것. (가드 해제: HARNESS_GUARD_OFF=1)"
          )
        }
      }
    },
  }
}

export default HarnessRules
