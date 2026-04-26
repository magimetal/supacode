import SwiftUI
import WebKit

struct BrowserWebViewRepresentable: NSViewRepresentable {
  let webView: WKWebView

  func makeNSView(context _: Context) -> WKWebView {
    webView
  }

  func updateNSView(_: WKWebView, context _: Context) {}
}
