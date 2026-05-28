---
name: liquid-glass-design
description: iOS 26 Liquid Glass 디자인 시스템 — 블러·반사·인터랙티브 모핑을 갖춘 동적 글래스 머티리얼. SwiftUI·UIKit·WidgetKit 용 (iOS 26 Liquid Glass design system — dynamic glass material with blur, reflection, and interactive morphing for SwiftUI, UIKit, and WidgetKit).
---

# Liquid Glass 디자인 시스템 (iOS 26)

Apple의 Liquid Glass 구현 패턴 — 뒤 콘텐츠를 블러하고, 주변 콘텐츠의 색·빛을 반사하며, 터치·포인터 상호작용에 반응하는 동적 머티리얼. SwiftUI·UIKit·WidgetKit 통합 다룸.

## 활성화 시점

- iOS 26+의 새 디자인 언어로 앱 구축·업데이트
- 글래스 스타일 버튼·카드·툴바·컨테이너 구현
- 글래스 요소 간 모핑 전환 생성
- 위젯에 Liquid Glass 효과 적용
- 기존 블러·머티리얼 효과를 새 Liquid Glass API로 마이그레이션

## 핵심 패턴 — SwiftUI

### 기본 Glass Effect

뷰에 Liquid Glass를 추가하는 가장 단순한 방법:

```swift
Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect()  // 기본: regular variant, capsule 모양
```

### 모양·Tint 커스터마이징

```swift
Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect(.regular.tint(.orange).interactive(), in: .rect(cornerRadius: 16.0))
```

핵심 커스터마이징 옵션:
- `.regular` — 표준 글래스 효과
- `.tint(Color)` — 강조용 색 tint 추가
- `.interactive()` — 터치·포인터 상호작용에 반응
- 모양: `.capsule` (기본)·`.rect(cornerRadius:)`·`.circle`

### Glass 버튼 스타일

```swift
Button("Click Me") { /* action */ }
    .buttonStyle(.glass)

Button("Important") { /* action */ }
    .buttonStyle(.glassProminent)
```

### 여러 요소를 위한 GlassEffectContainer

성능과 모핑을 위해 여러 글래스 뷰는 항상 컨테이너로 감쌀 것:

```swift
GlassEffectContainer(spacing: 40.0) {
    HStack(spacing: 40.0) {
        Image(systemName: "scribble.variable")
            .frame(width: 80.0, height: 80.0)
            .font(.system(size: 36))
            .glassEffect()

        Image(systemName: "eraser.fill")
            .frame(width: 80.0, height: 80.0)
            .font(.system(size: 36))
            .glassEffect()
    }
}
```

`spacing` 파라미터가 병합 거리 제어 — 더 가까운 요소는 글래스 모양을 함께 blend.

### Glass 효과 통합

`glassEffectUnion`으로 여러 뷰를 단일 글래스 모양에 결합:

```swift
@Namespace private var namespace

GlassEffectContainer(spacing: 20.0) {
    HStack(spacing: 20.0) {
        ForEach(symbolSet.indices, id: \.self) { item in
            Image(systemName: symbolSet[item])
                .frame(width: 80.0, height: 80.0)
                .glassEffect()
                .glassEffectUnion(id: item < 2 ? "group1" : "group2", namespace: namespace)
        }
    }
}
```

### 모핑 전환

글래스 요소가 출현·사라질 때 매끄러운 모핑 생성:

```swift
@State private var isExpanded = false
@Namespace private var namespace

GlassEffectContainer(spacing: 40.0) {
    HStack(spacing: 40.0) {
        Image(systemName: "scribble.variable")
            .frame(width: 80.0, height: 80.0)
            .glassEffect()
            .glassEffectID("pencil", in: namespace)

        if isExpanded {
            Image(systemName: "eraser.fill")
                .frame(width: 80.0, height: 80.0)
                .glassEffect()
                .glassEffectID("eraser", in: namespace)
        }
    }
}

Button("Toggle") {
    withAnimation { isExpanded.toggle() }
}
.buttonStyle(.glass)
```

### 수평 스크롤을 사이드바 아래로 확장

수평 스크롤 컨텐츠가 사이드바·inspector 아래로 확장되도록 하려면 `ScrollView` 컨텐츠가 컨테이너의 leading/trailing 가장자리까지 도달하도록 보장. 레이아웃이 가장자리까지 확장되면 시스템이 under-sidebar 스크롤 동작을 자동 처리 — 추가 modifier 불필요.

## 핵심 패턴 — UIKit

### 기본 UIGlassEffect

```swift
let glassEffect = UIGlassEffect()
glassEffect.tintColor = UIColor.systemBlue.withAlphaComponent(0.3)
glassEffect.isInteractive = true

let visualEffectView = UIVisualEffectView(effect: glassEffect)
visualEffectView.translatesAutoresizingMaskIntoConstraints = false
visualEffectView.layer.cornerRadius = 20
visualEffectView.clipsToBounds = true

view.addSubview(visualEffectView)
NSLayoutConstraint.activate([
    visualEffectView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    visualEffectView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    visualEffectView.widthAnchor.constraint(equalToConstant: 200),
    visualEffectView.heightAnchor.constraint(equalToConstant: 120)
])

// contentView에 컨텐츠 추가
let label = UILabel()
label.text = "Liquid Glass"
label.translatesAutoresizingMaskIntoConstraints = false
visualEffectView.contentView.addSubview(label)
NSLayoutConstraint.activate([
    label.centerXAnchor.constraint(equalTo: visualEffectView.contentView.centerXAnchor),
    label.centerYAnchor.constraint(equalTo: visualEffectView.contentView.centerYAnchor)
])
```

