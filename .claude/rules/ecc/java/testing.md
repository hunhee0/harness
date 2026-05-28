---
paths:
  - "**/*.java"
---
# Java 테스팅 (Java Testing)

> 이 파일은 [common/testing.md](../common/testing.md)를 Java 특화 내용으로 확장한다.

## 테스트 프레임워크

- **JUnit 5** (`@Test`·`@ParameterizedTest`·`@Nested`·`@DisplayName`)
- **AssertJ** fluent 단언 (`assertThat(result).isEqualTo(expected)`)
- **Mockito** 의존성 모킹
- **Testcontainers** DB·서비스가 필요한 통합 테스트

## 테스트 구조

```
src/test/java/com/example/app/
  service/           # 서비스 레이어 단위 테스트
  controller/        # 웹 레이어 / API 테스트
  repository/        # 데이터 접근 테스트
  integration/       # 레이어 간 통합 테스트
```

`src/test/java`에 `src/main/java` 패키지 구조 미러링.

## 단위 테스트 패턴

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    private OrderService orderService;

    @BeforeEach
    void setUp() {
        orderService = new OrderService(orderRepository);
    }

    @Test
    @DisplayName("findById returns order when exists")
    void findById_existingOrder_returnsOrder() {
        var order = new Order(1L, "Alice", BigDecimal.TEN);
        when(orderRepository.findById(1L)).thenReturn(Optional.of(order));

        var result = orderService.findById(1L);

        assertThat(result.customerName()).isEqualTo("Alice");
        verify(orderRepository).findById(1L);
    }

    @Test
    @DisplayName("findById throws when order not found")
    void findById_missingOrder_throws() {
        when(orderRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> orderService.findById(99L))
            .isInstanceOf(OrderNotFoundException.class)
            .hasMessageContaining("99");
    }
}
```

## 파라미터화 테스트

```java
@ParameterizedTest
@CsvSource({
    "100.00, 10, 90.00",
    "50.00, 0, 50.00",
    "200.00, 25, 150.00"
})
@DisplayName("discount applied correctly")
void applyDiscount(BigDecimal price, int pct, BigDecimal expected) {
    assertThat(PricingUtils.discount(price, pct)).isEqualByComparingTo(expected);
}
```

## 통합 테스트

실제 DB 통합에는 Testcontainers 사용:

```java
@Testcontainers
class OrderRepositoryIT {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

    private OrderRepository repository;

    @BeforeEach
    void setUp() {
        var dataSource = new PGSimpleDataSource();
        dataSource.setUrl(postgres.getJdbcUrl());
        dataSource.setUser(postgres.getUsername());
        dataSource.setPassword(postgres.getPassword());
        repository = new JdbcOrderRepository(dataSource);
    }

    @Test
    void save_and_findById() {
        var saved = repository.save(new Order(null, "Bob", BigDecimal.ONE));
        var found = repository.findById(saved.getId());
        assertThat(found).isPresent();
    }
}
```

Spring Boot 통합 테스트는 skill: `springboot-tdd` 참조.
Quarkus 통합 테스트는 skill: `quarkus-tdd` 참조.

## 테스트 명명

`@DisplayName`으로 서술적 이름 사용:
- 메서드 이름: `methodName_scenario_expectedBehavior()`
- 리포트용: `@DisplayName("사람이 읽기 좋은 설명")`

## 커버리지

- 80%+ 라인 커버리지 목표
- 커버리지 리포팅에 JaCoCo 사용
- service·도메인 로직에 집중 — 사소한 getter·설정 클래스는 건너뜀

## 참조

MockMvc·Testcontainers Spring Boot TDD 패턴은 skill: `springboot-tdd` 참조.
REST Assured·Dev Services Quarkus TDD 패턴은 skill: `quarkus-tdd` 참조.
테스팅 기대는 skill: `java-coding-standards` 참조.
