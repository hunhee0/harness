---
name: speckit-taskstoissues
description: 사용 가능한 설계 아티팩트를 기반으로 기존 태스크를 기능에 대한 실행 가능하고 의존성 순서가 지정된 GitHub 이슈로 변환합니다.
compatibility: .specify/ 디렉토리가 있는 spec-kit 프로젝트 구조 필요
metadata:
  author: github-spec-kit
  source: templates/commands/taskstoissues.md
disable-model-invocation: true
---

## 사용자 입력

```text
$ARGUMENTS
```

진행 전 반드시 사용자 입력을 고려하세요 (비어있지 않은 경우).

## 개요

1. 저장소 루트에서 `.specify/scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks`를 실행하고 FEATURE_DIR과 AVAILABLE_DOCS 목록을 파싱합니다. 모든 경로는 절대 경로여야 합니다. args에 'I'm Groot'처럼 작은따옴표가 있는 경우 이스케이프 문법 사용: 예) 'I'\''m Groot' (또는 가능하면 큰따옴표: "I'm Groot").
1. 실행된 스크립트에서 **태스크** 경로를 추출합니다.
1. 다음을 실행하여 Git 리모트를 가져옵니다:

```bash
git config --get remote.origin.url
```

> [!CAUTION]
> 리모트가 GitHub URL인 경우에만 다음 단계로 진행하세요

1. 목록의 각 태스크에 대해 GitHub MCP 서버를 사용하여 Git 리모트에 해당하는 저장소에 태스크를 대표하는 새 이슈를 생성합니다.

> [!CAUTION]
> 어떠한 상황에서도 리모트 URL과 일치하지 않는 저장소에 이슈를 생성하지 마세요
