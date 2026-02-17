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
  let payload: DailyContentPayload?
}

struct DailyContentProvider: TimelineProvider {
  func placeholder(in context: Context) -> DailyContentEntry {
    DailyContentEntry(
      date: Date(),
      payload: nil
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (DailyContentEntry) -> Void) {
    let entry: DailyContentEntry = DailyContentEntry(
      date: Date(),
      payload: loadPayload()
    )
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DailyContentEntry>) -> Void) {
    let now: Date = Date()
    let entry: DailyContentEntry = DailyContentEntry(
      date: now,
      payload: loadPayload()
    )
    let nextRefresh: Date = nextMidnightRefreshDate(after: now)
    let timeline: Timeline<DailyContentEntry> = Timeline(entries: [entry], policy: .after(nextRefresh))
    completion(timeline)
  }

  private func nextMidnightRefreshDate(after date: Date) -> Date {
    let calendar: Calendar = Calendar.current
    let startOfToday: Date = calendar.startOfDay(for: date)
    let nextDay: Date = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? date
    let refreshDate: Date = calendar.date(byAdding: .minute, value: 5, to: nextDay) ?? nextDay
    return refreshDate
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

struct NurAiWidgetsEntryView: View {
  private enum ContentType {
    case verse
    case hadith
    case asma
  }

  @Environment(\.widgetFamily) private var family: WidgetFamily
  let entry: DailyContentEntry

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

  @ViewBuilder
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
            .foregroundStyle(Color.secondary)
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

  private func selectedContentType(payload: DailyContentPayload) -> ContentType {
    if payload.verse != nil {
      return .verse
    }
    if payload.hadith != nil {
      return .hadith
    }
    return .asma
  }

  private func shortTitle(payload: DailyContentPayload) -> String {
    switch selectedContentType(payload: payload) {
    case .verse:
      return payload.verse?.title ?? String(localized: "content_type_verse")
    case .hadith:
      return payload.hadith?.title ?? String(localized: "content_type_hadith")
    case .asma:
      return String(localized: "content_type_asma")
    }
  }

  private func shortBody(payload: DailyContentPayload) -> String {
    switch selectedContentType(payload: payload) {
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
    switch selectedContentType(payload: payload) {
    case .verse:
      return payload.verse?.ref
    case .hadith:
      return payload.hadith?.ref
    case .asma:
      return payload.asma?.meaning
    }
  }

  private func inlineText(payload: DailyContentPayload) -> String {
    switch selectedContentType(payload: payload) {
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

  private var supportedWidgetFamilies: [WidgetFamily] {
    if #available(iOSApplicationExtension 16.0, *) {
      return [
        .accessoryInline,
        .accessoryCircular,
        .accessoryRectangular,
        .systemSmall,
        .systemMedium,
      ]
    }
    return [
      .systemSmall,
      .systemMedium,
    ]
  }

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: DailyContentProvider()) { entry in
      NurAiWidgetsEntryView(entry: entry)
    }
    .configurationDisplayName(LocalizedStringResource("widget_display_name"))
    .description(LocalizedStringResource("widget_description"))
    .supportedFamilies(supportedWidgetFamilies)
  }
}
