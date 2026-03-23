import XCTest
import SwiftUI
import ViewInspector
@testable import MyApp

// Your view must conform to Inspectable.
// You can either: (a) add conformance in test-only extension,
// or (b) add it in the main target if acceptable.
extension ContentView: Inspectable {}

final class ContentViewTests: XCTestCase {

  func testStringValue() throws {
    let sut = ContentView()
    let value = try sut.inspect().implicitAnyView().text().string()
    XCTAssertEqual(value, "Hello, world!")
  }
}

private struct ContentView: View {
  var body: some View { Text("Hello, world!") }
}
