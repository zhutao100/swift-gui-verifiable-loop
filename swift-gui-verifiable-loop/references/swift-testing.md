# Swift Testing (deterministic core gate) + attachments

Swift Testing is Apple’s modern testing framework (distinct from XCTest). This skill treats it as part of the “deterministic core” layer (Gate A).

## Why this matters for agentic loops

- Unit/state tests produce **structured, low-noise failures** that are ideal for an agent to act on.
- Swift Testing supports **attachments** (Xcode 26 / Swift 6.2+) which can carry logs, JSON, or images as additional evidence.

## Minimal Swift Testing example

```swift
import Testing

struct MathTests {
  @Test func addition() {
    #expect(1 + 1 == 2)
  }
}
```

## Recording attachments (bytes, strings, and images)

Swift Testing attaches values using `Attachment.record(...)`.

### Attach a text log

```swift
import Testing

@Test func attachesALog() {
  let log = "request_id=123 status=failed"
  Attachment.record(Array(log.utf8), named: "debug.log")
}
```

### Attach a rendered SwiftUI view (image) on Apple platforms

With image attachment support, you can render a SwiftUI view and attach the rendered image:

```swift
import Testing
import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

@MainActor
@Test func attachesSwiftUIViewRendering() throws {
  let view = Text("Hello")
    .padding()
    .background(Color.yellow)

  #if canImport(UIKit)
  let image = try #require(ImageRenderer(content: view).uiImage)
  Attachment.record(image, named: "hello", as: .png)
  #elseif canImport(AppKit)
  let image = try #require(ImageRenderer(content: view).nsImage)
  Attachment.record(image, named: "hello", as: .png)
  #endif
}
```

## Notes

- For UI automation, XCUITest is still the primary tool (Swift Testing does not replace XCUITest).
- For snapshot testing of complex screens, use Point-Free `SnapshotTesting` (see `references/snapshot-testing.md`), and prefer XCTest-based snapshots when you want images to appear as Xcode test report attachments.

## Sources

- Apple docs (Swift Testing): https://developer.apple.com/documentation/testing
- Swift Evolution proposal (image attachments; includes `Attachment.record(image, …)` example):
  https://github.com/swiftlang/swift-evolution/blob/main/proposals/testing/0014-image-attachments-in-swift-testing-apple-platforms.md
