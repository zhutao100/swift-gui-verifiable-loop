import Testing
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Demonstrates Swift Testing attachments (Xcode 26 / Swift 6.2+).
///
/// Notes:
/// - Swift Testing is best used for unit/state tests (deterministic core gate).
/// - UI automation still uses XCTest + XCUITest.
/// - Attachments are most useful when they capture low-noise evidence (logs, JSON, small rendered views).

struct SwiftTestingAttachmentsExamples {

  @Test func attachTextLog() {
    let log = "request_id=123 status=failed"
    Attachment.record(Array(log.utf8), named: "debug.log")
  }

  @MainActor
  @Test func attachRenderedSwiftUIView() throws {
    let view = Text("Hello")
      .padding()
      .background(Color.yellow)

    #if canImport(UIKit)
    let image = try #require(ImageRenderer(content: view).uiImage)
    Attachment.record(image, named: "hello", as: .png)
    #elseif canImport(AppKit)
    let image = try #require(ImageRenderer(content: view).nsImage)
    Attachment.record(image, named: "hello", as: .png)
    #else
    // Non-Apple platforms: image attachments may not be available.
    Attachment.record(Array("image attachments not supported".utf8), named: "note.txt")
    #endif
  }
}
