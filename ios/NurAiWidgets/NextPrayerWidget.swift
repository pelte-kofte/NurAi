import SwiftUI
import WidgetKit

private let defaultAppGroupId = "group.com.nilico.duaya"
private let payloadKey = "next_prayer_widget_payload"
private let rolloverDriftSeconds: TimeInterval = 10
private let safetyRefreshInterval: TimeInterval = 20 * 60
private let staleDataRefreshInterval: TimeInterval = 5 * 60
private let disabledRefreshInterval: TimeInterval = 3 * 60 * 60
private let lockScreenPeriodicRefreshInterval: TimeInterval = 12 * 60

private func debugLog(_ message: String) {
  #if DEBUG
    print(message)
  #endif
}

private func localized(_ key: String, fallback: String, languageCode: String? = nil) -> String {
  if
    let languageCode,
    let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
    let bundle = Bundle(path: path)
  {
    let value = bundle.localizedString(forKey: key, value: fallback, table: nil)
    return value == key ? fallback : value
  }
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
  let lang: String?
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
    if let nextPrayer = resolveNextPrayer(payload: payload, now: now) {
      let boundaryRefresh = nextPrayer.date.addingTimeInterval(rolloverDriftSeconds)
      let safetyRefresh = now.addingTimeInterval(safetyRefreshInterval)
      nextRefresh = min(boundaryRefresh, safetyRefresh)
      if nextRefresh <= now {
        nextRefresh = now.addingTimeInterval(staleDataRefreshInterval)
      }
      debugLog(
        "[NextPrayerWidget] timeline_next_prayer now=\(now.timeIntervalSince1970) "
          + "prayer=\(nextPrayer.name) nextPrayer=\(nextPrayer.date.timeIntervalSince1970) "
          + "boundaryRefresh=\(boundaryRefresh.timeIntervalSince1970)"
      )
    } else {
      nextRefresh = now.addingTimeInterval(staleDataRefreshInterval)
      debugLog(
        "[NextPrayerWidget] timeline_no_resolved_prayer now=\(now.timeIntervalSince1970) "
          + "hasPayload=\(payload != nil) hasUpcoming=\(!((payload?.upcomingPrayers ?? []).isEmpty))"
      )
    }

    let midnightRefresh = nextMidnight(after: now, payload: payload)
    nextRefresh = min(nextRefresh, midnightRefresh)

    // Lock Screen families can lag; force a lightweight periodic check.
    let periodicRefresh = now.addingTimeInterval(lockScreenPeriodicRefreshInterval)
    nextRefresh = min(nextRefresh, periodicRefresh)

    debugLog(
      "[NextPrayerWidget] timeline_ready now=\(now.timeIntervalSince1970) "
        + "nextRefresh=\(nextRefresh.timeIntervalSince1970) midnightRefresh=\(midnightRefresh.timeIntervalSince1970)"
    )

    completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
  }

  private func loadPayload() -> NextPrayerPayload? {
    guard
      let defaults = resolveSharedDefaults(),
      let raw = defaults.string(forKey: payloadKey),
      let data = raw.data(using: .utf8)
    else {
      debugLog("[NextPrayerWidget] load_payload missing_shared_data")
      return nil
    }
    let payload = try? JSONDecoder().decode(NextPrayerPayload.self, from: data)
    debugLog(
      "[NextPrayerWidget] load_payload generatedAt=\(payload?.generatedAtEpochMs ?? -1) "
        + "nextPrayerEpochMs=\(payload?.nextPrayerTimeEpochMs ?? -1) "
        + "upcomingCount=\(payload?.upcomingPrayers?.count ?? 0)"
    )
    return payload
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

  private func nextMidnight(after now: Date, payload: NextPrayerPayload?) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = widgetTimeZone(from: payload)
    let startOfToday = calendar.startOfDay(for: now)
    let midnight = calendar.date(byAdding: .day, value: 1, to: startOfToday)
      ?? now.addingTimeInterval(6 * 60 * 60)
    return midnight.addingTimeInterval(rolloverDriftSeconds)
  }

  private func widgetTimeZone(from payload: NextPrayerPayload?) -> TimeZone {
    if let identifier = payload?.timeZone, let zone = TimeZone(identifier: identifier) {
      return zone
    }
    return .current
  }
}

struct NextPrayerWidgetView: View {
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var colorScheme
  let entry: NextPrayerEntry

  private var hasPayload: Bool {
    entry.payload != nil
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
    selectedPrayer?.name ?? localized("next_prayer_widget_no_data", fallback: "Set location in app", languageCode: payloadLanguageCode)
  }

  private var locationLabel: String {
    entry.payload?.locationLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
  }

  private var targetDate: Date? {
    selectedPrayer?.date
  }

