---
name: ui-to-vue
description: 사용자가 UI 스크린샷·디자인 export를 Vue 3 컴포넌트로 일괄 변환해야 할 때 사용. 특히 Vant·Element Plus·Ant Design Vue 사용 시 (Use when the user has UI screenshots or design exports that need batch conversion into Vue 3 components, especially with Vant, Element Plus, or Ant Design Vue).
origin: community
---

# UI To Vue

UI 디자인 스크린샷을 Vue 3 Composition API 컴포넌트 코드로 일괄 변환.

## 사용 시점

- 사용자가 디자인 스크린샷·디자인 export 이미지 디렉터리 제공.
- 타겟 애플리케이션이 Vue 3.
- 사용자가 페이지 컴포넌트·공유 컴포넌트·라우터 와이어링의 첫 패스 원함.
- 사용자가 컴포넌트 라이브러리로 Vant·Element Plus·Ant Design Vue 지정.

## 사용 부적합 시점

- 사용자가 스크린샷 하나만 가지고 맞춤형 컴포넌트 원함.
- 타겟 프로젝트가 Vue 아님.
- 디자인이 상세 상호작용 로직·데이터 흐름·접근성 리뷰 필요.
- 스크린샷에 외부 모델 API로 보낼 수 없는 비공개 고객 데이터 포함.

## 입력

스크린샷을 모듈·페이지 상태별로 그룹화한 입력 디렉터리 사용:

```text
screenshots/
|-- HomePage/
|   |-- List/
|   |   |-- HomePage-List-Default@3x.png
|   |   `-- cut-images/
|   |-- cut-images/
|   `-- HomePage-Default@3x.png
`-- cut-images/
```

지원되는 cut-image 디렉터리 이름: `assets`·`icons`·`sprites`·`cut`·`images`·`cut-images`.

## 변환 모델

- 페이지 그룹화: 리스트·상세·폼·로딩·empty 상태를 나타내는 관련 스크린샷을 하나의 페이지 컴포넌트로 결합.
- UI 라이브러리 매핑: 네이티브 시각 요소를 가능한 경우 Vant·Element Plus·Ant Design Vue 컴포넌트로 매핑.
- Cut-image 우선순위: 페이지 레벨 자산 우선, 다음 모듈 레벨 자산, 다음 글로벌 공유 자산.
- 컴포넌트 추출: 반복되는 UI 영역이 두 번 이상 출현하면 공유 컴포넌트로 추출.

## CLI 사용

`npx`로 변환기 실행해 문서화된 명령이 글로벌 바이너리에 의존하지 않고 동작하게 함:

```bash
export DASHSCOPE_API_KEY=your_key
npx ui-to-vue-converter@1.0.2 --input ./screenshots --ui vant --output ./src
```

데스크톱 UI 라이브러리용:

```bash
npx ui-to-vue-converter@1.0.2 --input ./designs --ui element-plus --output ./src
npx ui-to-vue-converter@1.0.2 --input ./designs --ui antd-vue --output ./src
```

패키지가 글로벌 설치되어 있으면 `ui-to-vue` 바이너리 직접 사용 가능:

```bash
npm install -g ui-to-vue-converter@1.0.2
ui-to-vue --input ./screenshots --ui vant --output ./src
```

## 옵션

| Option | Description | Default |
| --- | --- | --- |
| `--input` | 디자인 이미지 디렉터리 | `./screenshots` |
| `--ui` | UI 라이브러리: `vant`·`element-plus`·`antd-vue` | `vant` |
| `--output` | 출력 디렉터리 | `./src` |
| `--config` | 설정 파일 경로 | `./.ui-to-vue.config.json` |

## API 키 처리

변환기는 DashScope 자격증명을 설정 파일이나 환경에서 읽을 수 있음. 저장소에서는 환경 변수 선호:

```bash
export DASHSCOPE_API_KEY=your_key
```

로컬 설정 파일이 필요하면 버전 관리에서 제외:

```json
{
  "apiKey": "your_dashscope_key",
  "input": "./designs",
  "ui": "vant",
  "output": "./src"
}
```

```gitignore
.ui-to-vue.config.json
```

## 보안·프라이버시

- 디자인 스크린샷을 외부 모델 API로 보낼 수 있는 소스 자료로 취급.
- 허가 없이 비공개 고객 디자인에 이 흐름 실행 금지.
- 반복 가능한 워크플로에서는 `@latest` 대신 변환기 버전 고정.
- 생성된 Vue 코드를 커밋 전 리뷰.
- `.ui-to-vue.config.json`·API 키·생성된 시크릿·고객 스크린샷 커밋 금지.

## 출력 리뷰 체크리스트

- [ ] 페이지 컴포넌트가 `views/` 또는 선택한 출력 디렉터리 하위에 생성.
- [ ] 반복 UI 영역이 재사용 명확할 때만 `components/`로 추출.
- [ ] 라우터 출력이 타겟 프로젝트 라우터 스타일과 호환.
- [ ] 생성된 컴포넌트가 요청된 UI 라이브러리를 일관되게 사용.
- [ ] 생성된 CSS 단위가 디자인 베이스라인과 일치.
- [ ] 코드가 프로젝트의 포매터·린터·타입 체커·빌드 통과.
- [ ] 플레이스홀더 카피·mock 데이터·생성된 자산을 커밋 전 리뷰.

## 트러블슈팅

| Issue | Check |
| --- | --- |
| `401` 또는 인증 에러 | 명령 실행 shell에 `DASHSCOPE_API_KEY` 설정 확인. |
| `command not found: ui-to-vue` | `npx ui-to-vue-converter@1.0.2` 형식 사용 또는 패키지 글로벌 설치. |
| Cut 이미지 무시됨 | 자산 디렉터리 이름 지원 여부와 매칭 페이지·모듈 하위 중첩 확인. |
| 컴포넌트가 요청한 UI 라이브러리 무시 | 명시적 `--ui` 값으로 재실행, 생성된 import 검사. |
| 생성된 레이아웃 차원이 잘못 보임 | 스크린샷 export 너비가 타겟 라이브러리 베이스라인과 일치 확인. |

## 참조

- npm 패키지: `ui-to-vue-converter`
