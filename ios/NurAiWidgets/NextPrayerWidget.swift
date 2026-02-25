import SwiftUI
import WidgetKit

private let defaultAppGroupId = "group.com.nilico.duaya"
private let payloadKey = "next_prayer_widget_payload"
private let rolloverDriftSeconds: TimeInterval = 10
private let safetyRefreshInterval: TimeInterval = 20 * 60
private let staleDataRefreshInterval: TimeInterval = 5 * 60
private let disabledRefreshInterval: TimeInterval = 3 * 60 * 60

struct NextPrayerEntry: TimelineEntry {
  let date: Date
  let payload: NextPrayerPayload?
}

struct UpcomingPrayerPayload: Decodable {
  let name: String?
  let timeEpochMs: Int64?
}

struct NextPrayerPayload: Decodable {
  let generatedAtEpochMs: Int64?
  let nextPrayerName: String?
  let nextPrayerTimeEpochMs: Int64?
  let timeZone: String?
  let locationLabel: String?
  let isWidgetEnabled: Bool?
  let upcomingPrayers: [UpcomingPrayerPayload]?
}

struct ResolvedPrayer {
  let name: String
  let date: Date
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

    var nextRefresh: Date
    if payload?.isWidgetEnabled != true {
      nextRefresh = now.addingTimeInterval(disabledRefreshInterval)
    } else if let nextPrayer = resolveNextPrayer(payload: payload, now: now) {
      let boundaryRefresh = nextPrayer.date.addingTimeInterval(rolloverDriftSeconds)
      let safetyRefresh = now.addingTimeInterval(safetyRefreshInterval)
      nextRefresh = min(boundaryRefresh, safetyRefresh)
      if nextRefresh <= now {
        nextRefresh = now.addingTimeInterval(staleDataRefreshInterval)
      }
    } else {
      nextRefresh = now.addingTimeInterval(staleDataRefreshInterval)
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

  private var hasPrayerSourceData: Bool {
    if let upcoming = entry.payload?.upcomingPrayers, !upcoming.isEmpty {
      return true
    }
    if let legacyEpoch = entry.payload?.nextPrayerTimeEpochMs, legacyEpoch > 0 {
      return true
    }
    return false
  }

  private var selectedPrayer: ResolvedPrayer? {
    resolveNextPrayer(payload: entry.payload, now: Date())
  }

  private var prayerName: String {
    selectedPrayer?.name ?? L("next_prayer_widget_no_data")
  }

  private var locationLabel: String {
    let raw = entry.payload?.locationLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return raw.isEmpty ? L("next_prayer_widget_location_current") : raw
  }

  private var targetDate: Date? {
    selectedPrayer?.date
  }

  var body: some View {
    Group {
      if !isEnabled {
        disabledView
      } else if targetDate != nil {
        contentView
      } else if hasPrayerSourceData {
        refreshingView
      } else {
        missingDataView
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
  private var refreshingView: some View {
    switch family {
    case .accessoryInline:
      Text(L("next_prayer_widget_refreshing"))
        .lineLimit(1)
    case .accessoryCircular:
      Image(systemName: "arrow.clockwise")
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 2) {
        Text(L("next_prayer_widget_title"))
          .font(.system(size: 11, weight: .semibold))
        Text(L("next_prayer_widget_refreshing"))
          .font(.system(size: 11, weight: .regular))
          .lineLimit(2)
      }
    default:
      VStack(alignment: .leading, spacing: 6) {
        Text(L("next_prayer_widget_title"))
          .font(.system(size: 12, weight: .regular))
          .foregroundStyle(.secondary)
        Text(L("next_prayer_widget_refreshing"))
          .font(.system(size: 15, weight: .medium))
          .lineLimit(2)
      }
    }
  }

  @ViewBuilder
  private var contentView: some View {
    switch family {
    case .accessoryInline:
      Text("\(prayerName) \(timeText()) | \(remainingText())")
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

private func resolveNextPrayer(payload: NextPrayerPayload?, now: Date) -> ResolvedPrayer? {
  guard let payload, payload.isWidgetEnabled == true else { return nil }

  let threshold = now.addingTimeInterval(rolloverDriftSeconds)
  let fromUpcoming: [ResolvedPrayer] =
    (payload.upcomingPrayers ?? []).compactMap { item in
      guard
        let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines),
        !name.isEmpty,
        let epochMs = item.timeEpochMs
      else {
        return nil
      }
      let date = Date(timeIntervalSince1970: TimeInterval(epochMs) / 1000.0)
      return ResolvedPrayer(name: name, date: date)
    }

  let sortedUpcoming = fromUpcoming.sorted { $0.date < $1.date }
  if let next = sortedUpcoming.first(where: { $0.date > threshold }) {
    return next
  }

  if
    let name = payload.nextPrayerName?.trimmingCharacters(in: .whitespacesAndNewlines),
    !name.isEmpty,
    let legacyEpochMs = payload.nextPrayerTimeEpochMs
  {
    let legacyDate = Date(timeIntervalSince1970: TimeInterval(legacyEpochMs) / 1000.0)
    if legacyDate > threshold {
      return ResolvedPrayer(name: name, date: legacyDate)
    }
  }

  return nil
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
