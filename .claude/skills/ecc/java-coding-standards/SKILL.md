---
name: java-coding-standards
description: "Spring Boot·Quarkus 서비스용 Java 코딩 표준: 명명·불변성·Optional 사용·스트림·예외·제네릭·CDI·리액티브 패턴·프로젝트 레이아웃. 프레임워크별 관례 자동 적용 (Java coding standards for Spring Boot and Quarkus services: naming, immutability, Optional usage, streams, exceptions, generics, CDI, reactive patterns, and project layout. Automatically applies framework-specific conventions)."
origin: ECC
---

# Java 코딩 표준

Spring Boot·Quarkus 서비스의 가독·유지보수 가능 Java(17+) 코드 표준.

## 사용 시점

- Spring Boot·Quarkus 프로젝트의 Java 코드 작성·리뷰
- 명명·불변성·예외 처리 관례 시행
- record·sealed 클래스·패턴 매칭 작업 (Java 17+)
- Optional·스트림·제네릭 사용 리뷰
- 패키지·프로젝트 레이아웃 구조화
- **[QUARKUS]**: CDI 스코프·Panache 엔티티·리액티브 파이프라인 작업

## 동작 원리

### 프레임워크 감지

표준 적용 전 빌드 파일에서 프레임워크 결정:

- 빌드 파일에 `quarkus` 포함 → **[QUARKUS]** 관례 적용
- 빌드 파일에 `spring-boot` 포함 → **[SPRING]** 관례 적용
- 둘 다 미감지 → 공유 관례만 적용

## 핵심 원칙

- 영리함보다 명료성 선호
- 기본 불변. 공유 변경 상태 최소화
- 의미 있는 예외로 fail fast
- 일관된 명명·패키지 구조
- **[QUARKUS]**: 런타임보다 빌드 타임 처리 선호. 가능한 곳에 런타임 리플렉션 회피

## 예시

아래 섹션들이 명명·불변성·DI·리액티브 코드·예외·프로젝트 레이아웃·로깅·설정·테스트의 구체적 Spring Boot·Quarkus·공유 Java 예시 보여줌.

## 명명

```java
// PASS: 클래스/Record: PascalCase
public class MarketService {}
public record Money(BigDecimal amount, Currency currency) {}

// PASS: 메서드/필드: camelCase
private final MarketRepository marketRepository;
public Market findBySlug(String slug) {}

// PASS: 상수: UPPER_SNAKE_CASE
private static final int MAX_PAGE_SIZE = 100;

// PASS: [QUARKUS] JAX-RS 리소스는 *Controller 아닌 *Resource로 명명
public class MarketResource {}

// PASS: [SPRING] REST 컨트롤러는 *Controller로 명명
public class MarketController {}
```

## 불변성

```java
// PASS: record와 final 필드 선호
public record MarketDto(Long id, String name, MarketStatus status) {}

public class Market {
  private final Long id;
  private final String name;
  // getter만, setter 없음
}

// PASS: [QUARKUS] Panache active-record 엔티티는 public 필드 사용 (Quarkus 관례)
@Entity
public class Market extends PanacheEntity {
  public String name;
  public MarketStatus status;
  // Panache가 빌드 타임에 accessor 생성. 여기서는 public 필드가 관용
}

// PASS: [QUARKUS] Panache MongoDB 엔티티
@MongoEntity(collection = "markets")
public class Market extends PanacheMongoEntity {
  public String name;
  public MarketStatus status;
}
```

## Optional 사용

```java
// PASS: find* 메서드에서 Optional 반환
// [SPRING]
Optional<Market> market = marketRepository.findBySlug(slug);

// [QUARKUS] Panache
Optional<Market> market = Market.find("slug", slug).firstResultOptional();

// PASS: get() 대신 map/flatMap
return market
    .map(MarketResponse::from)
    .orElseThrow(() -> new EntityNotFoundException("Market not found"));
```

## 스트림 모범 사례

```java
// PASS: 변환에 스트림 사용. 파이프라인 짧게 유지
List<String> names = markets.stream()
    .map(Market::name)
    .filter(Objects::nonNull)
    .toList();

// FAIL: 복잡한 중첩 스트림 회피. 명료성 위해 루프 선호
```

## DI

