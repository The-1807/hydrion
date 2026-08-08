import SwiftUI
import WidgetKit

private let appGroup = "group.com.the1807.hydrion"
private let widgetKind = "HydrionDailyProgressWidget"

struct HydrionProgressEntry: TimelineEntry {
    let date: Date
    let todayMl: Int
    let goalMl: Int
    let percent: Int
    let status: String
    let isPlaceholder: Bool
    let isStale: Bool
}

struct HydrionProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> HydrionProgressEntry {
        HydrionProgressEntry(date: Date(), todayMl: 0, goalMl: 0, percent: 0,
                             status: "Open Hydrion to load progress", isPlaceholder: true, isStale: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (HydrionProgressEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HydrionProgressEntry>) -> Void) {
        let entry = loadEntry()
        let now = Date()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadEntry() -> HydrionProgressEntry {
        guard let defaults = UserDefaults(suiteName: appGroup),
              defaults.integer(forKey: "snapshot_schema") == 1,
              defaults.object(forKey: "snapshot_updated_at") != nil else {
            return HydrionProgressEntry(date: Date(), todayMl: 0, goalMl: 0, percent: 0,
                                        status: "Open Hydrion to load progress", isPlaceholder: true, isStale: false)
        }
        let updated = Date(timeIntervalSince1970: defaults.double(forKey: "snapshot_updated_at") / 1000)
        let stale = Date().timeIntervalSince(updated) > 6 * 60 * 60 || !Calendar.current.isDate(updated, inSameDayAs: Date())
        return HydrionProgressEntry(
            date: updated,
            todayMl: defaults.integer(forKey: "today_ml"),
            goalMl: defaults.integer(forKey: "goal_ml"),
            percent: defaults.integer(forKey: "progress_percent"),
            status: stale ? "Open Hydrion to refresh" : (defaults.string(forKey: "status") ?? "Open Hydrion"),
            isPlaceholder: false,
            isStale: stale
        )
    }
}

struct HydrionProgressView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HydrionProgressEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hydrion").font(.headline)
            if entry.isPlaceholder {
                Text(entry.status).font(.caption).foregroundColor(.secondary)
            } else {
                ProgressView(value: Double(min(entry.percent, 100)), total: 100)
                    .accessibilityLabel("Daily hydration progress")
                    .accessibilityValue("\(entry.percent) percent")
                Text("\(entry.todayMl) / \(entry.goalMl) mL")
                    .font(family == .systemSmall ? .headline : .title3)
                    .minimumScaleFactor(0.75)
                Text(entry.status).font(.caption).foregroundColor(.secondary).lineLimit(2)
            }
        }
        .widgetURL(URL(string: "hydrion://home"))
        .hydrionWidgetBackground()
        .accessibilityElement(children: .combine)
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }
}

private extension View {
    @ViewBuilder
    func hydrionWidgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(.background, for: .widget)
        } else {
            background(Color(UIColor.systemBackground))
        }
    }
}

@main
struct HydrionWidgets: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: widgetKind, provider: HydrionProgressProvider()) { entry in
            HydrionProgressView(entry: entry)
        }
        .configurationDisplayName("Daily Progress")
        .description("See hydration progress without exposing profile or health details.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
