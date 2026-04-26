import ComposableArchitecture
import SupacodeSettingsFeature
import SwiftUI

struct UpdatesSettingsView: View {
  @Bindable var settingsStore: StoreOf<SettingsFeature>
  let updatesStore: StoreOf<UpdatesFeature>

  var body: some View {
    Form {
      Section("Automatic Updates") {
        Text("Automatic updates are disabled for this fork.")
          .font(.headline)
        Text("Install future builds manually until a fork-owned update channel is available.")
          .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
    .padding(.top, -20)
    .padding(.leading, -8)
    .padding(.trailing, -6)
    .navigationTitle("Updates")
  }
}