  private var shortTitleText: String {
    if isTurkishLanguage() {
      return "Sıradaki"
    }
    return localized(
      "next_prayer_title_short",
      fallback: localized("next_prayer_widget_title", fallback: "Next Prayer", languageCode: payloadLanguageCode),
      languageCode: payloadLanguageCode
    )
  }

  private var primaryAccent: Color {
    Color(red: 0.18, green: 0.53, blue: 0.58)
  }

  private var clayAccent: Color {
    Color(red: 0.71, green: 0.48, blue: 0.35)
  }

  private var paperBackground: Color {
    if colorScheme == .dark {
      return Color.white.opacity(0.05)
    }
    return Color.white.opacity(0.60)
  }

  var body: some View {
    Group {
      if targetDate != nil {
        contentView
      } else if hasPrayerSourceData {
        refreshingView
      } else if hasPayload {
        missingDataView
      } else {
        loadingView
      }
    }
    .widgetURL(URL(string: "duaya://adhanTimes"))
    .nurAiWidgetBackground()
  }

  @ViewBuilder
  private var loadingView: some View {
    switch family {
    case .accessoryInline:
      HStack(spacing: 4) {
        Image(systemName: "arrow.clockwise")
          .font(.caption2)
        Text(localized("widget_loading", fallback: "Loading...", languageCode: payloadLanguageCode))
          .font(.caption2)
          .lineLimit(1)
      }
    case .accessoryCircular:
      ZStack {
        Image(systemName: "arrow.clockwise")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 6) {
        accessoryHeader(icon: "arrow.clockwise")
        Text(localized("widget_loading", fallback: "Loading...", languageCode: payloadLanguageCode))
          .font(.system(size: 13, weight: .medium))
          .lineLimit(2)
          .minimumScaleFactor(0.8)
          .truncationMode(.tail)
      }
    default:
      VStack(spacing: 8) {
        Image(systemName: "arrow.clockwise")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(clayAccent)
        Text(localized("widget_loading", fallback: "Loading...", languageCode: payloadLanguageCode))
          .font(.caption.weight(.semibold))
          .multilineTextAlignment(.center)
          .lineLimit(2)
      }
      .padding(12)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .homeWidgetSurface(cornerRadius: 16)
    }
  }

  @ViewBuilder
  private var missingDataView: some View {
    switch family {
    case .accessoryInline:
      HStack(spacing: 4) {
        Image(systemName: "clock.badge.exclamationmark")
          .font(.caption2)
        Text(localized("next_prayer_widget_no_data", fallback: "Set location in app", languageCode: payloadLanguageCode))
          .font(.caption2)
          .lineLimit(1)
      }
    case .accessoryCircular:
      ZStack {
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
        accessoryHeader(icon: "location.slash")
        Text(localized("next_prayer_widget_no_data", fallback: "Set location in app", languageCode: payloadLanguageCode))
          .font(.system(size: 13, weight: .medium))
          .lineLimit(2)
          .minimumScaleFactor(0.8)
          .truncationMode(.tail)
      }
    default:
      VStack(alignment: .leading, spacing: 8) {
        homeHeader(icon: "clock")
        Text(localized("next_prayer_widget_no_data", fallback: "Set location in app", languageCode: payloadLanguageCode))
          .font(.system(size: 15, weight: .medium))
          .lineLimit(2)
          .minimumScaleFactor(0.8)
          .truncationMode(.tail)
      }
      .padding(14)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .homeWidgetSurface(cornerRadius: 18)
    }
  }

  @ViewBuilder
  private var refreshingView: some View {
    switch family {
    case .accessoryInline:
      HStack(spacing: 4) {
        Image(systemName: "arrow.clockwise")
          .font(.caption2)
        Text(localized("next_prayer_widget_refreshing", fallback: "Updating", languageCode: payloadLanguageCode))
          .font(.caption2)
          .lineLimit(1)
      }
    case .accessoryCircular:
      ZStack {
        Image(systemName: "arrow.clockwise")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 4) {
        accessoryHeader(icon: "arrow.clockwise")
        Text(localized("next_prayer_widget_refreshing", fallback: "Updating", languageCode: payloadLanguageCode))
          .font(.system(size: 13, weight: .medium))
          .lineLimit(2)
          .minimumScaleFactor(0.8)
          .truncationMode(.tail)
      }
    default:
      VStack(alignment: .leading, spacing: 8) {
        homeHeader(icon: "clock")
        Text(localized("next_prayer_widget_refreshing", fallback: "Updating", languageCode: payloadLanguageCode))
          .font(.system(size: 15, weight: .medium))
          .lineLimit(2)
          .minimumScaleFactor(0.8)
          .truncationMode(.tail)
      }
      .padding(14)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .homeWidgetSurface(cornerRadius: 18)
    }
  }

