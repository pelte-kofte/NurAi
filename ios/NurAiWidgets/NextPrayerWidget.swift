import WidgetKit
import SwiftUI

private let defaultAppGroupId = "group.com.nilico.duaya"
private let payloadKey = "next_prayer_payload"

struct NextPrayerEntry: TimelineEntry {
  let date: Date
  let payload: NextPrayerPayload?
}

struct NextPrayerPayload: Decodable {
  let updatedAtEpochMs: Int64?
  let locationLabel: String?
  let nextPrayerKey: String?
  let nextPrayerLabel: String?
  let nextPrayerTime: String?
  let countdownLabel: String?
  let isNotificationsEnabled: Bool?
}

struct NextPrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> NextPrayerEntry {
    NextPrayerEntry(date: Date(), payload: nil)
  }

  func getSnapshot(in context: Context, completion: @escaping (NextPrayerEntry) -> Void) {
    completion(NextPrayerEntry(date: Date(), payload: loadPayload()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<NextPrayerEntry>) -> Void) {
    let entry = NextPrayerEntry(date: Date(), payload: loadPayload())
    let nextRefresh = Date().addingTimeInterval(15 * 60)
    completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
  }

  private func loadPayload() -> NextPrayerPayload? {
    guard
      let defaults = resolveSharedDefaults(),
      let raw = defaults.string(forKey: payloadKey),
      let data = raw.data(using: .utf8)
    else {
      return nil
    }
    return try? JSONDecoder().decode(NextPrayerPayload.self, from: data)
  }

  private func resolveSharedDefaults() -> UserDefaults? {
    var candidates = [defaultAppGroupId]
    if let bundleId = Bundle.main.bundleIdentifier {
      candidates.append("group.\(bundleId)")
      if let dotIndex = bundleId.lastIndex(of: ".") {
        let baseId = String(bundleId[..<dotIndex])
        candidates.append("group.\(baseId)")
      }
    }
    for suite in candidates {
      if let defaults = UserDefaults(suiteName: suite) {
        return defaults
      }
    }
    return nil
  }
}

struct NextPrayerWidgetView: View {
  let entry: NextPrayerProvider.Entry

  var body: some View {
    if let payload = entry.payload {
      VStack(alignment: .leading, spacing: 8) {
        Text("Next Prayer")
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(.secondary)

        Text(payload.locationLabel?.isEmpty == false ? payload.locationLabel! : "Current")
          .font(.system(size: 11, weight: .regular))
          .foregroundStyle(.primary.opacity(0.7))
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(Color.secondary.opacity(0.12))
          .clipShape(Capsule())

        Text("\(payload.nextPrayerLabel ?? "Prayer") \(payload.nextPrayerTime ?? "--:--")")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(.primary)
          .lineLimit(1)

        Text(payload.countdownLabel ?? "")
          .font(.system(size: 13, weight: .regular))
          .foregroundStyle(.secondary)
          .lineLimit(1)

        if let enabled = payload.isNotificationsEnabled {
          Text(enabled ? "Notifications: ON" : "Notifications: OFF")
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(.secondary.opacity(0.85))
            .lineLimit(1)
        }
      }
      .containerBackground(for: .widget) {
        Color.clear
      }
      .widgetURL(URL(string: "nurai://adhan"))
    } else {
      VStack(alignment: .leading, spacing: 8) {
        Text("Next Prayer")
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(.secondary)
        Text("Open NurAi to update")
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(.primary)
      }
      .containerBackground(for: .widget) {
        Color.clear
      }
      .widgetURL(URL(string: "nurai://adhan"))
    }
  }
}

struct NextPrayerWidget: Widget {
  let kind: String = "NextPrayerWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: NextPrayerProvider()) { entry in
      NextPrayerWidgetView(entry: entry)
    }
    .configurationDisplayName("Next Prayer")
    .description("Shows the upcoming prayer and countdown.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
