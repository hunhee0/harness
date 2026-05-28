# 공통 패턴 (Common Patterns)

## Skeleton 프로젝트

새 기능 구현 시:
1. 검증된 skeleton 프로젝트 검색
2. 병렬 에이전트로 옵션 평가:
   - 보안 평가
   - 확장성 분석
   - 관련성 점수
   - 구현 계획
3. 최적 매치를 기반으로 클론
4. 검증된 구조 내에서 반복

## 디자인 패턴

### Repository 패턴

일관된 인터페이스 뒤에 데이터 접근을 캡슐화:
- 표준 연산 정의: findAll·findById·create·update·delete
- 구체 구현이 저장 디테일(DB·API·파일 등) 처리
- 비즈니스 로직은 저장 메커니즘이 아닌 추상 인터페이스에 의존
- 데이터 소스의 손쉬운 교체와 mock을 통한 테스팅 단순화

### API 응답 형식

모든 API 응답에 일관된 envelope 사용:
- success/status 지표 포함
- 데이터 페이로드 포함 (에러 시 nullable)
- 에러 메시지 필드 포함 (성공 시 nullable)
- 페이지네이션 응답에 메타데이터 포함 (total·page·limit)
