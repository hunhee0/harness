---
name: springboot-tdd
description: JUnit 5·Mockito·MockMvc·Testcontainers·JaCoCo를 사용하는 Spring Boot TDD. 기능 추가·버그 수정·리팩토링 시 사용 (Test-driven development for Spring Boot using JUnit 5, Mockito, MockMvc, Testcontainers, and JaCoCo. Use when adding features, fixing bugs, or refactoring).
origin: ECC
---

# Spring Boot TDD 워크플로

80%+ 커버리지(unit + integration) 있는 Spring Boot 서비스용 TDD 가이던스.

## 사용 시점

- 새 기능·엔드포인트
- 버그 수정·리팩토링
- 데이터 접근 로직·보안 규칙 추가

## 워크플로

1) 테스트 먼저 작성 (실패해야 함)
2) 통과시킬 최소 코드 구현
3) 테스트 green 유지하며 리팩토링
4) 커버리지 시행 (JaCoCo)

## 단위 테스트 (JUnit 5 + Mockito)

```java
@ExtendWith(MockitoExtension.class)
class MarketServiceTest {
  @Mock MarketRepository repo;
  @InjectMocks MarketService service;

  @Test
  void createsMarket() {
    CreateMarketRequest req = new CreateMarketRequest("name", "desc", Instant.now(), List.of("cat"));
    when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Market result = service.create(req);

    assertThat(result.name()).isEqualTo("name");
    verify(repo).save(any());
  }
}
```

패턴:
- Arrange-Act-Assert
- partial mock 회피. 명시적 stubbing 선호
- 변형에 `@ParameterizedTest` 사용

## 웹 레이어 테스트 (MockMvc)

```java
@WebMvcTest(MarketController.class)
class MarketControllerTest {
  @Autowired MockMvc mockMvc;
  @MockBean MarketService marketService;

  @Test
  void returnsMarkets() throws Exception {
    when(marketService.list(any())).thenReturn(Page.empty());

    mockMvc.perform(get("/api/markets"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.content").isArray());
  }
}
```

## 통합 테스트 (SpringBootTest)

```java
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class MarketIntegrationTest {
  @Autowired MockMvc mockMvc;

  @Test
  void createsMarket() throws Exception {
    mockMvc.perform(post("/api/markets")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {"name":"Test","description":"Desc","endDate":"2030-01-01T00:00:00Z","categories":["general"]}
        """))
      .andExpect(status().isCreated());
  }
}
```

## 영속화 테스트 (DataJpaTest)

```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import(TestContainersConfig.class)
class MarketRepositoryTest {
  @Autowired MarketRepository repo;

  @Test
  void savesAndFinds() {
    MarketEntity entity = new MarketEntity();
    entity.setName("Test");
    repo.save(entity);

    Optional<MarketEntity> found = repo.findByName("Test");
    assertThat(found).isPresent();
  }
}
```

## Testcontainers

- 프로덕션 미러링에 Postgres/Redis 재사용 컨테이너 사용
- Spring 컨텍스트에 JDBC URL 주입에 `@DynamicPropertySource` 와이어링

## 커버리지 (JaCoCo)

Maven snippet:
```xml
<plugin>
  <groupId>org.jacoco</groupId>
  <artifactId>jacoco-maven-plugin</artifactId>
  <version>0.8.14</version>
  <executions>
    <execution>
      <goals><goal>prepare-agent</goal></goals>
    </execution>
    <execution>
      <id>report</id>
      <phase>verify</phase>
      <goals><goal>report</goal></goals>
    </execution>
  </executions>
</plugin>
```

## 단언

- 가독성 위해 AssertJ (`assertThat`) 선호
- JSON 응답에 `jsonPath` 사용
- 예외에 `assertThatThrownBy(...)`

## 테스트 데이터 빌더

```java
class MarketBuilder {
  private String name = "Test";
  MarketBuilder withName(String name) { this.name = name; return this; }
  Market build() { return new Market(null, name, MarketStatus.ACTIVE); }
}
```

## CI 명령

- Maven: `mvn -T 4 test` 또는 `mvn verify`
- Gradle: `./gradlew test jacocoTestReport`

**기억하라**: 테스트 빠르고·격리되고·결정론적 유지. 구현 디테일 아닌 동작 테스트.
