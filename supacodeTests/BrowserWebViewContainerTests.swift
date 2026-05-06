import AppKit
import Testing
import WebKit

@testable import supacode

@MainActor
struct BrowserWebViewContainerTests {
  @Test func hoverHitTestingBrowserContentDoesNotRequestPaneFocus() {
    let fixture = makeFixture()

    _ = fixture.container.hitTest(NSPoint(x: 50, y: 50))

    #expect(fixture.focusRequestCount() == 0)
  }

  @Test func mouseDownHitTestingBrowserContentRequestsPaneFocus() throws {
    let fixture = makeFixture()
    let target = fixture.container.hitTest(NSPoint(x: 50, y: 50))
    let event = try #require(mouseEvent(type: .leftMouseDown))

    fixture.container.requestFocusIfNeeded(hitTestTarget: target, event: event)

    #expect(fixture.focusRequestCount() == 1)
  }

  @Test func focusRequestIsLimitedToMouseDownEvents() throws {
    let mouseMovedEvent = try #require(mouseEvent(type: .mouseMoved))
    let leftMouseDownEvent = try #require(mouseEvent(type: .leftMouseDown))
    let rightMouseDownEvent = try #require(mouseEvent(type: .rightMouseDown))
    let otherMouseDownEvent = try #require(mouseEvent(type: .otherMouseDown))

    #expect(!BrowserWebViewContainer.shouldRequestFocus(for: nil))
    #expect(!BrowserWebViewContainer.shouldRequestFocus(for: mouseMovedEvent))
    #expect(BrowserWebViewContainer.shouldRequestFocus(for: leftMouseDownEvent))
    #expect(BrowserWebViewContainer.shouldRequestFocus(for: rightMouseDownEvent))
    #expect(BrowserWebViewContainer.shouldRequestFocus(for: otherMouseDownEvent))
  }

  private func makeFixture() -> (container: BrowserWebViewContainer, focusRequestCount: () -> Int) {
    let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
    var focusRequestCount = 0
    let container = BrowserWebViewContainer(webView: webView) {
      focusRequestCount += 1
    }
    container.frame = NSRect(x: 0, y: 0, width: 100, height: 100)
    container.layoutSubtreeIfNeeded()

    return (container, { focusRequestCount })
  }

  private func mouseEvent(type: NSEvent.EventType, windowNumber: Int = 0) -> NSEvent? {
    NSEvent.mouseEvent(
      with: type,
      location: NSPoint(x: 50, y: 50),
      modifierFlags: [],
      timestamp: 0,
      windowNumber: windowNumber,
      context: nil,
      eventNumber: 0,
      clickCount: 1,
      pressure: 1,
    )
  }
}
