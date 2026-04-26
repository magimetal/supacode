import ComposableArchitecture
import SwiftUI

struct UpdateCommands: Commands {
  let store: StoreOf<UpdatesFeature>

  var body: some Commands {
    EmptyCommands()
  }
}
