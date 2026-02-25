import SwiftUI
import WidgetKit

private let defaultAppGroupId = "group.com.nilico.duaya"
private let payloadKey = "next_prayer_widget_payload"

struct NextPrayerEntry: TimelineEntry {
  let date: Date
  let payload: NextPrayerPayload?
}

struct NextPrayerPayload: Decodable {
  let generatedAtEpochMs: Int64?
  let nextPrayerName: String?
  let nextPrayerTimeEpochMs: Int64?
  let timeZone: String?
  let locationLabel: String?
  let isWidgetEnabled: Bool?
}

struct NextPrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> NextPrayerEntry {
    NextPrayerEntry(date: Date(), payload: nil)
  }

  func getSnapshot(in context: Context, completion: @escaping (NextPrayerEntry) -> Void) {
    completion(NextPrayerEntry(date: Date(), payload: loadPayload()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<NextPrayerEntry>) -> Void) {
    let now = Date()
    let payload = loadPayload()
    let entry = NextPrayerEntry(date: now, payload: payload)

    var nextRefresh = now.addingTimeInterval(20 * 60)
    if
      let payload,
      payload.isWidgetEnabled == true,
      let prayerEpochMs = payload.nextPrayerTimeEpochMs
    {
      let rollover = Date(timeIntervalSince1970: TimeInterval(prayerEpochMs) / 1000.0)
        .addingTimeInterval(10)
      if rollover > now && rollover < nextRefresh {
        nextRefresh = rollover
      }
    }

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
    var candidates: [String] = [defaultAppGroupId]
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
  @Environment(\.widgetFamily) private var family
  let entry: NextPrayerEntry

  private var isEnabled: Bool {
    entry.payload?.isWidgetEnabled == true
  }

  private var prayerName: String {
    entry.payload?.nextPrayerName ?? L("next_prayer_widget_no_data")
  }

  private var locationLabel: String {
    let raw = entry.payload?.locationLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return raw.isEmpty ? L("next_prayer_widget_location_current") : raw
  }

  private var targetDate: Date? {
    guard let epoch = entry.payload?.nextPrayerTimeEpochMs else { return nil }
    return Date(timeIntervalSince1970: TimeInterval(epoch) / 1000.0)
  }

  var body: some View {
    Group {
      if !isEnabled {
        disabledView
      } else if targetDate == nil {
        missingDataView
      } else {
        contentView
      }
    }
    .widgetURL(URL(string: "duaya://adhanTimes"))
    .nurAiWidgetBackground()
  }

  @ViewBuilder
  private var disabledView: some View {
    switch family {
    case .accessoryInline:
      Text(L("next_prayer_widget_enable_short"))
        .lineLimit(1)
    case .accessoryCircular:
      Image(systemName: "moon.stars")
    case .accessoryRectangular:
      Text(L("next_prayer_widget_enable_short"))
        .lineLimit(2)
    default:
      VStack(alignment: .leading, spacing: 6) {
        Text(L("next_prayer_widget_title"))
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(.secondary)
        Text(L("next_prayer_widget_enable_full"))
          .font(.system(size: 14, weight: .medium))
          .lineLimit(3)
      }
    }
  }

  @ViewBuilder
  private var missingDataView: some View {
    switch family {
    case .accessoryInline:
      Text(L("next_prayer_widget_no_data"))
        .lineLimit(1)
    case .accessoryCircular:
      Image(systemName: "location.slash")
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 2) {
        Text(L("next_prayer_widget_title"))
          .font(.system(size: 11, weight: .semibold))
        Text(L("next_prayer_widget_no_data"))
          .font(.system(size: 11, weight: .regular))
          .lineLimit(2)
      }
    default:
      VStack(alignment: .leading, spacing: 6) {
        Text(L("next_prayer_widget_title"))
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(.secondary)
        Text(L("next_prayer_widget_no_data"))
          .font(.system(size: 15, weight: .medium))
          .lineLimit(2)
      }
    }
  }

  @ViewBuilder
  private var contentView: some View {
    switch family {
    case .accessoryInline:
      Text("\(prayerName) \(timeText()) • \(remainingText())")
        .lineLimit(1)
    case .accessoryCircular:
      VStack(spacing: 2) {
        Text(shortPrayerName())
          .font(.system(size: 10, weight: .semibold))
        Text(remainingShortText())
          .font(.system(size: 10, weight: .regular))
      }
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 2) {
        Text("\(prayerName) \(timeText())")
          .font(.system(size: 12, weight: .semibold))
          .lineLimit(1)
        Text(remainingText())
          .font(.system(size: 11, weight: .regular))
          .lineLimit(1)
      }
    default:
      VStack(alignment: .leading, spacing: 8) {
        Text(L("next_prayer_widget_title"))
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(.secondary)
        Text(locationLabel)
          .font(.system(size: 11, weight: .regular))
          .foregroundStyle(.primary.opacity(0.72))
          .lineLimit(1)
        Text("\(prayerName) \(timeText())")
          .font(.system(size: 20, weight: .semibold))
          .lineLimit(1)
        if #available(iOSApplicationExtension 16.0, *), let targetDate {
          Text(timerInterval: Date()...targetDate, countsDown: true)
            .font(.system(size: 14, weight: .regular, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
        } else {
          Text(remainingText())
            .font(.system(size: 14, weight: .regular, design: .rounded))
            .lineLimit(1)
        }
      }
    }
  }

  private func timeText() -> String {
    guard let targetDate else { return "--:--" }
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    formatter.timeZone = widgetTimeZone()
    return formatter.string(from: targetDate)
  }

  private func widgetTimeZone() -> TimeZone {
    if let identifier = entry.payload?.timeZone, let zone = TimeZone(identifier: identifier) {
      return zone
    }
    return .current
  }

  private func remainingText() -> String {
    guard let targetDate else { return L("next_prayer_widget_no_data") }
    let diff = max(0, Int(targetDate.timeIntervalSince(Date())))
    let hours = diff / 3600
    let minutes = (diff % 3600) / 60
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    }
    return "\(minutes)m"
  }

  private func remainingShortText() -> String {
    guard let targetDate else { return "--" }
    let diff = max(0, Int(targetDate.timeIntervalSince(Date())))
    let hours = diff / 3600
    let minutes = (diff % 3600) / 60
    if hours > 0 {
      return "\(hours)h"
    }
    return "\(minutes)m"
  }

  private func shortPrayerName() -> String {
    let trimmed = prayerName.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.count <= 3 { return trimmed }
    return String(trimmed.prefix(3))
  }

  private func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
  }
}

private extension View {
  @ViewBuilder
  func nurAiWidgetBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) {
        Color.clear
      }
    } else {
      background(Color.clear)
    }
  }
}

struct NextPrayerWidget: Widget {
  let kind: String = "NextPrayerWidget"

  private var supportedWidgetFamilies: [WidgetFamily] {
    if #available(iOSApplicationExtension 16.0, *) {
      return [
        .systemSmall,
        .systemMedium,
        .accessoryInline,
        .accessoryCircular,
        .accessoryRectangular,
      ]
    }
    return [
      .systemSmall,
      .systemMedium,
    ]
  }

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: NextPrayerProvider()) { entry in
      NextPrayerWidgetView(entry: entry)
    }
    .configurationDisplayName(NSLocalizedString("next_prayer_widget_title", comment: ""))
    .description(NSLocalizedString("next_prayer_widget_description", comment: ""))
    .supportedFamilies(supportedWidgetFamilies)
  }
}
