import SwiftUI

private enum HydrionWatchPalette {
  static let abyss = Color(red: 0x04 / 255, green: 0x24 / 255, blue: 0x3A / 255)
  static let current = Color(red: 0x00 / 255, green: 0x88 / 255, blue: 0xCC / 255)
  static let glow = Color(red: 0x00 / 255, green: 0xD2 / 255, blue: 0xFF / 255)
  static let kelp = Color(red: 0x0E / 255, green: 0x9F / 255, blue: 0x6E / 255)
}

/// The watch app's only screen: a hydration ring mirroring the phone's daily
/// progress, driven entirely by the last snapshot Runner pushed over
/// WatchConnectivity. There is no independent data source, no HealthKit
/// access and no live sensor reading on the watch in this version.
struct ContentView: View {
  @EnvironmentObject private var receiver: HydrationConnectivityReceiver

  var body: some View {
    ZStack {
      HydrionWatchPalette.abyss.ignoresSafeArea()
      if let snapshot = receiver.snapshot {
        HydrationRing(snapshot: snapshot)
      } else {
        WaitingForPhoneView(isReachable: receiver.isReachable)
      }
    }
  }
}

private struct HydrationRing: View {
  let snapshot: HydrationSnapshot

  private var ringColor: Color {
    snapshot.progressFraction >= 1 ? HydrionWatchPalette.kelp : HydrionWatchPalette.glow
  }

  var body: some View {
    VStack(spacing: 6) {
      ZStack {
        Circle()
          .stroke(HydrionWatchPalette.current.opacity(0.25), lineWidth: 10)
        Circle()
          .trim(from: 0, to: snapshot.progressFraction)
          .stroke(
            ringColor,
            style: StrokeStyle(lineWidth: 10, lineCap: .round)
          )
          .rotationEffect(.degrees(-90))
          .animation(.easeOut(duration: 0.6), value: snapshot.progressFraction)
        VStack(spacing: 0) {
          Text("\(snapshot.progressPercent)%")
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
          Text("\(snapshot.todayMl) / \(snapshot.goalMl) ml")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.75))
        }
      }
      .frame(width: 110, height: 110)
      .padding(.top, 4)

      Text(snapshot.status)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.white.opacity(0.85))
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .padding(.horizontal, 8)
    }
  }
}

private struct WaitingForPhoneView: View {
  let isReachable: Bool

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "drop.fill")
        .font(.system(size: 28))
        .foregroundStyle(HydrionWatchPalette.glow)
      Text("Open Hydrion on your iPhone")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
      Text(isReachable ? "iPhone connected — waiting for data" : "iPhone not reachable")
        .font(.system(size: 11))
        .foregroundStyle(.white.opacity(0.6))
        .multilineTextAlignment(.center)
    }
    .padding(.horizontal, 12)
  }
}

#Preview {
  ContentView()
    .environmentObject(HydrationConnectivityReceiver())
}
