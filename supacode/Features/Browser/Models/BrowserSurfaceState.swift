import Foundation
import Observation
import SupacodeSettingsShared
import WebKit

private let browserLogger = SupaLogger("Browser")

@MainActor
@Observable
final class BrowserSurfaceState: Identifiable {
  let id: UUID
  @ObservationIgnored let webView: WKWebView
  var currentURL: URL?
  var pageTitle = ""
  var isLoading = false
  var estimatedProgress = 0.0
  var canGoBack = false
  var canGoForward = false
  @ObservationIgnored var onDisplayTitleChange: ((String) -> Void)?

  @ObservationIgnored private var observations: [NSKeyValueObservation] = []

  init(id: UUID = UUID()) {
    self.id = id
    self.webView = WKWebView(frame: .zero, configuration: Self.makeConfiguration())
    observeWebView()
  }

  deinit {
    observations.forEach { $0.invalidate() }
  }

  func load(_ url: URL) {
    browserLogger.info("Loading browser URL: \(url.absoluteString)")
    webView.load(URLRequest(url: url))
  }

  func navigateSmart(_ input: String) {
    guard let url = BrowserURLResolver.resolve(input) else { return }
    load(url)
  }

  func goBack() {
    guard webView.canGoBack else { return }
    webView.goBack()
  }

  func goForward() {
    guard webView.canGoForward else { return }
    webView.goForward()
  }

  func reloadOrStop() {
    if webView.isLoading {
      webView.stopLoading()
    } else {
      webView.reload()
    }
  }

  private func observeWebView() {
    observations = [
      webView.observe(\.url, options: [.initial, .new]) { [weak self] _, change in
        let url = change.newValue.flatMap { $0 }
        Task { @MainActor [weak self] in
          self?.currentURL = url
          self?.emitDisplayTitleChange()
        }
      },
      webView.observe(\.title, options: [.initial, .new]) { [weak self] _, change in
        let title = change.newValue.flatMap { $0 } ?? ""
        Task { @MainActor [weak self] in
          self?.pageTitle = title
          self?.emitDisplayTitleChange()
        }
      },
      webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] _, change in
        let isLoading = change.newValue ?? false
        Task { @MainActor [weak self] in
          self?.isLoading = isLoading
        }
      },
      webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] _, change in
        let estimatedProgress = change.newValue ?? 0
        Task { @MainActor [weak self] in
          self?.estimatedProgress = estimatedProgress
        }
      },
      webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] _, change in
        let canGoBack = change.newValue ?? false
        Task { @MainActor [weak self] in
          self?.canGoBack = canGoBack
        }
      },
      webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] _, change in
        let canGoForward = change.newValue ?? false
        Task { @MainActor [weak self] in
          self?.canGoForward = canGoForward
        }
      },
    ]
  }

  private func emitDisplayTitleChange() {
    onDisplayTitleChange?(displayTitle)
  }

  private var displayTitle: String {
    let trimmedTitle = pageTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedTitle.isEmpty { return trimmedTitle }
    if let host = currentURL?.host(), !host.isEmpty { return host }
    if let currentURL { return currentURL.absoluteString }
    return "New Browser"
  }

  private static func makeConfiguration() -> WKWebViewConfiguration {
    let configuration = WKWebViewConfiguration()
    configuration.processPool = sharedProcessPool
    configuration.websiteDataStore = .default()
    return configuration
  }

  private static let sharedProcessPool = WKProcessPool()
}
