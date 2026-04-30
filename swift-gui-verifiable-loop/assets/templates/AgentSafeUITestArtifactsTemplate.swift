import AppKit
import XCTest

// Copy this helper into UI test targets that need agent-safe evidence.
// It intentionally avoids XCUIScreen.main.screenshot(); on macOS prefer window
// or root-element screenshots because XCUIApplication.screenshot() can be
// display-sized on some runners.

extension XCTestCase {
  func attachAgentSafeScreenshot(
    of element: XCUIScreenshotProviding,
    named name: String,
    lifetime: XCTAttachment.Lifetime = .keepAlways
  ) {
    let attachment = XCTAttachment(screenshot: element.screenshot())
    attachment.name = name
    attachment.lifetime = lifetime
    add(attachment)
  }

  func attachAccessibilityTree(
    of app: XCUIApplication,
    named name: String = "accessibility-tree",
    lifetime: XCTAttachment.Lifetime = .keepAlways
  ) {
    let attachment = XCTAttachment(string: app.debugDescription)
    attachment.name = name
    attachment.lifetime = lifetime
    add(attachment)
  }

  func attachCroppedScreenshot(
    of app: XCUIApplication,
    around elements: [XCUIElement],
    named name: String,
    padding: CGFloat = 24,
    lifetime: XCTAttachment.Lifetime = .keepAlways
  ) {
    guard let data = croppedScreenshotData(of: app, around: elements, padding: padding) else {
      let attachment = XCTAttachment(screenshot: app.screenshot())
      attachment.name = name
      attachment.lifetime = lifetime
      add(attachment)
      return
    }

    let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
    attachment.name = name
    attachment.lifetime = lifetime
    add(attachment)
  }

  private func croppedScreenshotData(
    of app: XCUIApplication,
    around elements: [XCUIElement],
    padding: CGFloat
  ) -> Data? {
    let visibleElements = elements.filter { $0.exists && !$0.frame.isEmpty }
    guard !visibleElements.isEmpty else {
      return nil
    }

    var cropFrame = visibleElements.reduce(CGRect.null) { partial, element in
      partial.union(element.frame)
    }
    cropFrame = cropFrame.insetBy(dx: -padding, dy: -padding)

    let screenshot = app.screenshot()
    guard
      let bitmap = NSBitmapImageRep(data: screenshot.pngRepresentation),
      let image = bitmap.cgImage,
      let screenFrame = NSScreen.main?.frame
    else {
      return nil
    }

    cropFrame = cropFrame.intersection(CGRect(origin: .zero, size: screenFrame.size))
    guard !cropFrame.isNull, !cropFrame.isEmpty else {
      return nil
    }

    let scaleX = CGFloat(image.width) / screenFrame.width
    let scaleY = CGFloat(image.height) / screenFrame.height
    let pixelCrop = CGRect(
      x: floor(cropFrame.minX * scaleX),
      y: floor(cropFrame.minY * scaleY),
      width: ceil(cropFrame.width * scaleX),
      height: ceil(cropFrame.height * scaleY)
    )
    .integral
    .intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))

    guard
      !pixelCrop.isNull,
      !pixelCrop.isEmpty,
      let cropped = image.cropping(to: pixelCrop)
    else {
      return nil
    }

    return NSBitmapImageRep(cgImage: cropped).representation(using: .png, properties: [:])
  }
}
