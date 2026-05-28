---
name: api-design
description: 리소스 명명·상태 코드·페이지네이션·필터링·에러 응답·버저닝·rate limiting을 포함한 프로덕션 API용 REST API 디자인 패턴 (REST API design patterns including resource naming, status codes, pagination, filtering, error responses, versioning, and rate limiting for production APIs).
origin: ECC
---

# API 디자인 패턴

일관되고 개발자 친화적 REST API 디자인을 위한 관례·모범 사례.

## 활성화 시점

- 새 API 엔드포인트 설계
- 기존 API 계약 리뷰
- 페이지네이션·필터링·정렬 추가
- API 에러 처리 구현
- API 버저닝 전략 계획
- 공개 또는 파트너 대상 API 구축

## 리소스 디자인

### URL 구조

```
# 리소스는 명사·복수·소문자·kebab-case
GET    /api/v1/users
GET    /api/v1/users/:id
POST   /api/v1/users
PUT    /api/v1/users/:id
PATCH  /api/v1/users/:id
DELETE /api/v1/users/:id

# 관계용 서브 리소스
GET    /api/v1/users/:id/orders
POST   /api/v1/users/:id/orders

# CRUD에 매핑되지 않는 액션 (동사 절제 사용)
POST   /api/v1/orders/:id/cancel
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
```

### 명명 규칙

```
# GOOD
/api/v1/team-members          # 다단어 리소스에 kebab-case
/api/v1/orders?status=active  # 필터링에 query param
/api/v1/users/123/orders      # 소유권에 중첩 리소스

# BAD
/api/v1/getUsers              # URL에 동사
/api/v1/user                  # 단수 (복수 사용)
/api/v1/team_members          # URL의 snake_case
/api/v1/users/123/getOrders   # 중첩 리소스에 동사
```

## HTTP 메서드와 상태 코드

### 메서드 의미

| Method | Idempotent | Safe | Use For |
|--------|-----------|------|---------|
| GET | Yes | Yes | 리소스 조회 |
| POST | No | No | 리소스 생성·액션 트리거 |
| PUT | Yes | No | 리소스 전체 교체 |
| PATCH | No* | No | 리소스 부분 업데이트 |
| DELETE | Yes | No | 리소스 제거 |

*PATCH는 적절한 구현으로 idempotent 가능

### 상태 코드 레퍼런스

```
# 성공
200 OK                    — GET·PUT·PATCH (응답 바디 있음)
201 Created               — POST (Location 헤더 포함)
204 No Content            — DELETE·PUT (응답 바디 없음)

# 클라이언트 에러
400 Bad Request           — 검증 실패·잘못된 JSON
401 Unauthorized          — 인증 누락 또는 무효
403 Forbidden             — 인증되었으나 권한 없음
404 Not Found             — 리소스 존재 안 함
409 Conflict              — 중복 항목·상태 충돌
422 Unprocessable Entity  — 의미적으로 무효 (JSON은 유효, 데이터 나쁨)
429 Too Many Requests     — rate limit 초과

# 서버 에러
500 Internal Server Error — 예상치 못한 실패 (디테일 노출 금지)
502 Bad Gateway           — 업스트림 서비스 실패
503 Service Unavailable   — 일시 과부하, Retry-After 포함
```

### 일반적 실수

```
# BAD: 모든 것에 200
{ "status": 200, "success": false, "error": "Not found" }

# GOOD: HTTP 상태 코드를 의미적으로 사용
HTTP/1.1 404 Not Found
{ "error": { "code": "not_found", "message": "User not found" } }

# BAD: 검증 에러에 500
# GOOD: 필드별 디테일과 함께 400 또는 422

# BAD: 생성된 리소스에 200
# GOOD: Location 헤더와 함께 201
HTTP/1.1 201 Created
Location: /api/v1/users/abc-123
```

## 응답 형식

### 성공 응답

```json
{
  "data": {
    "id": "abc-123",
    "email": "alice@example.com",
    "name": "Alice",
    "created_at": "2025-01-15T10:30:00Z"
  }
}
```

### 컬렉션 응답 (페이지네이션 포함)

```json
{
  "data": [
    { "id": "abc-123", "name": "Alice" },
    { "id": "def-456", "name": "Bob" }
  ],
  "meta": {
    "total": 142,
    "page": 1,
    "per_page": 20,
    "total_pages": 8
  },
  "links": {
    "self": "/api/v1/users?page=1&per_page=20",
    "next": "/api/v1/users?page=2&per_page=20",
    "last": "/api/v1/users?page=8&per_page=20"
  }
}
```

### 에러 응답

