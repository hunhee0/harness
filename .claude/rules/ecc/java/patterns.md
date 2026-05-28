---
paths:
  - "**/*.java"
---
# Java 패턴 (Java Patterns)

> 이 파일은 [common/patterns.md](../common/patterns.md)를 Java 특화 내용으로 확장한다.

## Repository 패턴

인터페이스 뒤에 데이터 접근을 캡슐화:

```java
public interface OrderRepository {
    Optional<Order> findById(Long id);
    List<Order> findAll();
    Order save(Order order);
    void deleteById(Long id);
}
```

구체 구현이 저장 디테일(JPA·JDBC·테스트용 in-memory)을 처리.

## Service 레이어

비즈니스 로직은 service 클래스에 두고 컨트롤러·리포지토리는 얇게 유지:

```java
public class OrderService {
    private final OrderRepository orderRepository;
    private final PaymentGateway paymentGateway;

    public OrderService(OrderRepository orderRepository, PaymentGateway paymentGateway) {
        this.orderRepository = orderRepository;
        this.paymentGateway = paymentGateway;
    }

    public OrderSummary placeOrder(CreateOrderRequest request) {
        var order = Order.from(request);
        paymentGateway.charge(order.total());
        var saved = orderRepository.save(order);
        return OrderSummary.from(saved);
    }
}
```

## 생성자 주입

항상 생성자 주입 사용 — 필드 주입 금지:

```java
// GOOD — 생성자 주입 (테스트 가능, 불변)
public class NotificationService {
    private final EmailSender emailSender;

    public NotificationService(EmailSender emailSender) {
        this.emailSender = emailSender;
    }
}

// BAD — 필드 주입 (리플렉션 없으면 테스트 불가, 프레임워크 마법 필요)
public class NotificationService {
    @Inject // 또는 @Autowired
    private EmailSender emailSender;
}
```

## DTO 매핑

DTO에 record 사용. service·controller 경계에서 매핑:

```java
public record OrderResponse(Long id, String customer, BigDecimal total) {
    public static OrderResponse from(Order order) {
        return new OrderResponse(order.getId(), order.getCustomerName(), order.getTotal());
    }
}
```

## Builder 패턴

선택 파라미터가 많은 객체에 사용:

```java
public class SearchCriteria {
    private final String query;
    private final int page;
    private final int size;
    private final String sortBy;

    private SearchCriteria(Builder builder) {
        this.query = builder.query;
        this.page = builder.page;
        this.size = builder.size;
        this.sortBy = builder.sortBy;
    }

    public static class Builder {
        private String query = "";
        private int page = 0;
        private int size = 20;
        private String sortBy = "id";

        public Builder query(String query) { this.query = query; return this; }
        public Builder page(int page) { this.page = page; return this; }
        public Builder size(int size) { this.size = size; return this; }
        public Builder sortBy(String sortBy) { this.sortBy = sortBy; return this; }
        public SearchCriteria build() { return new SearchCriteria(this); }
    }
}
```

## 도메인 모델에 sealed 타입

```java
public sealed interface PaymentResult permits PaymentSuccess, PaymentFailure {
    record PaymentSuccess(String transactionId, BigDecimal amount) implements PaymentResult {}
    record PaymentFailure(String errorCode, String message) implements PaymentResult {}
}

// 완전 처리 (Java 21+)
String message = switch (result) {
    case PaymentSuccess s -> "Paid: " + s.transactionId();
    case PaymentFailure f -> "Failed: " + f.errorCode();
};
```

## API 응답 Envelope

일관된 API 응답:

```java
public record ApiResponse<T>(boolean success, T data, String error) {
    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, null);
    }
    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(false, null, message);
    }
}
```

## 참조

Spring Boot 아키텍처 패턴은 skill: `springboot-patterns` 참조.
REST·Panache·메시징 Quarkus 아키텍처 패턴은 skill: `quarkus-patterns` 참조.
엔티티 설계·쿼리 최적화는 skill: `jpa-patterns` 참조.
