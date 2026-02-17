import Foundation
import SwiftUI
import WidgetKit

private let defaultAppGroupId = "group.com.nilico.duaya"
private let dailyContentPayloadKey = "daily_content_payload"

struct DailyContentPayload: Decodable {
  struct Item: Decodable {
    let title: String?
    let text: String?
    let ref: String?
  }

  struct AsmaItem: Decodable {
    let name: String?
    let meaning: String?
  }

  let schema: Int?
  let lang: String?
  let date: String?
  let verse: Item?
  let hadith: Item?
  let asma: AsmaItem?
  let updatedAt: Int64?
}

struct DailyContentEntry: TimelineEntry {
  let date: Date
  let configuration: DailyWidgetConfigurationIntent
  let payload: DailyContentPayload?
}

struct DailyContentProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> DailyContentEntry {
    DailyContentEntry(
      date: Date(),
      configuration: DailyWidgetConfigurationIntent(),
      payload: nil
    )
  }

  func snapshot(
    for configuration: DailyWidgetConfigurationIntent,
    in context: Context
  ) async -> DailyContentEntry {
    DailyContentEntry(
      date: Date(),
      configuration: configuration,
      payload: loadPayload()
    )
  }

  func timeline(
    for configuration: DailyWidgetConfigurationIntent,
    in context: Context
  ) async -> Timeline<DailyContentEntry> {
    let now = Date()
    let entry = DailyContentEntry(
      date: now,
      configuration: configuration,
      payload: loadPayload()
    )
    let nextRefresh = nextMidnightRefreshDate(after: now)
    return Timeline(entries: [entry], policy: .after(nextRefresh))
  }

  private func nextMidnightRefreshDate(after date: Date) -> Date {
    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: date)
    let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? date
    return calendar.date(byAdding: .minute, value: 5, to: nextDay) ?? nextDay
  }

  private func loadPayload() -> DailyContentPayload? {
    guard
      let defaults = resolveSharedDefaults(),
      let raw = defaults.string(forKey: dailyContentPayloadKey),
      let data = raw.data(using: .utf8)
    else {
      return nil
    }
    guard let decoded = try? JSONDecoder().decode(DailyContentPayload.self, from: data) else {
      return nil
    }
    if let schema = decoded.schema, schema != 1 {
      return nil
    }
    return decoded
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

struct NurAiWidgetsEntryView: View {
  @Environment(\.widgetFamily) private var family
  var entry: DailyContentProvider.Entry

  var body: some View {
    if let payload = entry.payload {
      contentView(payload: payload)
        .containerBackground(for: .widget) {
          Color.clear
        }
        .widgetURL(URL(string: "nurai://home"))
    } else {
      loadingView
        .containerBackground(for: .widget) {
          Color.clear
        }
        .widgetURL(URL(string: "nurai://home"))
    }
  }

  private func contentView(payload: DailyContentPayload) -> some View {
    switch family {
    case .accessoryInline:
      Text(inlineText(payload: payload))
        .lineLimit(1)
    case .accessoryCircular:
      VStack(spacing: 2) {
        Text(shortTitle(payload: payload))
          .font(.system(size: 10, weight: .semibold))
        Text(shortBody(payload: payload))
          .font(.system(size: 10, weight: .regular))
          .lineLimit(1)
      }
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 3) {
        Text(shortTitle(payload: payload))
          .font(.system(size: 11, weight: .semibold))
          .lineLimit(1)
        Text(shortBody(payload: payload))
          .font(.system(size: 12, weight: .regular))
          .lineLimit(2)
      }
    default:
      VStack(alignment: .leading, spacing: 8) {
        Text(shortTitle(payload: payload))
          .font(.system(size: 12, weight: .semibold))
          .lineLimit(1)
        Text(shortBody(payload: payload))
          .font(.system(size: 14, weight: .regular))
          .lineLimit(4)
        if let reference = shortReference(payload: payload), !reference.isEmpty {
          Text(reference)
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
    }
  }

  private var loadingView: some View {
    Text(LocalizedStringResource("widget_loading"))
      .font(.system(size: 12, weight: .regular))
      .lineLimit(2)
  }

  private func shortTitle(payload: DailyContentPayload) -> String {
    switch entry.configuration.contentType {
    case .verse:
      return payload.verse?.title ?? String(localized: "content_type_verse")
    case .hadith:
      return payload.hadith?.title ?? String(localized: "content_type_hadith")
    case .asma:
      return String(localized: "content_type_asma")
    }
  }

  private func shortBody(payload: DailyContentPayload) -> String {
    switch entry.configuration.contentType {
    case .verse:
      return payload.verse?.text ?? String(localized: "widget_loading")
    case .hadith:
      return payload.hadith?.text ?? String(localized: "widget_loading")
    case .asma:
      if let name = payload.asma?.name, let meaning = payload.asma?.meaning {
        return "\(name) - \(meaning)"
      }
      return payload.asma?.name ?? String(localized: "widget_loading")
    }
  }

  private func shortReference(payload: DailyContentPayload) -> String? {
    switch entry.configuration.contentType {
    case .verse:
      return payload.verse?.ref
    case .hadith:
      return payload.hadith?.ref
    case .asma:
      return payload.asma?.meaning
    }
  }

  private func inlineText(payload: DailyContentPayload) -> String {
    switch entry.configuration.contentType {
    case .verse:
      return "\(shortTitle(payload: payload)): \(shortBody(payload: payload))"
    case .hadith:
      return "\(shortTitle(payload: payload)): \(shortBody(payload: payload))"
    case .asma:
      return shortBody(payload: payload)
    }
  }
}

struct NurAiWidgets: Widget {
  let kind: String = "NurAiWidgets"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: DailyWidgetConfigurationIntent.self,
      provider: DailyContentProvider()
    ) { entry in
      NurAiWidgetsEntryView(entry: entry)
    }
    .configurationDisplayName(LocalizedStringResource("widget_display_name"))
    .description(LocalizedStringResource("widget_description"))
    .supportedFamilies([
      .accessoryInline,
      .accessoryCircular,
      .accessoryRectangular,
      .systemSmall,
      .systemMedium,
    ])
  }
}
