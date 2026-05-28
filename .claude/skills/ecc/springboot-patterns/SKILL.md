---
name: springboot-patterns
description: Spring Boot 아키텍처 패턴·REST API 디자인·레이어드 서비스·데이터 접근·캐싱·async 처리·로깅. Java Spring Boot 백엔드 작업에 사용 (Spring Boot architecture patterns, REST API design, layered services, data access, caching, async processing, and logging. Use for Java Spring Boot backend work).
origin: ECC
---

# Spring Boot 개발 패턴

확장 가능·프로덕션급 서비스용 Spring Boot 아키텍처·API 패턴.

## 활성화 시점

- Spring MVC·WebFlux로 REST API 구축
- 컨트롤러 → 서비스 → 리포지토리 레이어 구조화
- Spring Data JPA·캐싱·async 처리 설정
- 검증·예외 처리·페이지네이션 추가
- dev/staging/production 환경 프로필 셋업
- Spring Events·Kafka로 이벤트 기반 패턴 구현

## REST API 구조

```java
@RestController
@RequestMapping("/api/markets")
@Validated
class MarketController {
  private final MarketService marketService;

  MarketController(MarketService marketService) {
    this.marketService = marketService;
  }

  @GetMapping
  ResponseEntity<Page<MarketResponse>> list(
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "20") int size) {
    Page<Market> markets = marketService.list(PageRequest.of(page, size));
    return ResponseEntity.ok(markets.map(MarketResponse::from));
  }

  @PostMapping
  ResponseEntity<MarketResponse> create(@Valid @RequestBody CreateMarketRequest request) {
    Market market = marketService.create(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(MarketResponse.from(market));
  }
}
```

## Repository 패턴 (Spring Data JPA)

```java
public interface MarketRepository extends JpaRepository<MarketEntity, Long> {
  @Query("select m from MarketEntity m where m.status = :status order by m.volume desc")
  List<MarketEntity> findActive(@Param("status") MarketStatus status, Pageable pageable);
}
```

## 트랜잭션 있는 서비스 레이어

```java
@Service
public class MarketService {
  private final MarketRepository repo;

  public MarketService(MarketRepository repo) {
    this.repo = repo;
  }

  @Transactional
  public Market create(CreateMarketRequest request) {
    MarketEntity entity = MarketEntity.from(request);
    MarketEntity saved = repo.save(entity);
    return Market.from(saved);
  }
}
```

## DTO·검증

```java
public record CreateMarketRequest(
    @NotBlank @Size(max = 200) String name,
    @NotBlank @Size(max = 2000) String description,
    @NotNull @FutureOrPresent Instant endDate,
    @NotEmpty List<@NotBlank String> categories) {}

public record MarketResponse(Long id, String name, MarketStatus status) {
  static MarketResponse from(Market market) {
    return new MarketResponse(market.id(), market.name(), market.status());
  }
}
```

## 예외 처리

```java
@ControllerAdvice
class GlobalExceptionHandler {
  @ExceptionHandler(MethodArgumentNotValidException.class)
  ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex) {
    String message = ex.getBindingResult().getFieldErrors().stream()
        .map(e -> e.getField() + ": " + e.getDefaultMessage())
        .collect(Collectors.joining(", "));
    return ResponseEntity.badRequest().body(ApiError.validation(message));
  }

  @ExceptionHandler(AccessDeniedException.class)
  ResponseEntity<ApiError> handleAccessDenied() {
    return ResponseEntity.status(HttpStatus.FORBIDDEN).body(ApiError.of("Forbidden"));
  }

  @ExceptionHandler(Exception.class)
  ResponseEntity<ApiError> handleGeneric(Exception ex) {
    // 예상치 못한 에러를 stack trace와 함께 로깅
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
        .body(ApiError.of("Internal server error"));
  }
}
```

## 캐싱

설정 클래스에 `@EnableCaching` 필요.

```java
@Service
public class MarketCacheService {
  private final MarketRepository repo;

  public MarketCacheService(MarketRepository repo) {
    this.repo = repo;
  }

  @Cacheable(value = "market", key = "#id")
  public Market getById(Long id) {
    return repo.findById(id)
        .map(Market::from)
        .orElseThrow(() -> new EntityNotFoundException("Market not found"));
  }

  @CacheEvict(value = "market", key = "#id")
  public void evict(Long id) {}
}
```

## Async 처리

설정 클래스에 `@EnableAsync` 필요.

```java
@Service
public class NotificationService {
  @Async
  public CompletableFuture<Void> sendAsync(Notification notification) {
    // 이메일/SMS 전송
    return CompletableFuture.completedFuture(null);
  }
}
```

## 로깅 (SLF4J)

```java
@Service
public class ReportService {
  private static final Logger log = LoggerFactory.getLogger(ReportService.class);

  public Report generate(Long marketId) {
    log.info("generate_report marketId={}", marketId);
    try {
      // 로직
    } catch (Exception ex) {
      log.error("generate_report_failed marketId={}", marketId, ex);
      throw ex;
    }
    return new Report();
  }
}
```

## 미들웨어 / 필터

