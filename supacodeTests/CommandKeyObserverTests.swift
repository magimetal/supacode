import AppKit
import Testing

@testable import supacode

struct CommandKeyObserverTests {
  @Test func shouldShowCommandShortcutsForCommandOnly() {
    #expect(CommandKeyObserver.shouldShowCommandShortcuts(for: [.command]))
    #expect(CommandKeyObserver.shouldShowCommandShortcuts(for: [.command, .shift]))
    #expect(CommandKeyObserver.shouldShowCommandShortcuts(for: [.command, .control, .shift]))
  }

  @Test func shouldNotShowCommandShortcutsForNonCommandModifiers() {
    #expect(CommandKeyObserver.shouldShowCommandShortcuts(for: []) == false)
    #expect(CommandKeyObserver.shouldShowCommandShortcuts(for: [.control]) == false)
    #expect(CommandKeyObserver.shouldShowCommandShortcuts(for: [.control, .shift]) == false)
    #expect(CommandKeyObserver.shouldShowCommandShortcuts(for: [.option]) == false)
    #expect(CommandKeyObserver.shouldShowCommandShortcuts(for: [.shift, .option]) == false)
  }

  @Test func shouldShowWorktreeSelectionShortcutsForControlShift() {
    #expect(CommandKeyObserver.shouldShowWorktreeSelectionShortcuts(for: [.control, .shift]))
    #expect(CommandKeyObserver.shouldShowWorktreeSelectionShortcuts(for: [.control, .shift, .option]))
    #expect(CommandKeyObserver.shouldShowWorktreeSelectionShortcuts(for: [.command, .control, .shift]))
  }

  @Test func shouldNotShowWorktreeSelectionShortcutsForPlainControlOrCommand() {
    #expect(CommandKeyObserver.shouldShowWorktreeSelectionShortcuts(for: []) == false)
    #expect(CommandKeyObserver.shouldShowWorktreeSelectionShortcuts(for: [.control]) == false)
    #expect(CommandKeyObserver.shouldShowWorktreeSelectionShortcuts(for: [.command]) == false)
    #expect(CommandKeyObserver.shouldShowWorktreeSelectionShortcuts(for: [.command, .shift]) == false)
    #expect(CommandKeyObserver.shouldShowWorktreeSelectionShortcuts(for: [.shift]) == false)
    #expect(CommandKeyObserver.shouldShowWorktreeSelectionShortcuts(for: [.option]) == false)
  }
}
