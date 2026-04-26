import AppKit
import Foundation

@MainActor
final class WorktreePaneSurface: NSView, Identifiable {
  let id: UUID
  var content: WorktreePaneContent

  init(id: UUID, content: WorktreePaneContent) {
    self.id = id
    self.content = content
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var terminalSurface: GhosttySurfaceView? {
    if case .terminal(let surface) = content { return surface }
    return nil
  }

  var browserSurface: BrowserSurfaceState? {
    if case .browser(let surface) = content { return surface }
    return nil
  }

  var isTerminal: Bool {
    terminalSurface != nil
  }

  var isBrowser: Bool {
    browserSurface != nil
  }

  var bridge: GhosttySurfaceBridge {
    guard let terminalSurface else {
      preconditionFailure("Browser panes do not own Ghostty surface bridges")
    }
    return terminalSurface.bridge
  }
}

enum WorktreePaneContent {
  case terminal(GhosttySurfaceView)
  case browser(BrowserSurfaceState)
}
