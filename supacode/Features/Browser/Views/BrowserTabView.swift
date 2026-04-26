import SwiftUI

struct BrowserTabView: View {
  @Bindable var surface: BrowserSurfaceState
  @State private var addressText = ""

  var body: some View {
    VStack(spacing: 0) {
      browserChrome
      if surface.isLoading && surface.estimatedProgress > 0 && surface.estimatedProgress < 1 {
        ProgressView(value: surface.estimatedProgress)
          .controlSize(.small)
      }
      BrowserWebViewRepresentable(webView: surface.webView)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .onAppear {
      syncAddressText()
    }
    .onChange(of: surface.currentURL) { _, _ in
      syncAddressText()
    }
  }

  private var browserChrome: some View {
    HStack(spacing: 8) {
      Button {
        surface.goBack()
      } label: {
        Image(systemName: "chevron.left")
          .accessibilityLabel("Go Back")
      }
      .buttonStyle(.borderless)
      .disabled(!surface.canGoBack)
      .help("Go Back")

      Button {
        surface.goForward()
      } label: {
        Image(systemName: "chevron.right")
          .accessibilityLabel("Go Forward")
      }
      .buttonStyle(.borderless)
      .disabled(!surface.canGoForward)
      .help("Go Forward")

      Button {
        surface.reloadOrStop()
      } label: {
        Image(systemName: surface.isLoading ? "xmark" : "arrow.clockwise")
          .accessibilityLabel(surface.isLoading ? "Stop Loading" : "Reload Page")
      }
      .buttonStyle(.borderless)
      .help(surface.isLoading ? "Stop Loading" : "Reload Page")

      TextField("Search or enter website name", text: $addressText)
        .textFieldStyle(.roundedBorder)
        .onSubmit {
          surface.navigateSmart(addressText)
        }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(.bar)
  }

  private func syncAddressText() {
    guard let url = surface.currentURL else { return }
    addressText = url.absoluteString
  }
}
