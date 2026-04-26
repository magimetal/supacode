import Foundation

enum BrowserURLResolver {
  static func resolve(_ input: String) -> URL? {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    if isLocalhostWithPort(trimmed) {
      // Local development servers commonly do not serve TLS by default.
      return URL(string: "http://\(trimmed)")
    }

    if let url = URL(string: trimmed), url.scheme != nil {
      return url
    }

    if isDomainLike(trimmed) {
      return URL(string: "https://\(trimmed)")
    }

    var components = URLComponents(string: "https://duckduckgo.com/")
    components?.queryItems = [URLQueryItem(name: "q", value: trimmed)]
    return components?.url
  }

  private static func isLocalhostWithPort(_ value: String) -> Bool {
    guard value.hasPrefix("localhost:") else { return false }
    let port = value.dropFirst("localhost:".count)
    return !port.isEmpty && port.allSatisfy(\.isNumber)
  }

  private static func isDomainLike(_ value: String) -> Bool {
    guard !value.contains(" ") else { return false }
    guard value.contains(".") else { return false }
    guard !value.hasPrefix(".") && !value.hasSuffix(".") else { return false }
    return true
  }
}
