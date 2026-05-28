---
name: dashboard-builder
description: Grafana·SigNoz 등 플랫폼용 실제 운영 질문에 답하는 모니터링 대시보드 구축. vanity 보드가 아닌 동작하는 대시보드로 메트릭을 전환할 때 사용 (Build monitoring dashboards that answer real operator questions for Grafana, SigNoz, and similar platforms. Use when turning metrics into a working dashboard instead of a vanity board).
origin: ECC direct-port adaptation
version: "1.0.0"
---

# Dashboard Builder

사람들이 운영할 수 있는 대시보드 구축 작업에 사용.

목표는 "모든 메트릭 보이기"가 아님. 다음에 답하는 것이 목표:

- 건강한가?
- 병목은 어디인가?
- 무엇이 바뀌었나?
- 누가 어떤 행동을 취해야 하나?

## 사용 시점

- "Kafka 모니터링 대시보드 구축"
- "Elasticsearch용 Grafana 대시보드 생성"
- "이 서비스용 SigNoz 대시보드 만들기"
- "이 메트릭 목록을 실제 운영 대시보드로 전환"

## 가드레일

- 시각 레이아웃에서 시작 금지. 운영자 질문에서 시작
- 존재한다는 이유만으로 모든 사용 가능 메트릭 포함 금지
- 구조 없이 health·throughput·resource 패널 혼합 금지
- 제목·단위·합리적 임계값 없는 패널 출하 금지

## 워크플로

### 1. 운영 질문 정의

다음 기준으로 구성:

- health / availability
- latency / performance
- throughput / volume
- saturation / resources
- 서비스 특정 리스크

### 2. 타겟 플랫폼 스키마 학습

기존 대시보드부터 검사:

- JSON 구조
- 쿼리 언어
- 변수
- 임계값 스타일
- 섹션 레이아웃

### 3. 최소 유용 보드 구축

권장 구조:

1. overview
2. performance
3. resources
4. 서비스 특정 섹션

### 4. Vanity 패널 제거

모든 패널은 실제 질문에 답해야 함. 그렇지 않으면 제거.

## 패널 셋 예시

### Elasticsearch

- cluster health
- shard allocation
- search latency
- indexing rate
- JVM heap / GC

### Kafka

- broker count
- under-replicated partitions
- messages in / out
- consumer lag
- 디스크·네트워크 압박

### API gateway / ingress

- request rate
- p50 / p95 / p99 latency
- error rate
- upstream health
- active connections

## 품질 체크리스트

- [ ] 유효한 대시보드 JSON
- [ ] 명확한 섹션 그룹화
- [ ] 제목·단위 존재
- [ ] 임계값·상태 색이 의미 있음
- [ ] 일반 필터용 변수 존재
- [ ] 기본 시간 범위·refresh가 합리적
- [ ] 운영자 가치 없는 vanity 패널 없음

## 관련 스킬

- `research-ops`
- `backend-patterns`
- `terminal-ops`
