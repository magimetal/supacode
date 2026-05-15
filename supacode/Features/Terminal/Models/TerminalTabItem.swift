import Foundation
import SupacodeSettingsShared

enum TerminalTabKind: String, Codable, Equatable, Sendable {
  case terminal
  case browser
}

struct TerminalTabItem: Identifiable, Equatable, Sendable {
  let id: TerminalTabID
  /// Live shell title; for display use `displayTitle`.
  var title: String
  /// User-supplied override; nil means follow the live shell title.
  var customTitle: String?
  var icon: String?
  var isDirty: Bool
  var isTitleLocked: Bool
  var tintColor: RepositoryColor?
  var kind: TerminalTabKind

  var displayTitle: String { customTitle ?? title }

  init(
    id: TerminalTabID = TerminalTabID(),
    title: String,
    customTitle: String? = nil,
    icon: String?,
    isDirty: Bool = false,
    isTitleLocked: Bool = false,
    tintColor: RepositoryColor? = nil,
    kind: TerminalTabKind = .terminal
  ) {
    self.id = id
    self.title = title
    self.customTitle = customTitle
    self.icon = icon
    self.isDirty = isDirty
    self.isTitleLocked = isTitleLocked
    self.tintColor = tintColor
    self.kind = kind
  }
}
