import AppKit
import SwiftUI
import WebKit

struct BrowserWebViewRepresentable: NSViewRepresentable {
  let webView: WKWebView
  var onFocusRequest: (() -> Void)?

  func makeNSView(context _: Context) -> BrowserWebViewContainer {
    BrowserWebViewContainer(webView: webView, onFocusRequest: onFocusRequest)
  }

  func updateNSView(_ nsView: BrowserWebViewContainer, context _: Context) {
    nsView.onFocusRequest = onFocusRequest
  }
}

final class BrowserWebViewContainer: NSView {
  let webView: WKWebView
  var onFocusRequest: (() -> Void)?

  init(webView: WKWebView, onFocusRequest: (() -> Void)?) {
    self.webView = webView
    self.onFocusRequest = onFocusRequest
    super.init(frame: .zero)

    webView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(webView)
    NSLayoutConstraint.activate([
      webView.leadingAnchor.constraint(equalTo: leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: trailingAnchor),
      webView.topAnchor.constraint(equalTo: topAnchor),
      webView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func hitTest(_ point: NSPoint) -> NSView? {
    let target = super.hitTest(point)
    if target != nil {
      onFocusRequest?()
    }
    return target
  }
}