```json
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed",
    "details": [
      {
        "field": "email",
        "message": "Must be a valid email address",
        "code": "invalid_format"
      },
      {
        "field": "age",
        "message": "Must be between 0 and 150",
        "code": "out_of_range"
      }
    ]
  }
}
```

### 응답 Envelope 변형

```typescript
// Option A: data wrapper 있는 envelope (공개 API에 권장)
interface ApiResponse<T> {
  data: T;
  meta?: PaginationMeta;
  links?: PaginationLinks;
}

interface ApiError {
  error: {
    code: string;
    message: string;
    details?: FieldError[];
  };
}

// Option B: flat 응답 (단순, 내부 API에 흔함)
// 성공: 리소스 직접 반환
// 에러: 에러 객체 반환
// HTTP 상태 코드로 구분
```

## 페이지네이션

### Offset 기반 (단순)

```
GET /api/v1/users?page=2&per_page=20

# 구현
SELECT * FROM users
ORDER BY created_at DESC
LIMIT 20 OFFSET 20;
```

**Pros:** 구현 쉬움, "N 페이지로 점프" 지원
**Cons:** 큰 offset(OFFSET 100000)에서 느림, 동시 insert와 불일치

### Cursor 기반 (확장성)

```
GET /api/v1/users?cursor=eyJpZCI6MTIzfQ&limit=20

# 구현
SELECT * FROM users
WHERE id > :cursor_id
ORDER BY id ASC
LIMIT 21;  -- has_next 판단용 추가 1개 fetch
```

```json
{
  "data": [...],
  "meta": {
    "has_next": true,
    "next_cursor": "eyJpZCI6MTQzfQ"
  }
}
```

**Pros:** 위치와 무관하게 일관된 성능, 동시 insert에 안정
**Cons:** 임의 페이지로 점프 불가, cursor가 불투명

### 사용 시점

| Use Case | Pagination Type |
|----------|----------------|
| 관리자 대시보드·소규모 데이터셋(<10K) | Offset |
| 무한 스크롤·피드·대규모 데이터셋 | Cursor |
| 공개 API | Cursor (기본) + offset (선택) |
| 검색 결과 | Offset (사용자가 페이지 번호 기대) |

## 필터링·정렬·검색

### 필터링

```
# 단순 동등
GET /api/v1/orders?status=active&customer_id=abc-123

# 비교 연산자 (bracket 표기)
GET /api/v1/products?price[gte]=10&price[lte]=100
GET /api/v1/orders?created_at[after]=2025-01-01

# 다중 값 (콤마 구분)
GET /api/v1/products?category=electronics,clothing

# 중첩 필드 (dot 표기)
GET /api/v1/orders?customer.country=US
```

### 정렬

```
# 단일 필드 (내림차순은 - 접두사)
GET /api/v1/products?sort=-created_at

# 다중 필드 (콤마 구분)
GET /api/v1/products?sort=-featured,price,-created_at
```

### 전문 검색

```
# 검색 query param
GET /api/v1/products?q=wireless+headphones

# 필드 특정 검색
GET /api/v1/users?email=alice
```

### Sparse Fieldset

```
# 지정 필드만 반환 (페이로드 감소)
GET /api/v1/users?fields=id,name,email
GET /api/v1/orders?fields=id,total,status&include=customer.name
```

## 인증·인가

### 토큰 기반 인증

```
# Authorization 헤더의 Bearer 토큰
GET /api/v1/users
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

# API 키 (서버-서버)
GET /api/v1/data
X-API-Key: sk_live_abc123
```

### 인가 패턴

```typescript
// 리소스 레벨: 소유권 체크
app.get("/api/v1/orders/:id", async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ error: { code: "not_found" } });
  if (order.userId !== req.user.id) return res.status(403).json({ error: { code: "forbidden" } });
  return res.json({ data: order });
});

// Role 기반: 권한 체크
app.delete("/api/v1/users/:id", requireRole("admin"), async (req, res) => {
  await User.delete(req.params.id);
  return res.status(204).send();
});
```

## Rate Limiting

### 헤더

```
HTTP/1.1 200 OK
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000

# 초과 시
HTTP/1.1 429 Too Many Requests
Retry-After: 60
{
  "error": {
    "code": "rate_limit_exceeded",
    "message": "Rate limit exceeded. Try again in 60 seconds."
  }
}
```

### Rate Limit 티어

| Tier | Limit | Window | Use Case |
|------|-------|--------|----------|
| Anonymous | 30/min | IP별 | 공개 엔드포인트 |
| Authenticated | 100/min | 사용자별 | 표준 API 접근 |
| Premium | 1000/min | API 키별 | 유료 API 플랜 |
| Internal | 10000/min | 서비스별 | 서비스-서비스 |

