---
name: springboot-security
description: Java Spring Boot 서비스의 authn/authz·검증·CSRF·시크릿·헤더·rate limiting·의존성 보안용 Spring Security 모범 사례 (Spring Security best practices for authn/authz, validation, CSRF, secrets, headers, rate limiting, and dependency security in Java Spring Boot services).
origin: ECC
---

# Spring Boot 보안 리뷰

auth 추가·입력 처리·엔드포인트 생성·시크릿 다룰 때 사용.

## 활성화 시점

- 인증 추가 (JWT·OAuth2·세션 기반)
- 인가 구현 (@PreAuthorize·role 기반 접근)
- 사용자 입력 검증 (Bean Validation·커스텀 검증기)
- CORS·CSRF·보안 헤더 설정
- 시크릿 관리 (Vault·환경 변수)
- rate limiting 또는 brute-force 보호 추가
- CVE 의존성 스캔

## 인증

- 무상태 JWT 또는 revocation 리스트 있는 opaque 토큰 선호
- 세션에 `httpOnly`·`Secure`·`SameSite=Strict` 쿠키 사용
- `OncePerRequestFilter` 또는 resource server로 토큰 검증

```java
@Component
public class JwtAuthFilter extends OncePerRequestFilter {
  private final JwtService jwtService;

  public JwtAuthFilter(JwtService jwtService) {
    this.jwtService = jwtService;
  }

  @Override
  protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
      FilterChain chain) throws ServletException, IOException {
    String header = request.getHeader(HttpHeaders.AUTHORIZATION);
    if (header != null && header.startsWith("Bearer ")) {
      String token = header.substring(7);
      Authentication auth = jwtService.authenticate(token);
      SecurityContextHolder.getContext().setAuthentication(auth);
    }
    chain.doFilter(request, response);
  }
}
```

## 인가

- 메서드 보안 활성화: `@EnableMethodSecurity`
- `@PreAuthorize("hasRole('ADMIN')")` 또는 `@PreAuthorize("@authz.canEdit(#id)")` 사용
- 기본 거부. 필요한 스코프만 노출

```java
@RestController
@RequestMapping("/api/admin")
public class AdminController {

  @PreAuthorize("hasRole('ADMIN')")
  @GetMapping("/users")
  public List<UserDto> listUsers() {
    return userService.findAll();
  }

  @PreAuthorize("@authz.isOwner(#id, authentication)")
  @DeleteMapping("/users/{id}")
  public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
    userService.delete(id);
    return ResponseEntity.noContent().build();
  }
}
```

## 입력 검증

- 컨트롤러에 `@Valid`로 Bean Validation 사용
- DTO에 제약 적용: `@NotBlank`·`@Email`·`@Size`·커스텀 검증기
- 렌더링 전 화이트리스트로 HTML 정화

```java
// BAD: 검증 없음
@PostMapping("/users")
public User createUser(@RequestBody UserDto dto) {
  return userService.create(dto);
}

// GOOD: 검증된 DTO
public record CreateUserDto(
    @NotBlank @Size(max = 100) String name,
    @NotBlank @Email String email,
    @NotNull @Min(0) @Max(150) Integer age
) {}

@PostMapping("/users")
public ResponseEntity<UserDto> createUser(@Valid @RequestBody CreateUserDto dto) {
  return ResponseEntity.status(HttpStatus.CREATED)
      .body(userService.create(dto));
}
```

## SQL 인젝션 방지

- Spring Data 리포지토리 또는 파라미터화 쿼리 사용
- 네이티브 쿼리는 `:param` 바인딩 사용. 절대 문자열 결합 X

```java
// BAD: 네이티브 쿼리의 문자열 결합
@Query(value = "SELECT * FROM users WHERE name = '" + name + "'", nativeQuery = true)

// GOOD: 파라미터화 네이티브 쿼리
@Query(value = "SELECT * FROM users WHERE name = :name", nativeQuery = true)
List<User> findByName(@Param("name") String name);

// GOOD: Spring Data 파생 쿼리 (자동 파라미터화)
List<User> findByEmailAndActiveTrue(String email);
```

## 비밀번호 인코딩

- 항상 BCrypt 또는 Argon2로 비밀번호 해시. 절대 평문 저장 X
- 수동 해싱 아닌 `PasswordEncoder` 빈 사용

