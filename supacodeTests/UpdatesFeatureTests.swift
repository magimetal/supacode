import ComposableArchitecture
import DependenciesTestSupport
import SupacodeSettingsShared
import Testing

@testable import supacode

@MainActor
struct UpdatesFeatureTests {
  @Test(.dependencies) func applySettingsForcesDisabledUpdaterConfiguration() async {
    let configuredValues = LockIsolated<[UpdaterConfigurationCall]>([])
    let channels = LockIsolated<[UpdateChannel]>([])
    let store = TestStore(initialState: UpdatesFeature.State()) {
      UpdatesFeature()
    } withDependencies: {
      $0.updaterClient.configure = { checks, downloads, checkInBackground in
        configuredValues.withValue {
          $0.append(
            UpdaterConfigurationCall(
              checks: checks,
              downloads: downloads,
              checkInBackground: checkInBackground
            )
          )
        }
      }
      $0.updaterClient.setUpdateChannel = { channel in
        channels.withValue { $0.append(channel) }
      }
    }

    await store.send(
      .applySettings(
        updateChannel: .tip,
        automaticallyChecks: true,
        automaticallyDownloads: true
      )
    ) {
      $0.didConfigureUpdates = true
    }
    await store.finish()

    #expect(channels.value == [.tip])
    #expect(configuredValues.value.count == 1)
    #expect(configuredValues.value.first?.checks == false)
    #expect(configuredValues.value.first?.downloads == false)
    #expect(configuredValues.value.first?.checkInBackground == false)
  }

  @Test(.dependencies) func checkForUpdatesIsNoOp() async {
    let checkCount = LockIsolated(0)
    let analyticsEvents = LockIsolated<[String]>([])
    let store = TestStore(initialState: UpdatesFeature.State()) {
      UpdatesFeature()
    } withDependencies: {
      $0.updaterClient.checkForUpdates = {
        checkCount.withValue { $0 += 1 }
      }
      $0.analyticsClient.capture = { event, _ in
        analyticsEvents.withValue { $0.append(event) }
      }
    }

    await store.send(.checkForUpdates)
    await store.finish()

    #expect(checkCount.value == 0)
    #expect(analyticsEvents.value.isEmpty)
  }
}

private struct UpdaterConfigurationCall: Equatable {
  var checks: Bool
  var downloads: Bool
  var checkInBackground: Bool
}