## 버저닝

### URL 경로 버저닝 (권장)

```
/api/v1/users
/api/v2/users
```

**Pros:** 명시적, 라우팅 쉬움, 캐시 가능
**Cons:** 버전 간 URL 변경

### 헤더 버저닝

```
GET /api/users
Accept: application/vnd.myapp.v2+json
```

**Pros:** 깔끔한 URL
**Cons:** 테스트 어려움, 잊기 쉬움

### 버저닝 전략

```
1. /api/v1/로 시작 — 필요할 때까지 버저닝 금지
2. 최대 2개 활성 버전 유지 (현재 + 이전)
3. Deprecation 타임라인:
   - Deprecation 공지 (공개 API는 6개월 notice)
   - Sunset 헤더 추가: Sunset: Sat, 01 Jan 2026 00:00:00 GMT
   - sunset 날짜 이후 410 Gone 반환
4. 비파괴 변경은 새 버전 불필요:
   - 응답에 새 필드 추가
   - 새 선택 query param 추가
   - 새 엔드포인트 추가
5. 파괴 변경은 새 버전 필요:
   - 필드 제거·이름 변경
   - 필드 타입 변경
   - URL 구조 변경
   - 인증 방법 변경
```

## 구현 패턴

### TypeScript (Next.js API Route)

```typescript
import { z } from "zod";
import { NextRequest, NextResponse } from "next/server";

const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
});

export async function POST(req: NextRequest) {
  const body = await req.json();
  const parsed = createUserSchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json({
      error: {
        code: "validation_error",
        message: "Request validation failed",
        details: parsed.error.issues.map(i => ({
          field: i.path.join("."),
          message: i.message,
          code: i.code,
        })),
      },
    }, { status: 422 });
  }

  const user = await createUser(parsed.data);

  return NextResponse.json(
    { data: user },
    {
      status: 201,
      headers: { Location: `/api/v1/users/${user.id}` },
    },
  );
}
```

### Python (Django REST Framework)

```python
from rest_framework import serializers, viewsets, status
from rest_framework.response import Response

class CreateUserSerializer(serializers.Serializer):
    email = serializers.EmailField()
    name = serializers.CharField(max_length=100)

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "email", "name", "created_at"]

class UserViewSet(viewsets.ModelViewSet):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action == "create":
            return CreateUserSerializer
        return UserSerializer

    def create(self, request):
        serializer = CreateUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = UserService.create(**serializer.validated_data)
        return Response(
            {"data": UserSerializer(user).data},
            status=status.HTTP_201_CREATED,
            headers={"Location": f"/api/v1/users/{user.id}"},
        )
```

### Go (net/http)

```go
func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        writeError(w, http.StatusBadRequest, "invalid_json", "Invalid request body")
        return
    }

    if err := req.Validate(); err != nil {
        writeError(w, http.StatusUnprocessableEntity, "validation_error", err.Error())
        return
    }

    user, err := h.service.Create(r.Context(), req)
    if err != nil {
        switch {
        case errors.Is(err, domain.ErrEmailTaken):
            writeError(w, http.StatusConflict, "email_taken", "Email already registered")
        default:
            writeError(w, http.StatusInternalServerError, "internal_error", "Internal error")
        }
        return
    }

    w.Header().Set("Location", fmt.Sprintf("/api/v1/users/%s", user.ID))
    writeJSON(w, http.StatusCreated, map[string]any{"data": user})
}
```

## API 디자인 체크리스트

새 엔드포인트 출하 전:

- [ ] 리소스 URL이 명명 관례 따름 (복수·kebab-case·동사 없음)
- [ ] 올바른 HTTP 메서드 사용 (읽기는 GET, 생성은 POST 등)
- [ ] 적절한 상태 코드 반환 (모든 것에 200 금지)
- [ ] 스키마로 입력 검증 (Zod·Pydantic·Bean Validation)
- [ ] 에러 응답이 코드·메시지의 표준 형식 따름
- [ ] 리스트 엔드포인트에 페이지네이션 구현 (cursor 또는 offset)
- [ ] 인증 요구 (또는 명시적으로 public 표시)
- [ ] 인가 체크 (사용자가 자신의 리소스만 접근)
- [ ] Rate limiting 설정
- [ ] 응답이 내부 디테일 누출 안 함 (stack trace·SQL 에러)
- [ ] 기존 엔드포인트와 일관된 명명 (camelCase vs snake_case)
- [ ] 문서화 (OpenAPI/Swagger spec 업데이트)