  @ViewBuilder
  private var contentView: some View {
    switch family {
    case .accessoryInline:
      HStack(spacing: 3) {
        Image(systemName: prayerSymbolName())
          .font(.caption2)
          .foregroundStyle(clayAccent)
        Text(prayerName)
          .font(.caption)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .truncationMode(.tail)
        Text("•")
          .font(.caption2)
          .foregroundStyle(.secondary)
        Text(inlineRightText())
          .font(.caption.monospacedDigit())
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .truncationMode(.tail)
      }
    case .accessoryCircular:
      VStack(spacing: 2) {
        Image(systemName: prayerSymbolName())
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(clayAccent)
        Text(remainingShortTextRounded())
          .font(.system(size: 11, weight: .bold, design: .rounded).monospacedDigit())
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .center, spacing: 8) {
          accessoryHeader(icon: prayerSymbolName())
          Spacer(minLength: 6)
          Text(timeText())
            .font(.system(size: 13, weight: .medium, design: .rounded).monospacedDigit())
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .truncationMode(.tail)
        }
        Text(prayerName)
          .font(.system(size: 17, weight: .semibold, design: .rounded))
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .truncationMode(.tail)
        rectangularRemainingText
      }
    case .systemSmall:
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .center, spacing: 8) {
          homeHeader(icon: prayerSymbolName())
          Spacer(minLength: 4)
          Text(timeText())
            .font(.system(size: 14, weight: .medium, design: .rounded).monospacedDigit())
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .truncationMode(.tail)
        }
        Spacer(minLength: 0)
        Text(prayerName)
          .font(.system(size: 24, weight: .semibold, design: .rounded))
          .lineLimit(1)
          .minimumScaleFactor(0.72)
          .truncationMode(.tail)
        shortCountdownText
          .font(.system(size: 15, weight: .medium, design: .rounded).monospacedDigit())
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .truncationMode(.tail)
        if !locationLabel.isEmpty {
          Text(locationLabel)
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .truncationMode(.tail)
        }
      }
      .padding(14)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .homeWidgetSurface(cornerRadius: 18)
    case .systemMedium:
      VStack(alignment: .leading, spacing: 12) {
        HStack(alignment: .center, spacing: 10) {
          homeHeader(icon: prayerSymbolName())
          Spacer(minLength: 8)
          Text(timeText())
            .font(.system(size: 16, weight: .medium, design: .rounded).monospacedDigit())
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .truncationMode(.tail)
        }
        HStack(alignment: .bottom, spacing: 12) {
          VStack(alignment: .leading, spacing: 6) {
            Text(prayerName)
              .font(.system(size: 28, weight: .semibold, design: .rounded))
              .lineLimit(1)
              .minimumScaleFactor(0.75)
              .truncationMode(.tail)
            shortCountdownText
              .font(.system(size: 17, weight: .medium, design: .rounded).monospacedDigit())
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .minimumScaleFactor(0.8)
              .truncationMode(.tail)
          }
          Spacer(minLength: 8)
          VStack(alignment: .trailing, spacing: 6) {
            if !locationLabel.isEmpty {
              Text(locationLabel)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .truncationMode(.tail)
            }
            HStack(spacing: 4) {
              Image(systemName: "globe.europe.africa.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(clayAccent.opacity(0.9))
              Text(timeZoneShortLabel())
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .truncationMode(.tail)
            }
          }
        }
      }
      .padding(16)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .homeWidgetSurface(cornerRadius: 20)
    default:
      EmptyView()
    }
  }

  private var shortCountdownText: some View {
    Group {
      if #available(iOSApplicationExtension 16.0, *), let targetDate {
        Text(timerInterval: Date()...targetDate, countsDown: true)
      } else {
        Text(remainingPrefixText(nowLabel: false))
      }
    }
  }

  private var rectangularRemainingText: some View {
    Group {
      if #available(iOSApplicationExtension 16.0, *), let targetDate {
        Text(timerInterval: Date()...targetDate, countsDown: true)
      } else {
        Text(remainingPrefixText())
      }
    }
    .font(.system(size: 12, weight: .medium, design: .rounded).monospacedDigit())
    .foregroundStyle(.secondary)
    .lineLimit(1)
    .minimumScaleFactor(0.8)
    .truncationMode(.tail)
  }

  private func accessoryHeader(icon: String) -> some View {
    HStack(spacing: 6) {
      Image(systemName: icon)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(clayAccent)
      Text(shortTitleText)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .truncationMode(.tail)
    }
  }

  private func homeHeader(icon: String) -> some View {
    HStack(spacing: 6) {
      Image(systemName: icon)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(clayAccent)
      Text(shortTitleText)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .truncationMode(.tail)
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

  private func inlineRightText() -> String {
    if targetDate == nil {
      return localized("next_prayer_widget_no_data", fallback: "Set location", languageCode: payloadLanguageCode)
    }
    guard let targetDate else { return "--" }
    let diff = max(0, Int(targetDate.timeIntervalSince(Date())))
    if diff >= 90 * 60 {
      return timeText()
    }
    return remainingShortTextRounded()
  }

  private func remainingPrefixText(nowLabel: Bool = true) -> String {
    let fallback = localized("next_prayer_widget_no_data", fallback: "No data", languageCode: payloadLanguageCode)
    guard let targetDate else { return fallback }
    let diff = max(0, Int(targetDate.timeIntervalSince(Date())))
    if diff < 60 {
      return nowLabel
        ? localized("next_prayer_widget_now", fallback: "Now", languageCode: payloadLanguageCode)
        : localizedMinuteText(0)
    }
    let hours = diff / 3600
    let minutes = (diff % 3600) / 60
    if hours > 0 {
      if minutes > 0 {
        return "\(localizedHourText(hours)) \(localizedMinuteText(minutes))\(localizedRemainingSuffix())"
      }
      return "\(localizedHourText(hours))\(localizedRemainingSuffix())"
    }
    return "\(localizedMinuteText(minutes))\(localizedRemainingSuffix())"
  }

  private func prayerSymbolName() -> String {
    let lowered = prayerName.lowercased()
    if lowered.contains("imsak") || lowered.contains("fajr") || lowered.contains("sabah") {
      return "moon.stars.fill"
    }
    if lowered.contains("aksam") || lowered.contains("akşam") || lowered.contains("maghrib")
      || lowered.contains("isha") || lowered.contains("yatsi") || lowered.contains("yatsı")
    {
      return "moon.stars.fill"
    }
    if lowered.contains("gunes") || lowered.contains("güneş") || lowered.contains("sunrise") {
      return "sun.max.fill"
    }
    return "clock"
  }

  private func remainingShortTextRounded() -> String {
    guard let targetDate else { return "--" }
    let diff = max(0, Int(targetDate.timeIntervalSince(Date())))
    if diff < 60 { return localizedMinuteText(0) }
    if diff >= 3600 {
      let roundedHours = Int((Double(diff) / 3600.0).rounded(.toNearestOrAwayFromZero))
      return localizedHourText(max(1, roundedHours))
    }
    let minutes = max(1, diff / 60)
    return localizedMinuteText(minutes)
  }

  private func localizedHourText(_ value: Int) -> String {
    if isTurkishLanguage() {
      return "\(value) sa"
    }
    return "\(value)h"
  }

  private func localizedMinuteText(_ value: Int) -> String {
    if isTurkishLanguage() {
      return "\(value) dk"
    }
    return "\(value)m"
  }

  private func localizedRemainingSuffix() -> String {
    if isTurkishLanguage() {
      return " \(localized("next_prayer_widget_remaining_suffix", fallback: "kaldı", languageCode: payloadLanguageCode))"
    }
    return ""
  }

  private var payloadLanguageCode: String? {
    let trimmed = entry.payload?.lang?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let trimmed, !trimmed.isEmpty {
      return trimmed.lowercased()
    }
    return nil
  }

  private func isTurkishLanguage() -> Bool {
    (payloadLanguageCode ?? Locale.current.languageCode ?? "").lowercased() == "tr"
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
  guard let payload else { return nil }

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
    debugLog(
      "[NextPrayerWidget] resolve_next_prayer source=upcoming now=\(now.timeIntervalSince1970) "
        + "selected=\(next.name) selectedEpoch=\(next.date.timeIntervalSince1970)"
    )
    return next
  }

  if
    let name = payload.nextPrayerName?.trimmingCharacters(in: .whitespacesAndNewlines),
    !name.isEmpty,
    let legacyEpochMs = payload.nextPrayerTimeEpochMs
  {
    let legacyDate = Date(timeIntervalSince1970: TimeInterval(legacyEpochMs) / 1000.0)
    if legacyDate > threshold {
      debugLog(
        "[NextPrayerWidget] resolve_next_prayer source=legacy now=\(now.timeIntervalSince1970) "
          + "selected=\(name) selectedEpoch=\(legacyDate.timeIntervalSince1970)"
      )
      return ResolvedPrayer(name: name, date: legacyDate)
    }
  }

  debugLog(
    "[NextPrayerWidget] resolve_next_prayer none now=\(now.timeIntervalSince1970) "
      + "generatedAt=\(payload.generatedAtEpochMs ?? -1) upcomingCount=\(payload.upcomingPrayers?.count ?? 0)"
  )
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
  func homeWidgetSurface(cornerRadius: CGFloat) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self
        .containerBackground(.fill.tertiary, for: .widget)
    } else {
      self
        .background(
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.08))
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