### 여러 요소용 UIGlassContainerEffect

```swift
let containerEffect = UIGlassContainerEffect()
containerEffect.spacing = 40.0

let containerView = UIVisualEffectView(effect: containerEffect)

let firstGlass = UIVisualEffectView(effect: UIGlassEffect())
let secondGlass = UIVisualEffectView(effect: UIGlassEffect())

containerView.contentView.addSubview(firstGlass)
containerView.contentView.addSubview(secondGlass)
```

### 스크롤 Edge 효과

```swift
scrollView.topEdgeEffect.style = .automatic
scrollView.bottomEdgeEffect.style = .hard
scrollView.leftEdgeEffect.isHidden = true
```

### 툴바 Glass 통합

```swift
let favoriteButton = UIBarButtonItem(image: UIImage(systemName: "heart"), style: .plain, target: self, action: #selector(favoriteAction))
favoriteButton.hidesSharedBackground = true  // 공유 글래스 배경 opt out
```

## 핵심 패턴 — WidgetKit

### 렌더링 모드 감지

```swift
struct MyWidgetView: View {
    @Environment(\.widgetRenderingMode) var renderingMode

    var body: some View {
        if renderingMode == .accented {
            // Tinted 모드: 흰색 tint, 테마화된 글래스 배경
        } else {
            // 전체 컬러 모드: 표준 외관
        }
    }
}
```

### 시각 계층용 Accent 그룹

```swift
HStack {
    VStack(alignment: .leading) {
        Text("Title")
            .widgetAccentable()  // Accent 그룹
        Text("Subtitle")
            // Primary 그룹 (기본)
    }
    Image(systemName: "star.fill")
        .widgetAccentable()  // Accent 그룹
}
```

### Accented 모드의 이미지 렌더링

```swift
Image("myImage")
    .widgetAccentedRenderingMode(.monochrome)
```

### 컨테이너 배경

```swift
VStack { /* content */ }
    .containerBackground(for: .widget) {
        Color.blue.opacity(0.2)
    }
```

## 핵심 디자인 결정

| Decision | Rationale |
|----------|-----------|
| GlassEffectContainer 래핑 | 성능 최적화, 글래스 요소 간 모핑 가능 |
| `spacing` 파라미터 | 병합 거리 제어 — 요소가 얼마나 가까워야 blend되는지 fine-tune |
| `@Namespace` + `glassEffectID` | 뷰 계층 변경 시 매끄러운 모핑 전환 |
| `interactive()` modifier | 터치·포인터 반응 명시적 opt-in — 모든 글래스가 반응해야 하는 건 아님 |
| UIKit의 UIGlassContainerEffect | 일관성 위해 SwiftUI와 동일한 컨테이너 패턴 |
| 위젯의 accented 렌더링 모드 | 사용자가 tinted Home Screen 선택 시 시스템이 tinted 글래스 적용 |

## 모범 사례

- **항상 GlassEffectContainer 사용** — 여러 sibling 뷰에 글래스 적용 시. 모핑 가능·렌더링 성능 향상.
- 다른 외관 modifier(frame·font·padding) **다음에 `.glassEffect()` 적용**.
- 사용자 상호작용에 반응하는 요소(버튼·토글 가능 항목)에만 **`.interactive()` 사용**.
- 컨테이너의 글래스 효과 병합 시점 제어 위해 **spacing 신중히 선택**.
- 뷰 계층 변경 시 매끄러운 모핑 가능 위해 **`withAnimation` 사용**.
- **외관 전반에서 테스트** — light·dark·accented/tinted 모드.
- **접근성 대비 보장** — 글래스 위 텍스트가 가독성 유지해야 함.

## 회피할 안티패턴

- GlassEffectContainer 없이 여러 독립 `.glassEffect()` 뷰 사용
- 글래스 효과 과도한 중첩 — 성능·시각 명료성 저하
- 모든 뷰에 글래스 적용 — 인터랙티브 요소·툴바·카드에 한정
- UIKit에서 corner radii 사용 시 `clipsToBounds = true` 누락
- 위젯의 accented 렌더링 모드 무시 — tinted Home Screen 외관 깨짐
- 글래스 뒤에 불투명 배경 사용 — 반투명 효과 무력화

## 사용 시점

- iOS 26 새 디자인의 네비게이션 바·툴바·탭 바
- 플로팅 액션 버튼·카드 스타일 컨테이너
- 시각 깊이·터치 피드백이 필요한 인터랙티브 컨트롤
- 시스템 Liquid Glass 외관과 통합되어야 할 위젯
- 관련 UI 상태 간 모핑 전환
