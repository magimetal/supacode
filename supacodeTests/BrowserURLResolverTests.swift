import Foundation
import Testing

@testable import supacode

struct BrowserURLResolverTests {
  @Test func blankInputReturnsNil() {
    #expect(BrowserURLResolver.resolve("  \n\t ") == nil)
  }

  @Test func fullSchemeURLResolvesUnchanged() throws {
    let url = try #require(BrowserURLResolver.resolve("https://example.com/path?q=1"))
    #expect(url.absoluteString == "https://example.com/path?q=1")
  }

  @Test func domainLikeInputDefaultsToHTTPS() throws {
    let url = try #require(BrowserURLResolver.resolve("example.com"))
    #expect(url.absoluteString == "https://example.com")
  }

  @Test func localhostWithPortDefaultsToHTTP() throws {
    let url = try #require(BrowserURLResolver.resolve("localhost:3000"))
    #expect(url.absoluteString == "http://localhost:3000")
  }

  @Test func searchTermsResolveToDuckDuckGo() throws {
    let url = try #require(BrowserURLResolver.resolve("swift observable browser tabs"))
    #expect(url.scheme == "https")
    #expect(url.host() == "duckduckgo.com")
    #expect(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems == [
      URLQueryItem(name: "q", value: "swift observable browser tabs"),
    ])
  }
}