```java
@Bean
public PasswordEncoder passwordEncoder() {
  return new BCryptPasswordEncoder(12); // cost factor 12
}

// 서비스에서
public User register(CreateUserDto dto) {
  String hashedPassword = passwordEncoder.encode(dto.password());
  return userRepository.save(new User(dto.email(), hashedPassword));
}
```

## CSRF 보호

- 브라우저 세션 앱은 CSRF 활성 유지. 폼/헤더에 토큰 포함
- Bearer 토큰 순수 API는 CSRF 비활성화·무상태 auth 의존

```java
http
  .csrf(csrf -> csrf.disable())
  .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
```

## 시크릿 관리

- 소스에 시크릿 없음. env·vault에서 로딩
- `application.yml`에 자격증명 없음. 플레이스홀더 사용
- 토큰·DB 자격증명 정기 회전

```yaml
# BAD: application.yml에 하드코딩
spring:
  datasource:
    password: mySecretPassword123

# GOOD: 환경 변수 플레이스홀더
spring:
  datasource:
    password: ${DB_PASSWORD}

# GOOD: Spring Cloud Vault 통합
spring:
  cloud:
    vault:
      uri: https://vault.example.com
      token: ${VAULT_TOKEN}
```

## 보안 헤더

```java
http
  .headers(headers -> headers
    .contentSecurityPolicy(csp -> csp
      .policyDirectives("default-src 'self'"))
    .frameOptions(HeadersConfigurer.FrameOptionsConfig::sameOrigin)
    .xssProtection(Customizer.withDefaults())
    .referrerPolicy(rp -> rp.policy(ReferrerPolicyHeaderWriter.ReferrerPolicy.NO_REFERRER)));
```

## CORS 설정

- CORS를 컨트롤러별이 아닌 보안 필터 레벨에 설정
- 허용 출처 제한. 프로덕션에서 `*` 절대 사용 금지

```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
  CorsConfiguration config = new CorsConfiguration();
  config.setAllowedOrigins(List.of("https://app.example.com"));
  config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE"));
  config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
  config.setAllowCredentials(true);
  config.setMaxAge(3600L);

  UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
  source.registerCorsConfiguration("/api/**", config);
  return source;
}

// SecurityFilterChain에서:
http.cors(cors -> cors.configurationSource(corsConfigurationSource()));
```

## Rate Limiting

- 고비용 엔드포인트에 Bucket4j 또는 게이트웨이 레벨 제한 적용
- 버스트 로깅·알림. 재시도 힌트와 함께 429 반환

```java
// 엔드포인트별 rate limiting에 Bucket4j 사용
@Component
public class RateLimitFilter extends OncePerRequestFilter {
  private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();

  private Bucket createBucket() {
    return Bucket.builder()
        .addLimit(Bandwidth.classic(100, Refill.intervally(100, Duration.ofMinutes(1))))
        .build();
  }

  @Override
  protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
      FilterChain chain) throws ServletException, IOException {
    String clientIp = request.getRemoteAddr();
    Bucket bucket = buckets.computeIfAbsent(clientIp, k -> createBucket());

    if (bucket.tryConsume(1)) {
      chain.doFilter(request, response);
    } else {
      response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
      response.getWriter().write("{\"error\": \"Rate limit exceeded\"}");
    }
  }
}
```

## 의존성 보안

- CI에서 OWASP Dependency Check / Snyk 실행
- Spring Boot·Spring Security를 지원 버전으로 유지
- 알려진 CVE에 빌드 실패

## 로깅·PII

- 시크릿·토큰·비밀번호·전체 PAN 데이터 절대 로깅 금지
- 민감 필드 redact. 구조화 JSON 로깅 사용

## 파일 업로드

- 크기·content type·확장자 검증
- 웹 루트 외부에 저장. 필요 시 스캔

## 릴리스 전 체크리스트

- [ ] auth 토큰 검증·만료 올바름
- [ ] 모든 민감 경로에 인가 가드
- [ ] 모든 입력 검증·정화
- [ ] 문자열 결합 SQL 없음
- [ ] 앱 타입에 맞는 CSRF 자세
- [ ] 시크릿 외부화. 커밋 없음
- [ ] 보안 헤더 설정
- [ ] API에 rate limiting
- [ ] 의존성 스캔·최신
- [ ] 로그에 민감 데이터 없음

**기억하라**: 기본 거부·입력 검증·최소 권한·secure-by-configuration 우선.