```java
@Component
public class RequestLoggingFilter extends OncePerRequestFilter {
  private static final Logger log = LoggerFactory.getLogger(RequestLoggingFilter.class);

  @Override
  protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
      FilterChain filterChain) throws ServletException, IOException {
    long start = System.currentTimeMillis();
    try {
      filterChain.doFilter(request, response);
    } finally {
      long duration = System.currentTimeMillis() - start;
      log.info("req method={} uri={} status={} durationMs={}",
          request.getMethod(), request.getRequestURI(), response.getStatus(), duration);
    }
  }
}
```

## 페이지네이션·정렬

```java
PageRequest page = PageRequest.of(pageNumber, pageSize, Sort.by("createdAt").descending());
Page<Market> results = marketService.list(page);
```

## 에러 복원력 있는 외부 호출

```java
public <T> T withRetry(Supplier<T> supplier, int maxRetries) {
  int attempts = 0;
  while (true) {
    try {
      return supplier.get();
    } catch (Exception ex) {
      attempts++;
      if (attempts >= maxRetries) {
        throw ex;
      }
      try {
        Thread.sleep((long) Math.pow(2, attempts) * 100L);
      } catch (InterruptedException ie) {
        Thread.currentThread().interrupt();
        throw ex;
      }
    }
  }
}
```

## Rate Limiting (Filter + Bucket4j)

**보안 노트**: `X-Forwarded-For` 헤더는 클라이언트가 스푸핑할 수 있어 기본 신뢰 X.
다음 조건에서만 forwarded 헤더 사용:
1. 앱이 신뢰 reverse proxy(nginx·AWS ALB 등) 뒤에 있음
2. `ForwardedHeaderFilter` 빈 등록 완료
3. application 속성에 `server.forward-headers-strategy=NATIVE` 또는 `FRAMEWORK` 설정
4. 프록시가 `X-Forwarded-For` 헤더를 덮어쓰도록(추가 아닌) 설정

`ForwardedHeaderFilter`가 적절히 설정되면 `request.getRemoteAddr()`가 forwarded 헤더에서 올바른 클라이언트 IP 자동 반환.
이 설정 없이는 `request.getRemoteAddr()` 직접 사용 — 즉시 연결 IP 반환. 유일하게 신뢰 가능 값.

```java
@Component
public class RateLimitFilter extends OncePerRequestFilter {
  private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();

  /*
   * 보안: 이 필터는 rate limiting용 클라이언트 식별에 request.getRemoteAddr() 사용.
   *
   * 앱이 reverse proxy(nginx·AWS ALB 등) 뒤에 있으면 정확한 클라이언트 IP 감지를 위해
   * Spring이 forwarded 헤더를 적절히 처리하도록 설정 필수:
   *
   * 1. application.properties/yaml에 server.forward-headers-strategy=NATIVE
   *    (클라우드 플랫폼용) 또는 FRAMEWORK 설정
   * 2. FRAMEWORK 전략 사용 시 ForwardedHeaderFilter 등록:
   *
   *    @Bean
   *    ForwardedHeaderFilter forwardedHeaderFilter() {
   *        return new ForwardedHeaderFilter();
   *    }
   *
   * 3. 프록시가 스푸핑 방지 위해 X-Forwarded-For 헤더 덮어쓰도록(추가 아닌) 보장
   * 4. 컨테이너에 server.tomcat.remoteip.trusted-proxies 또는 동등물 설정
   *
   * 이 설정 없이 request.getRemoteAddr()는 클라이언트 IP가 아닌 프록시 IP 반환.
   * 신뢰 프록시 처리 없이 X-Forwarded-For 직접 읽지 말 것 — 사소하게 스푸핑 가능.
   */
  @Override
  protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
      FilterChain filterChain) throws ServletException, IOException {
    // ForwardedHeaderFilter 설정 시 올바른 클라이언트 IP 반환, 그 외 직접 연결 IP.
    // 적절한 프록시 설정 없이 X-Forwarded-For 헤더 직접 신뢰 금지.
    String clientIp = request.getRemoteAddr();

    Bucket bucket = buckets.computeIfAbsent(clientIp,
        k -> Bucket.builder()
            .addLimit(Bandwidth.classic(100, Refill.greedy(100, Duration.ofMinutes(1))))
            .build());

    if (bucket.tryConsume(1)) {
      filterChain.doFilter(request, response);
    } else {
      response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
    }
  }
}
```

## 백그라운드 잡

Spring의 `@Scheduled` 사용 또는 큐(Kafka·SQS·RabbitMQ)와 통합. 핸들러 idempotent·observable 유지.

## 관찰 가능성

- Logback 인코더로 구조화 로깅 (JSON)
- 메트릭: Micrometer + Prometheus/OTel
- 트레이싱: OpenTelemetry·Brave 백엔드로 Micrometer Tracing

## 프로덕션 기본값

- 필드 주입 회피, 생성자 주입 선호
- RFC 7807 에러용 `spring.mvc.problemdetails.enabled=true` 활성화 (Spring Boot 3+)
- 워크로드에 HikariCP 풀 크기 설정, 타임아웃 설정
- 쿼리에 `@Transactional(readOnly = true)` 사용
- `@NonNull`·`Optional`로 null 안전성 시행

**기억하라**: 컨트롤러 얇게·서비스 집중·리포지토리 단순·에러 중앙 처리. 유지보수성·테스트 가능성 위해 최적화.
