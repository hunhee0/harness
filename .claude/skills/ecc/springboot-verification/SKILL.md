---
name: springboot-verification
description: "Spring Boot 프로젝트용 검증 루프: 빌드·정적 분석·커버리지 있는 테스트·보안 스캔·릴리스/PR 전 diff 리뷰 (Verification loop for Spring Boot projects: build, static analysis, tests with coverage, security scans, and diff review before release or PR)."
origin: ECC
---

# Spring Boot 검증 루프

PR 전·주요 변경 후·배포 전 실행.

## 활성화 시점

- Spring Boot 서비스 PR 오픈 전
- 주요 리팩토링·의존성 업그레이드 후
- 스테이징·프로덕션 배포 전 검증
- 전체 빌드 → 린트 → 테스트 → 보안 스캔 파이프라인 실행
- 테스트 커버리지 임계치 만족 검증

## Phase 1: 빌드

```bash
mvn -T 4 clean verify -DskipTests
# 또는
./gradlew clean assemble -x test
```

빌드 실패 시 중단·수정.

## Phase 2: 정적 분석

Maven (일반 플러그인):
```bash
mvn -T 4 spotbugs:check pmd:check checkstyle:check
```

Gradle (설정 시):
```bash
./gradlew checkstyleMain pmdMain spotbugsMain
```

## Phase 3: 테스트 + 커버리지

```bash
mvn -T 4 test
mvn jacoco:report   # 80%+ 커버리지 검증
# 또는
./gradlew test jacocoTestReport
```

리포트:
- 총 테스트·통과/실패
- 커버리지 % (라인/분기)

### 단위 테스트

mock 의존성으로 서비스 로직 격리 테스트:

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

  @Mock private UserRepository userRepository;
  @InjectMocks private UserService userService;

  @Test
  void createUser_validInput_returnsUser() {
    var dto = new CreateUserDto("Alice", "alice@example.com");
    var expected = new User(1L, "Alice", "alice@example.com");
    when(userRepository.save(any(User.class))).thenReturn(expected);

    var result = userService.create(dto);

    assertThat(result.name()).isEqualTo("Alice");
    verify(userRepository).save(any(User.class));
  }

  @Test
  void createUser_duplicateEmail_throwsException() {
    var dto = new CreateUserDto("Alice", "existing@example.com");
    when(userRepository.existsByEmail(dto.email())).thenReturn(true);

    assertThatThrownBy(() -> userService.create(dto))
        .isInstanceOf(DuplicateEmailException.class);
  }
}
```

### Testcontainers로 통합 테스트

H2 대신 실제 DB로 테스트:

```java
@SpringBootTest
@Testcontainers
class UserRepositoryIntegrationTest {

  @Container
  static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
      .withDatabaseName("testdb");

  @DynamicPropertySource
  static void configureProperties(DynamicPropertyRegistry registry) {
    registry.add("spring.datasource.url", postgres::getJdbcUrl);
    registry.add("spring.datasource.username", postgres::getUsername);
    registry.add("spring.datasource.password", postgres::getPassword);
  }

  @Autowired private UserRepository userRepository;

  @Test
  void findByEmail_existingUser_returnsUser() {
    userRepository.save(new User("Alice", "alice@example.com"));

    var found = userRepository.findByEmail("alice@example.com");

    assertThat(found).isPresent();
    assertThat(found.get().getName()).isEqualTo("Alice");
  }
}
```

### MockMvc로 API 테스트

전체 Spring 컨텍스트로 컨트롤러 레이어 테스트:

```java
@WebMvcTest(UserController.class)
class UserControllerTest {

  @Autowired private MockMvc mockMvc;
  @MockBean private UserService userService;

  @Test
  void createUser_validInput_returns201() throws Exception {
    var user = new UserDto(1L, "Alice", "alice@example.com");
    when(userService.create(any())).thenReturn(user);

    mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {"name": "Alice", "email": "alice@example.com"}
                """))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.name").value("Alice"));
  }

  @Test
  void createUser_invalidEmail_returns400() throws Exception {
    mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {"name": "Alice", "email": "not-an-email"}
                """))
        .andExpect(status().isBadRequest());
  }
}
```

## Phase 4: 보안 스캔

```bash
# 의존성 CVE
mvn org.owasp:dependency-check-maven:check
# 또는
./gradlew dependencyCheckAnalyze

# 소스의 시크릿
grep -rn "password\s*=\s*\"" src/ --include="*.java" --include="*.yml" --include="*.properties"
grep -rn "sk-\|api_key\|secret" src/ --include="*.java" --include="*.yml"

# 시크릿 (git 히스토리)
git secrets --scan  # 설정 시
```

### 일반 보안 발견

```
# System.out.println 체크 (대신 logger 사용)
grep -rn "System\.out\.print" src/main/ --include="*.java"

# 응답의 raw 예외 메시지 체크
grep -rn "e\.getMessage()" src/main/ --include="*.java"

# 와일드카드 CORS 체크
grep -rn "allowedOrigins.*\*" src/main/ --include="*.java"
```

## Phase 5: 린트/포맷 (선택 게이트)

```bash
mvn spotless:apply   # Spotless 플러그인 사용 시
./gradlew spotlessApply
```

## Phase 6: Diff 리뷰

```bash
git diff --stat
git diff
```

체크리스트:
- 디버깅 로그 남지 않음 (`System.out`·가드 없는 `log.debug`)
- 의미 있는 에러·HTTP 상태
- 필요한 곳에 트랜잭션·검증 존재
- 설정 변경 문서화

## 출력 템플릿

```
VERIFICATION REPORT
===================
Build:     [PASS/FAIL]
Static:    [PASS/FAIL] (spotbugs/pmd/checkstyle)
Tests:     [PASS/FAIL] (X/Y passed, Z% coverage)
Security:  [PASS/FAIL] (CVE findings: N)
Diff:      [X files changed]

Overall:   [READY / NOT READY]

Issues to Fix:
1. ...
2. ...
```

## 지속 모드

- 주요 변경 시 또는 긴 세션에서 30-60분마다 phase 재실행
- 빠른 피드백 위해 짧은 루프 유지: `mvn -T 4 test` + spotbugs

**기억하라**: 빠른 피드백이 늦은 깜짝보다 낫다. 게이트 엄격 유지 — 프로덕션 시스템에서 경고를 결함으로 취급.
