import Foundation
import SupacodeSettingsShared

enum TerminalTabKind: String, Codable, Equatable, Sendable {
  case terminal
  case browser
}

struct TerminalTabItem: Identifiable, Equatable, Sendable {
  let id: TerminalTabID
  var title: String
  var icon: String?
  var isDirty: Bool
  var isTitleLocked: Bool
  var tintColor: TerminalTabTintColor?
  var kind: TerminalTabKind

  init(
    id: TerminalTabID = TerminalTabID(),
    title: String,
    icon: String?,
    isDirty: Bool = false,
    isTitleLocked: Bool = false,
    tintColor: TerminalTabTintColor? = nil,
    kind: TerminalTabKind = .terminal
  ) {
    self.id = id
    self.title = title
    self.icon = icon
    self.isDirty = isDirty
    self.isTitleLocked = isTitleLocked
    self.tintColor = tintColor
    self.kind = kind
  }
}
