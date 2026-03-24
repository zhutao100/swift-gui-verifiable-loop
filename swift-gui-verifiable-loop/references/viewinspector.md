# ViewInspector quick reference

ViewInspector enables unit-style tests over SwiftUI view hierarchies (reflection-based).

## Basic usage

```swift
import XCTest
import ViewInspector
@testable import MyApp

final class ContentViewTests: XCTestCase {
  func testStringValue() throws {
    let sut = ContentView()
    let value = try sut.inspect().implicitAnyView().text().string()
    XCTAssertEqual(value, "Hello, world!")
  }
}
```

## Notes

- With Swift 6 (Xcode 16+), the compiler may insert implicit `AnyView`s; `implicitAnyView()` helps unwrap.
- Treat this as a tactical tool (reflection can be sensitive to framework/compiler changes).

Template: `assets/templates/ViewInspectorTemplate.swift`
