import AppKit
import SwiftUI

@MainActor
@Observable
final class CommandKeyObserver {
  private static let holdDelay: Duration = .milliseconds(300)

  var isPressed: Bool
  var isWorktreeSelectionPressed: Bool
  private var monitor: Any?
  private var didBecomeActiveObserver: NSObjectProtocol?
  private var didResignActiveObserver: NSObjectProtocol?
  private var commandHoldTask: Task<Void, Never>?
  private var worktreeSelectionHoldTask: Task<Void, Never>?

  init() {
    isPressed = false
    isWorktreeSelectionPressed = false
    monitor = nil
    didBecomeActiveObserver = nil
    didResignActiveObserver = nil
    commandHoldTask = nil
    worktreeSelectionHoldTask = nil
    configureObservers()
  }

  private func configureObservers() {
    monitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
      MainActor.assumeIsolated {
        self?.handleModifierFlagsChange(event.modifierFlags)
      }
      return event
    }
    let center = NotificationCenter.default
    didBecomeActiveObserver = center.addObserver(
      forName: NSApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.handleModifierFlagsChange(NSEvent.modifierFlags)
      }
    }
    didResignActiveObserver = center.addObserver(
      forName: NSApplication.didResignActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.clearPressedStates()
      }
    }
  }

  nonisolated static func shouldShowCommandShortcuts(for modifierFlags: NSEvent.ModifierFlags) -> Bool {
    modifierFlags.contains(.command)
  }

  nonisolated static func shouldShowWorktreeSelectionShortcuts(for modifierFlags: NSEvent.ModifierFlags) -> Bool {
    modifierFlags.contains(.control) && modifierFlags.contains(.shift)
  }

  private func handleModifierFlagsChange(_ modifierFlags: NSEvent.ModifierFlags) {
    handleCommandKeyChange(isDown: Self.shouldShowCommandShortcuts(for: modifierFlags))
    handleWorktreeSelectionKeyChange(isDown: Self.shouldShowWorktreeSelectionShortcuts(for: modifierFlags))
  }

  private func handleCommandKeyChange(isDown: Bool) {
    updateDelayedState(isDown: isDown, task: &commandHoldTask) { [weak self] in
      self?.isPressed = $0
    }
  }

  private func handleWorktreeSelectionKeyChange(isDown: Bool) {
    updateDelayedState(isDown: isDown, task: &worktreeSelectionHoldTask) { [weak self] in
      self?.isWorktreeSelectionPressed = $0
    }
  }

  private func updateDelayedState(
    isDown: Bool,
    task: inout Task<Void, Never>?,
    setPressed: @escaping @MainActor (Bool) -> Void
  ) {
    task?.cancel()
    task = nil

    if isDown {
      task = Task { @MainActor in
        try? await ContinuousClock().sleep(for: Self.holdDelay)
        guard !Task.isCancelled else { return }
        setPressed(true)
      }
    } else {
      setPressed(false)
    }
  }

  private func clearPressedStates() {
    commandHoldTask?.cancel()
    commandHoldTask = nil
    worktreeSelectionHoldTask?.cancel()
    worktreeSelectionHoldTask = nil
    isPressed = false
    isWorktreeSelectionPressed = false
  }
}