```java
// PASS: [SPRING] 생성자 주입 (필드의 @Autowired보다 선호)
@Service
public class MarketService {
  private final MarketRepository marketRepository;

  public MarketService(MarketRepository marketRepository) {
    this.marketRepository = marketRepository;
  }
}

// PASS: [QUARKUS] 생성자 주입
@ApplicationScoped
public class MarketService {
  private final MarketRepository marketRepository;

  @Inject
  public MarketService(MarketRepository marketRepository) {
    this.marketRepository = marketRepository;
  }
}

// PASS: [QUARKUS] 패키지 private 필드 주입 (Quarkus에서 허용 — proxy 이슈 회피)
@ApplicationScoped
public class MarketService {
  @Inject
  MarketRepository marketRepository;
}

// FAIL: [SPRING] @Autowired 있는 필드 주입
@Autowired
private MarketRepository marketRepository; // 생성자 주입 사용

// FAIL: [QUARKUS] interception·lazy init 필요 시 @Singleton
@Singleton // non-proxyable — 대신 @ApplicationScoped 사용
public class MarketService {}
```

## 리액티브 패턴 [QUARKUS]

```java
// PASS: 리액티브 엔드포인트에서 Uni/Multi 반환
@GET
@Path("/{slug}")
public Uni<Market> findBySlug(@PathParam("slug") String slug) {
  return Market.find("slug", slug)
      .<Market>firstResult()
      .onItem().ifNull().failWith(() -> new MarketNotFoundException(slug));
}

// PASS: 비블로킹 파이프라인 구성
public Uni<OrderConfirmation> placeOrder(OrderRequest req) {
  return validateOrder(req)
      .chain(valid -> persistOrder(valid))
      .chain(order -> notifyFulfillment(order));
}

// FAIL: Uni/Multi 파이프라인 내 블로킹 호출
public Uni<Market> find(String slug) {
  Market m = Market.find("slug", slug).firstResult(); // 블로킹 — 이벤트 루프 깨뜨림
  return Uni.createFrom().item(m);
}

// FAIL: 공유 Uni에 두 번 이상 구독
Uni<Market> shared = fetchMarket(slug);
shared.subscribe().with(m -> log(m));
shared.subscribe().with(m -> cache(m)); // 이중 구독 — Uni.memoize() 사용
```

## 예외

- 도메인 에러에 unchecked 예외 사용. 기술 예외는 컨텍스트와 함께 wrap
- 도메인 특정 예외 생성 (예: `MarketNotFoundException`)
- 중앙 rethrow·logging이 아닌 한 광범위 `catch (Exception ex)` 회피

```java
throw new MarketNotFoundException(slug);
```

### 중앙 집중식 예외 처리

```java
// [SPRING]
@RestControllerAdvice
public class GlobalExceptionHandler {
  @ExceptionHandler(MarketNotFoundException.class)
  public ResponseEntity<ErrorResponse> handle(MarketNotFoundException ex) {
    return ResponseEntity.status(404).body(ErrorResponse.from(ex));
  }
}

// [QUARKUS] Option A: ExceptionMapper
@Provider
public class MarketNotFoundMapper implements ExceptionMapper<MarketNotFoundException> {
  @Override
  public Response toResponse(MarketNotFoundException ex) {
    return Response.status(404).entity(ErrorResponse.from(ex)).build();
  }
}

// [QUARKUS] Option B: @ServerExceptionMapper (RESTEasy Reactive)
@ServerExceptionMapper
public RestResponse<ErrorResponse> handle(MarketNotFoundException ex) {
  return RestResponse.status(Status.NOT_FOUND, ErrorResponse.from(ex));
}
```

## 제네릭·타입 안전성

- raw 타입 회피. 제네릭 파라미터 선언
- 재사용 가능 유틸에 bounded 제네릭 선호

```java
public <T extends Identifiable> Map<Long, T> indexById(Collection<T> items) { ... }
```

## 프로젝트 구조

### [SPRING] Maven/Gradle

```
src/main/java/com/example/app/
  config/
  controller/
  service/
  repository/
  domain/
  dto/
  util/
src/main/resources/
  application.yml
src/test/java/... (main 미러링)
```

### [QUARKUS] Maven/Gradle

```
src/main/java/com/example/app/
  config/              # @ConfigMapping·@ConfigProperty 빈·Producer
  resource/            # JAX-RS 리소스 ("controller" 아님)
  service/
  repository/          # PanacheRepository 구현 (active record 안 쓰면)
  domain/              # JPA/Panache 엔티티·MongoDB 엔티티
  dto/
  util/
  mapper/              # MapStruct mapper (사용 시)
src/main/resources/
  application.properties   # Quarkus 관례 (quarkus-config-yaml로 YAML 지원)
  import.sql               # dev/test용 Hibernate auto-import
src/test/java/... (main 미러링)
```

