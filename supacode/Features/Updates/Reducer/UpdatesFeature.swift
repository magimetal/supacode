import ComposableArchitecture
import SupacodeSettingsShared

@Reducer
struct UpdatesFeature {
  @ObservableState
  struct State: Equatable {
    var didConfigureUpdates = false
  }

  enum Action {
    case applySettings(
      updateChannel: UpdateChannel,
      automaticallyChecks: Bool,
      automaticallyDownloads: Bool
    )
    case checkForUpdates
  }

  @Dependency(UpdaterClient.self) private var updaterClient

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .applySettings(let channel, _, _):
        state.didConfigureUpdates = true
        return .run { _ in
          await updaterClient.setUpdateChannel(channel)
          await updaterClient.configure(false, false, false)
        }

      case .checkForUpdates:
        return .none
      }
    }
  }
}
