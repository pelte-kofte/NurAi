import SwiftUI
import WidgetKit

private let defaultAppGroupId = "group.com.nilico.duaya"
private let payloadKey = "next_prayer_widget_payload"
private let rolloverDriftSeconds: TimeInterval = 10
private let safetyRefreshInterval: TimeInterval = 20 * 60
private let staleDataRefreshInterval: TimeInterval = 5 * 60
private let disabledRefreshInterval: TimeInterval = 3 * 60 * 60
private let lockScreenPeriodicRefreshInterval: TimeInterval = 12 * 60

private func localized(_ key: String, fallback: String) -> String {
  let value = NSLocalizedString(key, comment: "")
  return value == key ? fallback : value
}

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

    // Lock Screen families can lag; force a lightweight periodic check.
    let periodicRefresh = now.addingTimeInterval(lockScreenPeriodicRefreshInterval)
    nextRefresh = min(nextRefresh, periodicRefresh)

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
  @Environment(\.colorScheme) private var colorScheme
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
    selectedPrayer?.name ?? localized("next_prayer_widget_no_data", fallback: "Set location in app")
  }

  private var locationLabel: String {
    let raw = entry.payload?.locationLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return raw.isEmpty ? localized("next_prayer_widget_location_current", fallback: "Current location") : raw
  }

  private var targetDate: Date? {
    selectedPrayer?.date
  }

  private var primaryAccent: Color {
    Color(red: 0.18, green: 0.53, blue: 0.58)
  }

  private var secondaryAccent: Color {
    Color(red: 0.20, green: 0.28, blue: 0.48)
  }

  private var clayAccent: Color {
    Color(red: 0.71, green: 0.48, blue: 0.35)
  }

  private var paperBackground: Color {
    if colorScheme == .dark {
      return Color.white.opacity(0.05)
    }
    return Color(red: 0.98, green: 0.96, blue: 0.92).opacity(0.70)
  }

  private var subtleStroke: Color {
    primaryAccent.opacity(colorScheme == .dark ? 0.45 : 0.26)
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
      HStack(spacing: 4) {
        Image(systemName: "moon.stars.fill")
          .font(.caption2)
        Text(localized("next_prayer_widget_enable_short", fallback: "Enable in Settings"))
          .font(.caption2)
          .lineLimit(1)
      }
    case .accessoryCircular:
      ZStack {
        Circle()
          .fill(paperBackground)
        Circle()
          .stroke(subtleStroke, lineWidth: 1)
        Image(systemName: "moon.stars.fill")
          .font(.caption)
          .foregroundStyle(clayAccent)
      }
    case .accessoryRectangular:
      HStack(spacing: 8) {
        Image(systemName: "moon.stars.fill")
          .font(.caption)
          .foregroundStyle(clayAccent)
        Text(localized("next_prayer_widget_enable_short", fallback: "Enable in Settings"))
          .font(.caption)
          .lineLimit(2)
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 8)
      .background(cardBackground(cornerRadius: 10))
    default:
      VStack(spacing: 8) {
        Image(systemName: "moon.stars.fill")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(clayAccent)
        Text(localized("next_prayer_widget_enable_short", fallback: "Enable in Settings"))
          .font(.caption.weight(.semibold))
          .multilineTextAlignment(.center)
          .lineLimit(2)
      }
      .padding(12)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .homeWidgetSurface(cornerRadius: 12, strokeColor: subtleStroke)
    }
  }

  @ViewBuilder
  private var missingDataView: some View {
    switch family {
    case .accessoryInline:
      HStack(spacing: 4) {
        Image(systemName: "clock.badge.exclamationmark")
          .font(.caption2)
        Text(localized("next_prayer_widget_no_data", fallback: "Set location in app"))
          .font(.caption2)
          .lineLimit(1)
      }
    case .accessoryCircular:
      ZStack {
        Circle()
          .fill(paperBackground)
        Circle()
          .stroke(subtleStroke, lineWidth: 1)
        VStack(spacing: 2) {
          Image(systemName: "location.slash")
            .font(.caption2)
          Text("--")
            .font(.caption2.monospacedDigit())
        }
        .foregroundStyle(.secondary)
      }
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Image(systemName: "clock")
            .font(.caption2)
            .foregroundStyle(primaryAccent)
          Text(localized("next_prayer_widget_title", fallback: "Next Prayer"))
            .font(.caption2.weight(.semibold))
          Spacer(minLength: 0)
        }
        Text(localized("next_prayer_widget_no_data", fallback: "Set location in app"))
          .font(.caption)
          .lineLimit(2)
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 8)
      .background(cardBackground(cornerRadius: 10))
    default:
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 6) {
          Image(systemName: "clock")
            .foregroundStyle(primaryAccent)
          Text(localized("next_prayer_widget_title", fallback: "Next Prayer"))
            .font(.system(size: 12, weight: .semibold))
        }
        Text(localized("next_prayer_widget_no_data", fallback: "Set location in app"))
          .font(.system(size: 15, weight: .medium))
          .lineLimit(2)
      }
      .padding(10)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .background(cardBackground(cornerRadius: 12))
    }
  }

  @ViewBuilder
  private var refreshingView: some View {
    switch family {
    case .accessoryInline:
      HStack(spacing: 4) {
        Image(systemName: "arrow.clockwise")
          .font(.caption2)
        Text(localized("next_prayer_widget_refreshing", fallback: "Updating"))
          .font(.caption2)
          .lineLimit(1)
      }
    case .accessoryCircular:
      ZStack {
        Circle()
          .fill(paperBackground)
        Circle()
          .stroke(subtleStroke, lineWidth: 1)
        Image(systemName: "arrow.clockwise")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Image(systemName: "clock")
            .font(.caption2)
            .foregroundStyle(primaryAccent)
          Text(localized("next_prayer_widget_title", fallback: "Next Prayer"))
            .font(.caption2.weight(.semibold))
          Spacer(minLength: 0)
        }
        Text(localized("next_prayer_widget_refreshing", fallback: "Updating"))
          .font(.caption)
          .lineLimit(2)
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 8)
      .background(cardBackground(cornerRadius: 10))
    default:
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 6) {
          Image(systemName: "clock")
            .foregroundStyle(primaryAccent)
          Text(localized("next_prayer_widget_title", fallback: "Next Prayer"))
            .font(.system(size: 12, weight: .semibold))
        }
        Text(localized("next_prayer_widget_refreshing", fallback: "Updating"))
          .font(.system(size: 15, weight: .medium))
          .lineLimit(2)
      }
      .padding(10)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .background(cardBackground(cornerRadius: 12))
    }
  }

  @ViewBuilder
  private var contentView: some View {
    switch family {
    case .accessoryInline:
      HStack(spacing: 4) {
        Image(systemName: "moon.stars.fill")
          .font(.caption2)
          .foregroundStyle(clayAccent)
        Text("\(prayerName) • \(inlineRightText())")
          .font(.caption)
          .lineLimit(1)
      }
    case .accessoryCircular:
      ZStack {
        Circle()
          .fill(paperBackground)
        Circle()
          .stroke(subtleStroke, lineWidth: 2)
        Circle()
          .trim(from: 0, to: progressFraction())
          .stroke(
            AngularGradient(
              gradient: Gradient(colors: [secondaryAccent.opacity(0.8), primaryAccent, clayAccent]),
              center: .center
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
          )
          .rotationEffect(.degrees(-90))
        Image(systemName: "sparkles")
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(.secondary.opacity(0.22))
          .offset(y: -11)
        Text(remainingShortTextRounded())
          .font(.caption2.monospacedDigit().weight(.semibold))
          .lineLimit(1)
      }
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 5) {
        HStack(spacing: 6) {
          Image(systemName: "clock")
            .font(.caption2)
            .foregroundStyle(primaryAccent)
          Text(localized("next_prayer_widget_title", fallback: "Next Prayer"))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
          Spacer(minLength: 6)
          Text(timeText())
            .font(.caption.monospacedDigit())
            .foregroundStyle(.primary)
        }
        Text(prayerName)
          .font(.subheadline.weight(.semibold))
          .lineLimit(1)
        if #available(iOSApplicationExtension 16.0, *), let targetDate {
          Text(timerInterval: Date()...targetDate, countsDown: true)
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        } else {
          Text(remainingPrefixText())
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        Rectangle()
          .fill(
            LinearGradient(
              colors: [primaryAccent.opacity(0.45), secondaryAccent.opacity(0.35)],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .frame(height: 1)
          .cornerRadius(1)
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 8)
      .background(cardBackground(cornerRadius: 10))
    case .systemSmall:
      VStack(alignment: .leading, spacing: 7) {
        HStack(spacing: 6) {
          Image(systemName: "clock")
            .font(.caption)
            .foregroundStyle(primaryAccent)
          Text(localized("next_prayer_widget_title", fallback: "Next Prayer"))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
          Spacer(minLength: 0)
          Text(timeText())
            .font(.caption.monospacedDigit().weight(.semibold))
            .foregroundStyle(.primary)
        }
        Text(prayerName)
          .font(.title3.weight(.semibold))
          .lineLimit(1)
        if #available(iOSApplicationExtension 16.0, *), let targetDate {
          Text(timerInterval: Date()...targetDate, countsDown: true)
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)
            .lineLimit(1)
        } else {
          Text(remainingPrefixText(nowLabel: false))
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
      .padding(12)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .homeWidgetSurface(cornerRadius: 12, strokeColor: subtleStroke)
    default:
      HStack(alignment: .top, spacing: 14) {
        VStack(alignment: .leading, spacing: 6) {
          HStack(spacing: 6) {
            Image(systemName: "clock")
              .font(.caption)
              .foregroundStyle(primaryAccent)
            Text(localized("next_prayer_widget_title", fallback: "Next Prayer"))
              .font(.caption.weight(.semibold))
              .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(timeText())
              .font(.caption.monospacedDigit())
          }
          Text(prayerName)
            .font(.title3.weight(.semibold))
            .lineLimit(1)
          if #available(iOSApplicationExtension 16.0, *), let targetDate {
            Text(timerInterval: Date()...targetDate, countsDown: true)
              .font(.subheadline.monospacedDigit())
              .foregroundStyle(.secondary)
              .lineLimit(1)
          } else {
            Text(remainingPrefixText(nowLabel: false))
              .font(.subheadline.monospacedDigit())
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
        VStack(alignment: .trailing, spacing: 4) {
          Text(localized("next_prayer_widget_title", fallback: "Next"))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
          let trimmedLocation = locationLabel.trimmingCharacters(in: .whitespacesAndNewlines)
          if !trimmedLocation.isEmpty {
            Text(trimmedLocation)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          } else {
            Text(timeZoneShortLabel())
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
          HStack(spacing: 4) {
            Image(systemName: "sun.max.fill")
              .font(.caption2)
              .foregroundStyle(clayAccent.opacity(0.85))
            Text(localized("next_prayer_widget_title", fallback: "Next"))
              .font(.caption2)
              .foregroundStyle(.secondary.opacity(0.95))
          }
        }
      }
      .padding(12)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .homeWidgetSurface(cornerRadius: 14, strokeColor: subtleStroke)
    }
  }

  private func cardBackground(cornerRadius: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
      .fill(paperBackground)
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .stroke(subtleStroke, lineWidth: 1)
      )
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

  private func inlineRightText() -> String {
    if targetDate == nil {
      return localized("next_prayer_widget_no_data", fallback: "Set location")
    }
    return remainingShortTextRounded()
  }

  private func remainingPrefixText(nowLabel: Bool = true) -> String {
    let fallback = localized("next_prayer_widget_no_data", fallback: "No data")
    guard let targetDate else { return fallback }
    let diff = max(0, Int(targetDate.timeIntervalSince(Date())))
    if diff < 60 {
      return nowLabel ? "Now" : "0m"
    }
    let hours = diff / 3600
    let minutes = (diff % 3600) / 60
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    }
    return "\(minutes)m"
  }

  private func remainingShortTextRounded() -> String {
    guard let targetDate else { return "--" }
    let diff = max(0, Int(targetDate.timeIntervalSince(Date())))
    if diff < 60 { return "0m" }
    if diff >= 3600 {
      let roundedHours = Int((Double(diff) / 3600.0).rounded(.toNearestOrAwayFromZero))
      return "\(max(1, roundedHours))h"
    }
    let minutes = max(1, diff / 60)
    return "\(minutes)m"
  }

  private func progressFraction() -> CGFloat {
    guard let targetDate else { return 0.12 }
    let totalWindowSeconds: CGFloat = 6 * 60 * 60
    let remaining = max(0, CGFloat(targetDate.timeIntervalSince(Date())))
    let normalized = 1 - min(1, remaining / totalWindowSeconds)
    return max(0.1, normalized)
  }

  private func timeZoneShortLabel() -> String {
    let zone = widgetTimeZone()
    if let abbr = zone.abbreviation(for: Date()), !abbr.isEmpty {
      return abbr
    }
    return zone.identifier
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

  @ViewBuilder
  func homeWidgetSurface(cornerRadius: CGFloat, strokeColor: Color) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self
        .containerBackground(.fill.tertiary, for: .widget)
        .overlay(
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(strokeColor, lineWidth: 1)
        )
    } else {
      self
        .background(
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.08))
            .overlay(
              RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(strokeColor, lineWidth: 1)
            )
        )
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
    .configurationDisplayName(localized("next_prayer_widget_title", fallback: "Next Prayer"))
    .description(localized("next_prayer_widget_description", fallback: "Shows next prayer time and remaining time."))
    .supportedFamilies(supportedWidgetFamilies)
  }
}