## 포맷팅·스타일

- 2 또는 4 스페이스 일관 사용 (프로젝트 표준)
- 파일당 public top-level 타입 하나
- 메서드 짧고 집중 유지. 헬퍼 추출
- 멤버 순서: 상수·필드·생성자·public 메서드·protected·private

## 회피할 코드 스멜

- 긴 파라미터 리스트 → DTO/builder 사용
- 깊은 중첩 → 조기 반환
- 매직 넘버 → 명명 상수
- static 변경 상태 → DI 선호
- 조용한 catch 블록 → 로깅·동작·rethrow
- **[QUARKUS]**: `@ApplicationScoped` 의도인데 `@Singleton` — 프록시·interception 깨짐
- **[QUARKUS]**: `quarkus-resteasy-reactive`와 `quarkus-resteasy`(classic) 혼용 — 하나 선택
- **[QUARKUS]**: 같은 bounded context에서 Panache active-record + repository 패턴 — 하나 선택

## 로깅

```java
// [SPRING] SLF4J
private static final Logger log = LoggerFactory.getLogger(MarketService.class);
log.info("fetch_market slug={}", slug);
log.error("failed_fetch_market slug={}", slug, ex);

// [QUARKUS] JBoss Logging (기본, 빌드 타임 zero-cost)
private static final Logger log = Logger.getLogger(MarketService.class);
log.infof("fetch_market slug=%s", slug);
log.errorf(ex, "failed_fetch_market slug=%s", slug);

// [QUARKUS] 대안: @Inject로 단순화된 로깅
@Inject
Logger log; // CDI 주입. 선언 클래스 스코프
```

## Null 처리

- 피할 수 없을 때만 `@Nullable` 수락. 그 외 `@NonNull` 사용
- 입력에 Bean Validation (`@NotNull`·`@NotBlank`) 사용
- **[QUARKUS]**: `@BeanParam`·`@RestForm`·요청 body 파라미터에 `@Valid` 적용

## 설정

```java
// [SPRING] @ConfigurationProperties
@ConfigurationProperties(prefix = "market")
public record MarketProperties(int maxPageSize, Duration cacheTtl) {}

// [QUARKUS] @ConfigMapping (타입 안전, 빌드 타임 검증)
@ConfigMapping(prefix = "market")
public interface MarketConfig {
  int maxPageSize();
  Duration cacheTtl();
}

// [QUARKUS] @ConfigProperty로 단순 값
@ConfigProperty(name = "market.max-page-size", defaultValue = "100")
int maxPageSize;
```

## 테스팅 기대

### 공유
- JUnit 5 + fluent 단언에 AssertJ
- 모킹에 Mockito. 가능한 곳에 partial mock 회피
- 결정론적 테스트 선호. 숨겨진 sleep 없음

### [SPRING]
- 컨트롤러 slice에 `@WebMvcTest`. 리포지토리 slice에 `@DataJpaTest`
- `@SpringBootTest`는 전체 통합 테스트에 한정
- Spring 컨텍스트의 빈 교체에 `@MockBean`

### [QUARKUS]
- 단위 테스트는 plain JUnit 5 + Mockito (`@QuarkusTest` 안 함)
- `@QuarkusTest`는 CDI 통합 테스트에 한정
- 통합 테스트의 CDI 빈 교체에 `@InjectMock`
- DB/Kafka/Redis에 Dev Services — Dev Services로 충분하면 수동 Testcontainers 셋업 회피
- 커스텀 외부 서비스 라이프사이클에 `@QuarkusTestResource`

```java
// [SPRING] 컨트롤러 테스트
@WebMvcTest(MarketController.class)
class MarketControllerTest {
  @Autowired MockMvc mockMvc;
  @MockBean MarketService marketService;
}

// [QUARKUS] 통합 테스트
@QuarkusTest
class MarketResourceTest {
  @InjectMock
  MarketService marketService;

  @Test
  void should_return_404_when_market_not_found() {
    given().when().get("/markets/unknown").then().statusCode(404);
  }
}

// [QUARKUS] 단위 테스트 (CDI 없음, @QuarkusTest 없음)
@ExtendWith(MockitoExtension.class)
class MarketServiceTest {
  @Mock MarketRepository marketRepository;
  @InjectMocks MarketService marketService;
}
```

**기억하라**: 코드를 의도적·타입화·관찰 가능하게 유지. 입증된 필요가 없는 한 micro-optimization보다 유지보수성 위해 최적화.
