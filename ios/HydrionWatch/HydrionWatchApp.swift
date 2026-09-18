import SwiftUI

@main
struct HydrionWatchApp: App {
  @StateObject private var receiver = HydrationConnectivityReceiver()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(receiver)
    }
  }
}
