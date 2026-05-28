---
description: 프론트엔드/시각 작업을 위한 generator/evaluator 디자인 루프 실행. 제한된 반복·점수 적용 (Run a generator/evaluator design loop for frontend or visual work with bounded iterations and scoring).
---

$ARGUMENTS에서 다음 파싱:
1. `brief` — 만들 디자인에 대한 사용자 설명
2. `--max-iterations N` — (선택, 기본 10) 최대 design-evaluate 사이클
3. `--pass-threshold N` — (선택, 기본 7.5) 통과 가중 점수 (디자인은 더 높은 기본값)

## GAN 스타일 디자인 하네스

프론트엔드 디자인 품질에 집중하는 2-에이전트 루프(Generator + Evaluator). 플래너 없음 — brief가 곧 spec.

Anthropic이 프론트엔드 디자인 실험에 사용한 동일 모드. CSS perspective와 doorway navigation의 3D Dutch art museum 같은 창의적 돌파구를 만든 방식.

### 셋업
1. `gan-harness/` 디렉터리 생성
2. brief를 직접 `gan-harness/spec.md`로 작성
3. Design Quality·Originality에 추가 가중치를 둔 디자인 중심 `gan-harness/eval-rubric.md` 작성

### 디자인 특화 Eval Rubric
```markdown
### Design Quality (weight: 0.35)
### Originality (weight: 0.30)
### Craft (weight: 0.25)
### Functionality (weight: 0.10)
```

비고: 창의적 돌파구를 밀어붙이기 위해 Originality 가중치가 더 높음(0.30 vs 0.20). 디자인 모드는 시각 품질에 집중하므로 Functionality 가중치는 더 낮음.

### 루프
`/project:gan-build` Phase 2와 동일하지만:
- 플래너 건너뜀
- 디자인 중심 rubric 사용
- Generator 프롬프트는 기능 완성도보다 시각 품질 강조
- Evaluator 프롬프트는 "모든 기능이 동작하는가?"보다 "디자인 어워드 수상할 만한가?" 강조

### gan-build와의 핵심 차이
Generator에 전달: "주된 목표는 시각적 탁월함이다. 기능적이지만 못생긴 앱보다 멋지지만 절반만 완성된 앱이 낫다. 창의적 도약을 밀어붙여라 — 특이한 레이아웃, 커스텀 애니메이션, 독창적인 색채 작업."
