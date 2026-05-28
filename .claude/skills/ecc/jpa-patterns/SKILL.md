---
name: jpa-patterns
description: Spring Boot의 엔티티 설계·관계·쿼리 최적화·트랜잭션·auditing·인덱싱·페이지네이션·풀링용 JPA/Hibernate 패턴 (JPA/Hibernate patterns for entity design, relationships, query optimization, transactions, auditing, indexing, pagination, and pooling in Spring Boot).
origin: ECC
---

# JPA/Hibernate 패턴

Spring Boot의 데이터 모델링·리포지토리·성능 튜닝에 사용.

## 활성화 시점

- JPA 엔티티·테이블 매핑 설계
- 관계 정의 (@OneToMany·@ManyToOne·@ManyToMany)
- 쿼리 최적화 (N+1 방지·fetch 전략·projection)
- 트랜잭션·auditing·soft delete 설정
- 페이지네이션·정렬·커스텀 리포지토리 메서드 셋업
- 커넥션 풀링(HikariCP) 또는 2차 캐싱 튜닝

## 엔티티 설계

```java
@Entity
@Table(name = "markets", indexes = {
  @Index(name = "idx_markets_slug", columnList = "slug", unique = true)
})
@EntityListeners(AuditingEntityListener.class)
public class MarketEntity {
  @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false, length = 200)
  private String name;

  @Column(nullable = false, unique = true, length = 120)
  private String slug;

  @Enumerated(EnumType.STRING)
  private MarketStatus status = MarketStatus.ACTIVE;

  @CreatedDate private Instant createdAt;
  @LastModifiedDate private Instant updatedAt;
}
```

auditing 활성화:
```java
@Configuration
@EnableJpaAuditing
class JpaConfig {}
```

## 관계·N+1 방지

```java
@OneToMany(mappedBy = "market", cascade = CascadeType.ALL, orphanRemoval = true)
private List<PositionEntity> positions = new ArrayList<>();
```

- lazy loading 기본. 필요 시 쿼리에서 `JOIN FETCH` 사용
- 컬렉션에 `EAGER` 회피. 읽기 경로에 DTO projection 사용

```java
@Query("select m from MarketEntity m left join fetch m.positions where m.id = :id")
Optional<MarketEntity> findWithPositions(@Param("id") Long id);
```

## 리포지토리 패턴

```java
public interface MarketRepository extends JpaRepository<MarketEntity, Long> {
  Optional<MarketEntity> findBySlug(String slug);

  @Query("select m from MarketEntity m where m.status = :status")
  Page<MarketEntity> findByStatus(@Param("status") MarketStatus status, Pageable pageable);
}
```

- 경량 쿼리에 projection 사용:
```java
public interface MarketSummary {
  Long getId();
  String getName();
  MarketStatus getStatus();
}
Page<MarketSummary> findAllBy(Pageable pageable);
```

## 트랜잭션

- 서비스 메서드에 `@Transactional` 어노테이트
- 읽기 경로 최적화에 `@Transactional(readOnly = true)` 사용
- propagation 신중 선택. 장기 트랜잭션 회피

```java
@Transactional
public Market updateStatus(Long id, MarketStatus status) {
  MarketEntity entity = repo.findById(id)
      .orElseThrow(() -> new EntityNotFoundException("Market"));
  entity.setStatus(status);
  return Market.from(entity);
}
```

## 페이지네이션

```java
PageRequest page = PageRequest.of(pageNumber, pageSize, Sort.by("createdAt").descending());
Page<MarketEntity> markets = repo.findByStatus(MarketStatus.ACTIVE, page);
```

cursor 유사 페이지네이션은 정렬과 함께 JPQL에 `id > :lastId` 포함.

## 인덱싱·성능

- 일반 필터(`status`·`slug`·외래 키)에 인덱스 추가
- 쿼리 패턴과 매칭되는 복합 인덱스 사용 (`status, created_at`)
- `select *` 회피. 필요한 컬럼만 project
- `saveAll`·`hibernate.jdbc.batch_size`로 배치 쓰기

## 커넥션 풀링 (HikariCP)

권장 속성:
```
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.validation-timeout=5000
```

PostgreSQL LOB 처리에:
```
spring.jpa.properties.hibernate.jdbc.lob.non_contextual_creation=true
```

## 캐싱

- 1차 캐시는 EntityManager별. 트랜잭션 간 엔티티 유지 회피
- 읽기 무거운 엔티티는 2차 캐시 신중 검토. eviction 전략 검증

## 마이그레이션

- Flyway·Liquibase 사용. 프로덕션에서 Hibernate auto DDL 의존 금지
- 마이그레이션 idempotent·additive 유지. 계획 없이 컬럼 드롭 회피

## 데이터 접근 테스팅

- 프로덕션 미러링에 `@DataJpaTest` + Testcontainers 선호
- 로그로 SQL 효율성 단언: `logging.level.org.hibernate.SQL=DEBUG`와 파라미터 값에 `logging.level.org.hibernate.orm.jdbc.bind=TRACE` 설정

**기억하라**: 엔티티 lean 유지·쿼리 의도적·트랜잭션 짧게. fetch 전략·projection으로 N+1 방지·읽기/쓰기 경로에 인덱스.
